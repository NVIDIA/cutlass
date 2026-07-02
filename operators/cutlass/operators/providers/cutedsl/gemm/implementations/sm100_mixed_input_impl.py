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

"""Mixed-Input GEMM kernel implementation for NVIDIA Blackwell SM100 architecture.

This module implements a warp-specialized persistent GEMM kernel that supports
mixed-precision inputs where tensor A uses narrow precision (Int4/Int8/Uint8)
and tensor B uses wide precision (BFloat16/Float16).

Warp Specialization Architecture (12 warps, 384 threads per CTA):
- Warps 0-3 (Epilogue): Load accumulators from TMEM, convert, store to GMEM
- Warp 4 (MMA): Execute matrix multiply-accumulate operations
- Warp 5 (TMA Load A/B): Load A and B tensors from GMEM to SMEM via TMA
- Warp 6 (TMA Load Scale): Load scale tensor from GMEM to SMEM (convert-scale mode)
- Warp 7 (Idle): Reserved
- Warps 8-11 (Transform): Type conversion and optional scaling of A tensor

Transform Modes:
- Convert-Only: C = type_convert(A) @ B  (for Int8/Uint8)
- Convert-Scale: C = (type_convert(A) * scale) @ B  (for Int4)

Pipeline Architecture:
- a_load2trans_pipeline: TMA load A → Transform warps
- scale_load2trans_pipeline: TMA load scale → Transform warps (convert-scale mode)
- trans2mma_pipeline: Transform warps → MMA warp
- b_load2mma_pipeline: TMA load B → MMA warp
- acc_pipeline: MMA warp → Epilogue warps
"""

from dataclasses import dataclass
from math import ceil, log2

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
import cutlass.pipeline as pipeline
import cutlass.utils as utils
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.mixed_input_helpers as mixed_input_utils
from cutlass.cute.nvgpu import OperandMajorMode, cpasync, tcgen05
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
from cutlass.utils.mixed_input_helpers import TransformMode

from cutlass.operators.utils.common import round_up

# =============================================================================
# Capacity computation for mixed-input GEMM kernels
# =============================================================================

# Constants for capacity calculations
SM100_SMEM_ALIGN = 1024
_BYTES_PER_PIPELINE_STAGE = 16


@dataclass
class _TmemConfig:
    """TMEM allocation configuration."""

    num_tmem_acc_col_per_stage: int
    num_tmem_cols_a_per_stage: int
    accumulator_stage_count: int
    num_tmem_acc_cols: int


@dataclass
class _SmemConfig:
    """SMEM allocation configuration: per-stage byte counts, stage counts, and totals."""

    a_load_bytes_per_stage: int
    b_load_bytes_per_stage: int
    ab_load_bytes_per_stage: int
    a_transform_bytes_per_stage: int
    a_scale_bytes_per_stage: int
    scale_load2trans_stage_count: int
    c_bytes_per_stage: int
    initial_c_stage_count: int
    carveout_smem_bytes: int


@dataclass
class CapacityConfig:
    """Result of capacity computation for mixed-input GEMM kernels.

    This dataclass contains all computed stage counts and TMEM allocations
    for a given kernel configuration. It serves as the single source of truth
    for capacity-related computations, used by both early validation checks
    and compile-time kernel configuration.
    """

    # Stage counts
    load2transform_stage_count: int
    transform2mma_stage_count: int
    accumulator_stage_count: int
    scale_load2trans_stage_count: int
    c_stage_count: int

    # TMEM allocations
    num_tmem_acc_cols: int
    num_tmem_a_cols: int
    num_tmem_alloc_cols: int
    num_tmem_acc_col_per_stage: int
    num_tmem_cols_a_per_stage: int

    @property
    def is_valid(self) -> bool:
        """Check if the configuration has sufficient capacity."""
        return (
            self.load2transform_stage_count >= 2
            and self.transform2mma_stage_count >= 2
            and self.accumulator_stage_count >= 1
        )


def _compute_tmem_config(
    cta_tile_m: int,
    cta_tile_n: int,
    cta_tile_k: int,
    use_2cta: bool,
    mma_dtype_width: int,
    transform_a_source_is_tmem: bool,
    tmem_capacity: int,
) -> _TmemConfig:
    """Compute TMEM allocation configuration.

    Determines accumulator stage count and TMEM column allocations based on
    tile sizes and whether A uses TMEM.
    """
    from cutlass.utils.blackwell_helpers import compute_acc_tmem_cols_per_stage

    # Compute accumulator TMEM columns per stage
    num_tmem_acc_col_per_stage = compute_acc_tmem_cols_per_stage(
        cta_tile_m,
        cta_tile_n,
        use_2cta,
        mma_n=cta_tile_n,
        transform_a_source_is_tmem=transform_a_source_is_tmem,
    )

    # Dynamic accumulator stage count heuristic
    # When A uses TMEM, reduce accumulator stages to leave room for A
    if transform_a_source_is_tmem:
        if num_tmem_acc_col_per_stage < 128:
            accumulator_stage_count = 3
        elif num_tmem_acc_col_per_stage < 256:
            accumulator_stage_count = 2
        else:
            accumulator_stage_count = 1
    else:
        accumulator_stage_count = tmem_capacity // num_tmem_acc_col_per_stage

    num_elts_per_tmem_col = 32 // mma_dtype_width
    num_tmem_cols_a_per_stage = (
        round_up(cta_tile_k // num_elts_per_tmem_col, 4)
        if transform_a_source_is_tmem
        else 0
    )

    num_tmem_acc_cols = round_up(
        accumulator_stage_count * num_tmem_acc_col_per_stage, 4
    )

    return _TmemConfig(
        num_tmem_acc_col_per_stage=num_tmem_acc_col_per_stage,
        num_tmem_cols_a_per_stage=num_tmem_cols_a_per_stage,
        accumulator_stage_count=accumulator_stage_count,
        num_tmem_acc_cols=num_tmem_acc_cols,
    )


def _compute_smem_bytes_config(
    cta_tile_m: int,
    cta_tile_n: int,
    cta_tile_k: int,
    use_2cta: bool,
    a_dtype_width: int,
    b_dtype_width: int,
    mma_dtype_width: int,
    out_dtype_width: int,
    transform_a_source_is_tmem: bool,
    scale_mode_is_convert_only: bool,
    scale_granularity_m: int,
    scale_granularity_k: int,
    use_tma_store: bool,
    accumulator_stage_count: int,
    smem_align: int,
) -> _SmemConfig:
    """Compute SMEM bytes per stage for each buffer type.

    Calculates memory requirements for A/B loads, transform buffers,
    scale tensors, and epilogue buffers.
    """
    from cutlass.utils.blackwell_helpers import compute_epilogue_tile_size

    cta_divisor = 2 if use_2cta else 1

    # A load bytes per stage
    a_load_bytes_per_stage = round_up(
        cta_tile_m * cta_tile_k * a_dtype_width // 8, smem_align
    )

    # B load bytes per stage (N divided by cta_divisor for 2CTA sharing)
    b_n_for_smem = cta_tile_n // cta_divisor
    b_load_bytes_per_stage = round_up(
        b_n_for_smem * cta_tile_k * b_dtype_width // 8, smem_align
    )

    ab_load_bytes_per_stage = (
        a_load_bytes_per_stage + b_load_bytes_per_stage + 2 * _BYTES_PER_PIPELINE_STAGE
    )

    # Transformed A SMEM per stage (only when A source is SMEM)
    a_transform_bytes_per_stage = (
        round_up(cta_tile_m * cta_tile_k * mma_dtype_width // 8, smem_align)
        if not transform_a_source_is_tmem
        else 0
    ) + _BYTES_PER_PIPELINE_STAGE

    # Scale bytes (for scaled mode)
    if scale_mode_is_convert_only:
        scale_load2trans_stage_count = 0
        a_scale_bytes_per_stage = 0
    else:
        a_scale_k_mode = (
            max(cta_tile_k // scale_granularity_k, 1) if scale_granularity_k > 0 else 1
        )
        a_scale_m_mode = (
            max(cta_tile_m // scale_granularity_m, 1) if scale_granularity_m > 0 else 1
        )
        scale_load2trans_stage_count = 4
        a_scale_bytes_per_stage = round_up(
            a_scale_m_mode * a_scale_k_mode * mma_dtype_width // 8, smem_align
        )

    a_scale_bytes = (
        a_scale_bytes_per_stage + _BYTES_PER_PIPELINE_STAGE
    ) * scale_load2trans_stage_count

    # Epilogue bytes (c_bytes)
    c_stage_count = 2 if use_tma_store else 0
    epi_tile_m, epi_tile_n = compute_epilogue_tile_size(
        cta_tile_m, cta_tile_n, use_2cta, out_dtype_width
    )
    c_bytes_per_stage = round_up(
        epi_tile_m * epi_tile_n * out_dtype_width // 8, smem_align
    )
    c_bytes = c_bytes_per_stage * c_stage_count

    # Carveout SMEM bytes (reserved for accumulator pipeline, scale, epilogue)
    carveout_smem_bytes = (
        _BYTES_PER_PIPELINE_STAGE * accumulator_stage_count + a_scale_bytes + c_bytes
    )

    return _SmemConfig(
        a_load_bytes_per_stage=a_load_bytes_per_stage,
        b_load_bytes_per_stage=b_load_bytes_per_stage,
        ab_load_bytes_per_stage=ab_load_bytes_per_stage,
        a_transform_bytes_per_stage=a_transform_bytes_per_stage,
        a_scale_bytes_per_stage=a_scale_bytes_per_stage,
        scale_load2trans_stage_count=scale_load2trans_stage_count,
        c_bytes_per_stage=c_bytes_per_stage,
        initial_c_stage_count=c_stage_count,
        carveout_smem_bytes=carveout_smem_bytes,
    )


def _compute_stage_counts(
    tmem_config: _TmemConfig,
    smem_config: _SmemConfig,
    transform_a_source_is_tmem: bool,
    use_tma_store: bool,
    smem_capacity: int,
    tmem_capacity: int,
) -> tuple[int, int, int]:
    """Compute final stage counts based on TMEM and SMEM capacity limits.

    Returns (load2transform_stage_count, transform2mma_stage_count, c_stage_count).
    """
    # TMEM-limited stage count for transform2mma
    if transform_a_source_is_tmem and tmem_config.num_tmem_cols_a_per_stage > 0:
        transform2mma_stage_count_tmem = (
            tmem_capacity - tmem_config.num_tmem_acc_cols
        ) // tmem_config.num_tmem_cols_a_per_stage
    else:
        transform2mma_stage_count_tmem = float("inf")

    # SMEM-limited stage count for transform2mma
    transform2mma_stage_count_smem = (
        smem_capacity - smem_config.carveout_smem_bytes
    ) // (smem_config.ab_load_bytes_per_stage + smem_config.a_transform_bytes_per_stage)

    transform2mma_stage_count = int(
        min(transform2mma_stage_count_tmem, transform2mma_stage_count_smem)
    )

    # Load2transform stage count
    load2transform_stage_count = (
        smem_capacity
        - smem_config.carveout_smem_bytes
        - (transform2mma_stage_count * smem_config.a_transform_bytes_per_stage)
    ) // smem_config.ab_load_bytes_per_stage

    # Increase c_stage_count with leftover SMEM if using TMA store
    c_stage_count = smem_config.initial_c_stage_count
    if use_tma_store and smem_config.c_bytes_per_stage > 0:
        c_stage_count += (
            smem_capacity
            - load2transform_stage_count * smem_config.ab_load_bytes_per_stage
            - transform2mma_stage_count * smem_config.a_transform_bytes_per_stage
            - smem_config.carveout_smem_bytes
        ) // smem_config.c_bytes_per_stage

    return load2transform_stage_count, transform2mma_stage_count, c_stage_count


def compute_capacity_config(
    cta_tile_m: int,
    cta_tile_n: int,
    cta_tile_k: int,
    use_2cta: bool,
    a_dtype_width: int,
    b_dtype_width: int,
    mma_dtype_width: int,
    out_dtype_width: int,
    transform_a_source_is_tmem: bool,
    smem_align: int,
    scale_mode_is_convert_only: bool = True,
    scale_granularity_m: int = 0,
    scale_granularity_k: int = 0,
    use_tma_store: bool = True,
    smem_capacity: int | None = None,
    tmem_capacity: int | None = None,
) -> CapacityConfig:
    """Compute capacity configuration for mixed-input GEMM kernels.

    This function computes all stage counts, TMEM allocations, and SMEM requirements
    for a given kernel configuration. It is the single source of truth for capacity
    computations, used by both early validation and compile-time configuration.
    """
    from cutlass.cute.arch import get_max_tmem_alloc_cols
    from cutlass.utils import get_smem_capacity_in_bytes

    # Get hardware capacities
    if smem_capacity is None:
        smem_capacity = get_smem_capacity_in_bytes("sm_100")
    if tmem_capacity is None:
        tmem_capacity = get_max_tmem_alloc_cols("sm_100")

    # Step 1: Compute TMEM allocations
    tmem_config = _compute_tmem_config(
        cta_tile_m,
        cta_tile_n,
        cta_tile_k,
        use_2cta,
        mma_dtype_width,
        transform_a_source_is_tmem,
        tmem_capacity,
    )

    # Step 2: Compute SMEM bytes per stage
    smem_config = _compute_smem_bytes_config(
        cta_tile_m,
        cta_tile_n,
        cta_tile_k,
        use_2cta,
        a_dtype_width,
        b_dtype_width,
        mma_dtype_width,
        out_dtype_width,
        transform_a_source_is_tmem,
        scale_mode_is_convert_only,
        scale_granularity_m,
        scale_granularity_k,
        use_tma_store,
        tmem_config.accumulator_stage_count,
        smem_align,
    )

    # Step 3: Compute final stage counts
    (
        load2transform_stage_count,
        transform2mma_stage_count,
        c_stage_count,
    ) = _compute_stage_counts(
        tmem_config,
        smem_config,
        transform_a_source_is_tmem,
        use_tma_store,
        smem_capacity,
        tmem_capacity,
    )

    # Compute TMEM A columns from stage count
    num_tmem_a_cols = transform2mma_stage_count * tmem_config.num_tmem_cols_a_per_stage

    # Apply hardware allocation constraints: min 32 columns, power-of-2 total
    from cutlass.cute.arch import get_min_tmem_alloc_cols

    num_tmem_alloc_cols = max(
        get_min_tmem_alloc_cols("sm_100"),
        2 ** ceil(log2(tmem_config.num_tmem_acc_cols + num_tmem_a_cols))
        if (tmem_config.num_tmem_acc_cols + num_tmem_a_cols) > 0
        else 0,
    )

    return CapacityConfig(
        load2transform_stage_count=load2transform_stage_count,
        transform2mma_stage_count=transform2mma_stage_count,
        accumulator_stage_count=tmem_config.accumulator_stage_count,
        scale_load2trans_stage_count=smem_config.scale_load2trans_stage_count,
        c_stage_count=c_stage_count,
        num_tmem_acc_cols=tmem_config.num_tmem_acc_cols,
        num_tmem_a_cols=num_tmem_a_cols,
        num_tmem_alloc_cols=num_tmem_alloc_cols,
        num_tmem_acc_col_per_stage=tmem_config.num_tmem_acc_col_per_stage,
        num_tmem_cols_a_per_stage=tmem_config.num_tmem_cols_a_per_stage,
    )


class MixedInputGemmKernel:
    """Mixed-Input GEMM kernel implementation for NVIDIA Blackwell SM100 architecture.

    This kernel supports GEMM operations where input tensors A and B have different
    data types, with tensor A being transformed to the precision of tensor B before
    matrix multiplication.

    :param scale_granularity_m: Number of elements sharing the same scale factor along M
    :param scale_granularity_k: Number of elements sharing the same scale factor along K
    :param acc_dtype: Data type for accumulation during computation
    :param use_2cta_instrs: Whether to use CTA group 2 for advanced thread cooperation
    :param mma_tiler_mn: Shape of the MMA tile (M, N)
    :param cluster_shape_mn: Cluster dimensions (M, N) for parallel processing
    :param use_tma_store: Whether to use TMA for storing results
    :param shuffle_a: Whether to use shuffle intrinsic for int4-to-bf16 conversion
    """

    def __init__(
        self,
        scale_granularity_m: int,
        scale_granularity_k: int,
        acc_dtype: type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mnk: tuple[int, int, int],
        cluster_shape_mn: tuple[int, int],
        use_tma_store: bool,
        shuffle_a: bool,
    ):
        """Initializes the mixed-input GEMM kernel with specified configuration.
        """
        self.scale_granularity_m = scale_granularity_m
        self.scale_granularity_k = scale_granularity_k

        # Determine transform mode based on scale granularity
        if scale_granularity_m == 0 and scale_granularity_k == 0:
            self.scale_mode = TransformMode.ConvertOnly
        else:
            self.scale_mode = TransformMode.ConvertScale

        self.acc_dtype = acc_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.cluster_shape_mn = cluster_shape_mn
        self.mma_tiler = mma_tiler_mnk  # Full 3-tuple (M, N, K) from user
        self.use_tma_store = use_tma_store
        self.shuffle_a = shuffle_a
        self.arch = "sm_100"

        self.cta_group = (
            tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE
        )

        # Set specialized warp ids
        self.epilog_warp_id = (0, 1, 2, 3)
        self.mma_warp_id = 4
        self.tma_warp_id = 5
        self.scale_tma_warp_id = 6
        self.idle_warp_id = 7
        self.transform_warp_id = (8, 9, 10, 11)

        # Register budgets for different warp types
        self.num_regs_epilogue_warps = 192
        self.num_regs_mma_warp = 96
        self.num_regs_tma_warps = 96
        self.num_regs_transform_warps = 208
        self.num_regs_idle_warp = 24

        self.threads_per_cta = 32 * (
            max(
                (
                    self.mma_warp_id,
                    self.tma_warp_id,
                    self.scale_tma_warp_id,
                    *self.epilog_warp_id,
                    *self.transform_warp_id,
                )
            )
            + 1
        )

        # Set barrier ids for synchronization
        self.epilog_sync_barrier = pipeline.NamedBarrier(
            1, 32 * len(self.epilog_warp_id)
        )
        self.tmem_ptr_sync_barrier = pipeline.NamedBarrier(2, self.threads_per_cta)
        self.transform_sync_barrier = pipeline.NamedBarrier(
            3, 32 * len(self.transform_warp_id)
        )

        self.smem_buffer_align_bytes = SM100_SMEM_ALIGN
        self.smem_capacity = utils.get_smem_capacity_in_bytes(self.arch)

    def _setup_attributes(self):
        """Set up configurations that are dependent on GEMM inputs.

        This method configures various attributes based on the input tensor properties
        (data types, leading dimensions) and kernel settings:
        - Deduce where the transformed A tensor is stored (SMEM or TMEM)
        - Configuring tiled MMA
        - Computing MMA/cluster/tile shapes
        - Computing cluster layout
        - Computing multicast CTAs for A/B
        - Computing epilogue sub-tile
        - Setting up stage counts for pipelines
        - Computing memory layouts
        - Computing tensor memory allocation columns
        """
        # Deduce where the transformed A tensor is stored
        self.transform_a_source = mixed_input_utils.get_transform_a_source(
            self.a_major_mode
        )

        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.mma_dtype,
            self.mma_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
            self.transform_a_source,
        )

        # Use user-provided mma_tiler directly (K dimension is already set)
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )

        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1

        if cutlass.const_expr(self.use_tma_store):
            self.epi_tile = sm100_utils.compute_epilogue_tile_shape(
                self.cta_tile_shape_mnk,
                self.use_2cta_instrs,
                self.c_layout,
                self.c_dtype,
            )
        else:
            self.epi_tile = self.cta_tile_shape_mnk[:2]

        # Compute stages and TMEM columns
        (
            self.num_load2trans_stage,
            self.num_scale_load2trans_stage,
            self.num_trans2mma_stage,
            self.num_acc_stage,
            self.num_c_stage,
            self.num_acc_tmem_cols,
            self.num_a_tmem_cols,
            self.num_tmem_alloc_cols,
        ) = self._compute_stages_and_tmem_cols(
            tiled_mma,
            self.cta_tile_shape_mnk,
            self.a_dtype,
            self.b_dtype,
            self.c_dtype,
            self.transform_a_source,
            self.scale_granularity_m,
            self.scale_granularity_k,
            self.smem_buffer_align_bytes,
            self.use_tma_store,
            self.scale_mode,
        )

        # Get smem layout for C tensor when TMA store is enabled
        self.c_smem_layout_staged = (
            sm100_utils.make_smem_layout_epi(
                self.c_dtype,
                self.c_layout,
                self.epi_tile,
                self.num_c_stage,
            )
            if self.use_tma_store
            else None
        )

        # Get smem layout for A, transformed A, and B
        (
            self.smem_layout_a,
            self.smem_layout_a_transform,
            self.smem_layout_b,
        ) = mixed_input_utils.compute_smem_layout(
            tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.num_load2trans_stage,
            self.num_trans2mma_stage,
        )

        # Get smem layout for scale tensor
        self.smem_layout_scale_per_stage = None
        self.smem_layout_scale = None
        if self.scale_mode == TransformMode.ConvertScale:
            (
                self.scale_tile_shape,
                self.smem_layout_scale_per_stage,
                self.smem_layout_scale,
            ) = mixed_input_utils.get_smem_layout_scale(
                self.mma_tiler,
                self.use_2cta_instrs,
                self.scale_granularity_m,
                self.scale_granularity_k,
                self.scale_major_mode,
                self.a_scale_dtype,
                self.num_scale_load2trans_stage,
            )

    @staticmethod
    def _compute_stages_and_tmem_cols(
        tiled_mma,
        cta_tile_shape_mnk,
        a_dtype,
        b_dtype,
        c_dtype,
        transform_a_source,
        scale_granularity_m,
        scale_granularity_k,
        smem_align,
        use_tma_store,
        scale_mode,
    ):
        """Compute pipeline stages and TMEM column allocation configurations.

        This method uses the shared compute_capacity_config function to compute
        all stage counts and TMEM allocations, ensuring consistency with the
        early validation check in _check_capacity.
        """
        # Determine if A uses TMEM or SMEM
        transform_a_source_is_tmem = transform_a_source == tcgen05.OperandSource.TMEM

        # Use the shared capacity computation function
        config = compute_capacity_config(
            cta_tile_m=cta_tile_shape_mnk[0],
            cta_tile_n=cta_tile_shape_mnk[1],
            cta_tile_k=cta_tile_shape_mnk[2],
            use_2cta=(cute.size(tiled_mma.thr_id) == 2),
            a_dtype_width=a_dtype.width,
            b_dtype_width=b_dtype.width,
            mma_dtype_width=tiled_mma.op.a_dtype.width,
            out_dtype_width=c_dtype.width,
            transform_a_source_is_tmem=transform_a_source_is_tmem,
            scale_mode_is_convert_only=(scale_mode == TransformMode.ConvertOnly),
            scale_granularity_m=scale_granularity_m,
            scale_granularity_k=scale_granularity_k,
            use_tma_store=use_tma_store,
            smem_align=smem_align,
        )

        # Check capacity using the shared validation
        if not config.is_valid:
            raise ValueError("Not enough SMEM or TMEM capacity for selected tile size")

        return (
            config.load2transform_stage_count,
            config.scale_load2trans_stage_count,
            config.transform2mma_stage_count,
            config.accumulator_stage_count,
            config.c_stage_count,
            config.num_tmem_acc_cols,
            config.num_tmem_a_cols,
            config.num_tmem_alloc_cols,
        )

    def _validate_inputs(
        self,
        a: cute.Tensor,
        a_scale: cute.Tensor | None,
        b: cute.Tensor,
        c: cute.Tensor,
    ) -> None:
        """Validates input tensors and their properties."""
        # Validate scale tensor major mode for convert-scale mode
        if self.scale_mode == TransformMode.ConvertScale:
            if a_scale is None:
                raise ValueError("Scale tensor required for convert-scale mode")
            if (
                utils.LayoutEnum.from_tensor(a_scale).mma_major_mode()
                != OperandMajorMode.MN
            ):
                raise ValueError("scale_major_mode must be M-major")

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        a_scale: cute.Tensor | None,
        b: cute.Tensor,
        c: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
    ):
        """Executes the Mixed Input GEMM operation.

        This method sets up the kernel parameters, computes the grid size,
        defines the shared storage, and launches the kernel.
        """

        # Add batch dimension if tensor is 2D (up_to_rank=3)
        def add_batch_mode(tensor: cute.Tensor) -> cute.Tensor:
            return cute.make_tensor(
                tensor.iterator,
                cute.prepend(tensor.layout, cute.make_layout(1), up_to_rank=3),
            )

        a = add_batch_mode(a)
        b = add_batch_mode(b)
        c = add_batch_mode(c)

        # Permute tensor modes from PyTorch to CuTe convention
        # A: (L, M, K) -> (M, K, L)
        a = cute.make_tensor(a.iterator, cute.select(a.layout, [1, 2, 0]))
        # B: (L, K, N) -> (N, K, L)
        b = cute.make_tensor(b.iterator, cute.select(b.layout, [2, 1, 0]))
        # C: (L, M, N) -> (M, N, L)
        c = cute.make_tensor(c.iterator, cute.select(c.layout, [1, 2, 0]))

        # Handle scale tensor for ConvertScale mode
        # Use compile-time check since a_scale being None is determined at compile time
        if cutlass.const_expr(self.scale_mode is TransformMode.ConvertScale):
            # Scale: (L, M, K//scale_k) -> (M, K//scale_k, L)
            a_scale = add_batch_mode(a_scale)
            a_scale = cute.make_tensor(
                a_scale.iterator, cute.select(a_scale.layout, [1, 2, 0])
            )

        # Extract data types from tensors
        self.a_dtype: type[cutlass.Numeric] = a.element_type
        self.a_scale_dtype: type[cutlass.Numeric] = (
            a_scale.element_type
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        self.b_dtype: type[cutlass.Numeric] = b.element_type
        self.c_dtype: type[cutlass.Numeric] = c.element_type
        self.mma_dtype = self.b_dtype

        # Extract layout information
        self.a_major_mode = utils.LayoutEnum.from_tensor(a).mma_major_mode()
        self.scale_major_mode = (
            utils.LayoutEnum.from_tensor(a_scale).mma_major_mode()
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        self.b_major_mode = utils.LayoutEnum.from_tensor(b).mma_major_mode()
        self.c_layout = utils.LayoutEnum.from_tensor(c)

        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            self.gmem_layout_scale = mixed_input_utils.get_gmem_layout_scale(
                a.shape,
                self.scale_granularity_m,
                self.scale_granularity_k,
                self.scale_major_mode,
            )

        # Validate inputs
        self._validate_inputs(a, a_scale, b, c)

        # Setup attributes dependent on GEMM inputs
        self._setup_attributes()

        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.mma_dtype,
            self.mma_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
            self.transform_a_source,
        )

        # Set up TMA copy atoms
        a_op = mixed_input_utils.get_tma_atom_kind(
            self.is_a_mcast, self.use_2cta_instrs, False
        )
        b_op = mixed_input_utils.get_tma_atom_kind(
            self.is_b_mcast, self.use_2cta_instrs, True
        )
        a_scale_op = a_op

        # Create TMA atoms for A, B, and scale
        smem_layout_a_per_stage = cute.slice_(self.smem_layout_a, (None, None, None, 0))
        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            a_op,
            a,
            smem_layout_a_per_stage,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if a.element_type is cutlass.Float32 else None
            ),
        )

        tma_atom_scale, tma_tensor_scale = None, None
        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            smem_layout_for_tma_atom = cute.get(
                tiled_mma._thrfrg_A(self.smem_layout_scale_per_stage.outer), mode=[1]
            )
            smem_layout_for_tma_atom = cute.dice(
                smem_layout_for_tma_atom,
                (1, (1,) * cute.rank(self.smem_layout_scale_per_stage.outer)),
            )
            tma_atom_scale, tma_tensor_scale = cute.nvgpu.make_tiled_tma_atom_A(
                a_scale_op,
                cute.make_tensor(a_scale.iterator, self.gmem_layout_scale),
                smem_layout_for_tma_atom,
                (self.scale_tile_shape[0], 1, self.scale_tile_shape[1]),
                tiled_mma,
                self.cluster_layout_vmnk.shape,
                internal_type=(
                    cutlass.TFloat32
                    if a_scale.element_type is cutlass.Float32
                    else None
                ),
            )

        smem_layout_b_per_stage = cute.slice_(self.smem_layout_b, (None, None, None, 0))
        tma_atom_b, tma_tensor_b = cute.nvgpu.make_tiled_tma_atom_B(
            b_op,
            b,
            smem_layout_b_per_stage,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if b.element_type is cutlass.Float32 else None
            ),
        )

        # Calculate copy sizes for TMA
        a_copy_size = cute.size_in_bytes(self.a_dtype, smem_layout_a_per_stage)
        b_copy_size = cute.size_in_bytes(self.b_dtype, smem_layout_b_per_stage)
        a_scale_copy_size = (
            cute.size_in_bytes(self.a_scale_dtype, self.smem_layout_scale_per_stage)
            if self.scale_mode is TransformMode.ConvertScale
            else 0
        )

        self.num_tma_load_bytes_a = a_copy_size
        self.num_tma_load_bytes_b = b_copy_size * cute.size(tiled_mma.thr_id.shape)
        self.num_tma_load_bytes_scale = a_scale_copy_size

        # Compute grid size
        self.tile_sched_params, grid = self._compute_grid(
            c,
            self.cta_tile_shape_mnk,
            self.cluster_shape_mn,
            max_active_clusters,
        )

        # Setup TMA atom for C (if using TMA store)
        tma_atom_c = None
        tma_tensor_c = None
        if cutlass.const_expr(self.use_tma_store):
            epi_smem_layout = cute.slice_(self.c_smem_layout_staged, (None, None, 0))
            tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
                cpasync.CopyBulkTensorTileS2GOp(),
                c,
                epi_smem_layout,
                self.epi_tile,
            )

        # Define shared storage structure
        @cute.struct
        class SharedStorage:
            a_load2trans_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_load2trans_stage
            ]
            a_load2trans_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_load2trans_stage
            ]
            a_scale_load2trans_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_scale_load2trans_stage
            ]
            a_scale_load2trans_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_scale_load2trans_stage
            ]
            a_trans2mma_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_trans2mma_stage
            ]
            a_trans2mma_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_trans2mma_stage
            ]
            b_load2mma_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_load2trans_stage
            ]
            b_load2mma_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_load2trans_stage
            ]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            acc_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            tmem_dealloc_mbar: cutlass.Int64
            tmem_holding_buf: cutlass.Int32
            smem_C: cute.struct.Align[
                cute.struct.MemRange[
                    self.c_dtype,
                    cute.size(self.c_smem_layout_staged.outer)
                    if self.use_tma_store
                    else 0,
                ],
                self.smem_buffer_align_bytes,
            ]
            smem_A: cute.struct.Align[
                cute.struct.MemRange[self.a_dtype, cute.size(self.smem_layout_a.outer)],
                self.smem_buffer_align_bytes,
            ]
            smem_B: cute.struct.Align[
                cute.struct.MemRange[self.b_dtype, cute.size(self.smem_layout_b.outer)],
                self.smem_buffer_align_bytes,
            ]
            smem_A_transform: cute.struct.Align[
                cute.struct.MemRange[
                    self.mma_dtype,
                    cute.size(self.smem_layout_a_transform.outer)
                    if self.transform_a_source == tcgen05.OperandSource.SMEM
                    else 0,
                ],
                self.smem_buffer_align_bytes,
            ]
            smem_A_scale: cute.struct.Align[
                cute.struct.MemRange[
                    self.mma_dtype,
                    cute.size(self.smem_layout_scale.outer)
                    if self.scale_mode is TransformMode.ConvertScale
                    else 0,
                ],
                self.smem_buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        # Launch kernel
        self.kernel(
            tiled_mma,
            tma_atom_a,
            tma_tensor_a,
            tma_atom_scale,
            tma_tensor_scale,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_c,
            tma_tensor_c if self.use_tma_store else c,
            self.cluster_layout_vmnk,
            self.smem_layout_a,
            self.smem_layout_scale,
            self.smem_layout_a_transform,
            self.smem_layout_b,
            self.c_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            min_blocks_per_mp=1,
            stream=stream,
        )
        return

    @staticmethod
    def _compute_grid(
        c: cute.Tensor,
        cta_tile_shape_mnk: tuple[int, int, int],
        cluster_shape_mn: tuple[int, int],
        max_active_clusters: cutlass.Constexpr,
    ):
        """Use persistent tile scheduler to compute the grid size for the output tensor C."""
        c_shape = cute.slice_(cta_tile_shape_mnk, (None, None, 0))
        gc = cute.zipped_divide(c, tiler=c_shape)
        num_ctas_mnl = gc[(0, (None, None, None))].shape
        cluster_shape_mnl = (*cluster_shape_mn, 1)

        tile_sched_params = utils.PersistentTileSchedulerParams(
            num_ctas_mnl, cluster_shape_mnl
        )
        grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )

        return tile_sched_params, grid

    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_s: cute.CopyAtom | None,
        mS_mkl: cute.Tensor | None,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom | None,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout: cute.ComposedLayout,
        scale_smem_layout: cute.ComposedLayout,
        a_smem_layout_transform: cute.ComposedLayout,
        b_smem_layout: cute.ComposedLayout,
        c_smem_layout_staged: cute.ComposedLayout,
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
    ):
        """GPU device kernel performing the Persistent Mixed-Input GEMM computation.
        """
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())
        tidx, _, _ = cute.arch.thread_idx()
        bidx, bidy, bidz = cute.arch.block_idx()
        # Prefetch TMA descriptors
        if warp_idx == self.epilog_warp_id[0]:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
                cpasync.prefetch_descriptor(tma_atom_s)
            if cutlass.const_expr(self.use_tma_store):
                cpasync.prefetch_descriptor(tma_atom_c)

        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2
        bidx, bidy, bidz = cute.arch.block_idx()
        # Compute how many k_tiles share the same scale
        num_k_tiles_per_scale = self.scale_granularity_k // self.cta_tile_shape_mnk[2]

        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        tidx, _, _ = cute.arch.thread_idx()

        smem = utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # Initialize load2transform pipeline, which tracks the dependencies between TMA's loading
        # of A and B, and the transformation of A and MMA's consumption
        transform_thread_idx = (
            tidx - 32 * self.transform_warp_id[0]
            if tidx >= 32 * self.transform_warp_id[0]
            else tidx
        )
        a_load2trans_pipeline = pipeline.PipelineTmaAsync.create(
            barrier_storage=storage.a_load2trans_full_mbar_ptr.data_ptr(),
            num_stages=self.num_load2trans_stage,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                self.num_mcast_ctas_a * len(self.transform_warp_id),
            ),
            tx_count=self.num_tma_load_bytes_a,
            cta_layout_vmnk=cluster_layout_vmnk,
            tidx=transform_thread_idx,
            mcast_mode_mn=(1, 0),  # multicast for A will only happen on the M-mode
            defer_sync=True,
        )
        # Initialize scale_load2trans pipeline, which tracks the dependencies between TMA's loading
        # of scale, and the transformation of A
        scale_load2trans_pipeline = None
        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            num_producers_a_scale = self.num_mcast_ctas_a
            scale_load2trans_pipeline = pipeline.PipelineTmaAsync.create(
                barrier_storage=storage.a_scale_load2trans_full_mbar_ptr.data_ptr(),
                num_stages=self.num_scale_load2trans_stage,
                producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
                consumer_group=pipeline.CooperativeGroup(
                    pipeline.Agent.Thread,
                    num_producers_a_scale
                    * len(self.transform_warp_id)
                    * num_k_tiles_per_scale,
                ),
                tx_count=self.num_tma_load_bytes_scale,
                cta_layout_vmnk=cluster_layout_vmnk,
                tidx=transform_thread_idx,
                mcast_mode_mn=(
                    1,
                    0,
                ),  # multicast for scale_a will only happen on the M-mode
                defer_sync=True,
            )
        # Initialize transform2mma pipeline, which tracks the dependencies between the transformation
        # of A and MMA's consumption of transformed A
        cta_v_size = cute.size(cluster_layout_vmnk, mode=[0])
        trans2mma_pipeline = pipeline.PipelineAsyncUmma.create(
            barrier_storage=storage.a_trans2mma_full_mbar_ptr.data_ptr(),
            num_stages=self.num_trans2mma_stage,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                32 * len(self.transform_warp_id) * cta_v_size,
            ),
            consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )
        # Initialize pipeline for tensor B load to MMA
        # MMA warp informs TMA warp to proceed to load next tile of B tensor
        b_load2mma_pipeline = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.b_load2mma_full_mbar_ptr.data_ptr(),
            num_stages=self.num_load2trans_stage,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, self.num_mcast_ctas_b
            ),
            tx_count=self.num_tma_load_bytes_b,
            cta_layout_vmnk=cluster_layout_vmnk,
            mcast_mode_mn=(0, 1),  # multicast for B will only happen on the N-mode
            defer_sync=True,
        )
        # Initialize accumulator pipeline, which tracks the dependencies between
        # MMA's computation of accumulators and epilogue warps' consumption of accumulators
        acc_pipeline = pipeline.PipelineUmmaAsync.create(
            barrier_storage=storage.acc_full_mbar_ptr.data_ptr(),
            num_stages=self.num_acc_stage,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, cta_v_size * len(self.epilog_warp_id)
            ),
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )

        # Tensor memory dealloc barrier init
        tmem = utils.TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=self.tmem_ptr_sync_barrier,
            allocator_warp_id=self.epilog_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar.ptr,
        )

        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=self.cluster_shape_mn, is_relaxed=True)

        # Setup smem tensor A/scale/B/C
        sC = (
            storage.smem_C.get_tensor(
                c_smem_layout_staged.outer, swizzle=c_smem_layout_staged.inner
            )
            if self.use_tma_store
            else None
        )
        sA_input = storage.smem_A.get_tensor(
            a_smem_layout.outer, swizzle=a_smem_layout.inner
        )
        sS_input = (
            storage.smem_A_scale.get_tensor(
                scale_smem_layout.outer, swizzle=scale_smem_layout.inner
            )
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        sB_input = storage.smem_B.get_tensor(
            b_smem_layout.outer, swizzle=b_smem_layout.inner
        )
        sA_transform = None
        # Get smem tensor for transformed A when transform_a_source is SMEM
        if cutlass.const_expr(self.transform_a_source == tcgen05.OperandSource.SMEM):
            sA_transform = storage.smem_A_transform.get_tensor(
                a_smem_layout_transform.outer, swizzle=a_smem_layout_transform.inner
            )

        # Compute multicast mask for A/B buffer full
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        s_full_mcast_mask = None
        if cutlass.const_expr(self.is_a_mcast or self.is_b_mcast or use_2cta_instrs):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            # scale tensor share the same multicast mask with A tensor
            s_full_mcast_mask = a_full_mcast_mask
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )

        # local_tile partition global tensors
        # (bM, bK, loopM, loopK, loopL)
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
        )
        # (bM, bK, loopM, loopK, loopL)
        gS_mkl = (
            cute.local_tile(
                mS_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
            )
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        # (bN, bK, loopN, loopK, loopL)
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(self.mma_tiler, (0, None, None)), (None, None, None)
        )
        # (bM, bN, loopM, loopN, loopL)
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )
        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        # Partition global tensor for TiledMMA_A/B/C
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        # (MMA, MMA_M, MMA_K, loopM, loopK, loopL)
        tCgA = thr_mma.partition_A(gA_mkl)
        # (MMA, MMA_M, MMA_K, loopM, loopK, loopL)
        tCgS = (
            thr_mma.partition_A(gS_mkl)
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        # (MMA, MMA_N, MMA_K, loopN, loopK, loopL)
        tCgB = thr_mma.partition_B(gB_nkl)
        # (MMA, MMA_M, MMA_N, loopM, loopN, loopL)
        tCgC = thr_mma.partition_C(gC_mnl)

        # Setup copy atom to load A from shared memory for further transformation
        copy_atom_a_input = (
            cute.make_copy_atom(
                cute.nvgpu.CopyUniversalOp(), self.a_dtype, num_bits_per_copy=32
            )
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        a_smem_shape = tiled_mma.partition_shape_A(
            cute.dice(self.mma_tiler, (1, None, 1))
        )
        # Setup copy atom to store transformed A into tensor memory or shared memory
        copy_atom_a_transform = mixed_input_utils.get_copy_atom_a_transform(
            self.mma_dtype,
            self.use_2cta_instrs,
            self.transform_a_source,
            a_smem_shape,
            self.a_dtype,
        )

        # Partition global/shared tensor for TMA load A/B
        # TMA load A partition_S/D
        a_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), loopM, loopK, loopL)
        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sA_input, 0, 3),
            cute.group_modes(tCgA, 0, 3),
        )

        tCsS = None
        tSsS = None
        tSgS = None
        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            thr_mma_leader_cta = tiled_mma.get_slice(0)
            # (MMA, MMA_M, MMA_K, STAGE)
            tCsS = thr_mma_leader_cta.partition_A(sS_input)
            # ((atom_v, rest_v), STAGE)
            # ((atom_v, rest_v), loopM, loopK, loopL)
            tSsS, tSgS = mixed_input_utils.scale_tma_partition(
                tCsS,
                tCgS,
                tma_atom_s,
                block_in_cluster_coord_vmnk,
                a_cta_layout,
            )

        # TMA load B partition_S/D
        b_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), loopM, loopK, loopL)
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB_input, 0, 3),
            cute.group_modes(tCgB, 0, 3),
        )

        # (MMA, MMA_N, MMA_K, STAGE)
        tCrB = tiled_mma.make_fragment_B(sB_input)
        # (MMA, MMA_M, MMA_N)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )

        # Cluster wait before TMEM alloc and ensure pipelines are ready
        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        # TMEM allocation
        tmem.allocate(self.num_tmem_alloc_cols)
        tmem.wait_for_alloc()
        # Get the pointer to the TMEM buffer
        tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
        accumulators = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

        tCrA = None
        if cutlass.const_expr(self.transform_a_source == tcgen05.OperandSource.TMEM):
            # TMEM columns are 32-bit wide. For accumulators with element size < 32 bits
            # (e.g., Float16), we need to scale the column offset to element offset.
            # num_acc_tmem_cols is in column units, but pointer arithmetic uses element units.
            column_to_element_scale = 32 // self.acc_dtype.width
            tmem_ptr_transform = cute.recast_ptr(
                accumulators.iterator
                + self.num_acc_tmem_cols * column_to_element_scale,
                dtype=self.mma_dtype,
            )
            tCrA = cute.make_tensor(
                tmem_ptr_transform,
                tiled_mma.make_fragment_A(a_smem_layout_transform.outer).layout,
            )
        else:
            tCrA = tiled_mma.make_fragment_A(sA_transform)

        # Specialized TMA load warp for A/B tensor
        if warp_idx == self.tma_warp_id:
            cute.arch.setmaxregister_decrease(self.num_regs_tma_warps)
            # Persistent tile scheduling loop
            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, (bidx, bidy, bidz), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()
            a_load2trans_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_load2trans_stage
            )
            b_load2mma_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_load2trans_stage
            )
            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )
                tAgA_slice = tAgA[
                    (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                ]
                tBgB_slice = tBgB[
                    (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                ]

                a_load2trans_producer_state.reset_count()
                peek_load2trans_empty_status = cutlass.Boolean(1)
                if a_load2trans_producer_state.count < k_tile_cnt:
                    peek_load2trans_empty_status = (
                        a_load2trans_pipeline.producer_try_acquire(
                            a_load2trans_producer_state
                        )
                    )
                b_load2mma_producer_state.reset_count()
                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    a_load2trans_pipeline.producer_acquire(
                        a_load2trans_producer_state, peek_load2trans_empty_status
                    )
                    b_load2mma_pipeline.producer_acquire(b_load2mma_producer_state)
                    # TMA load A/B
                    cute.copy(
                        tma_atom_a,
                        tAgA_slice[(None, a_load2trans_producer_state.count)],
                        tAsA[(None, a_load2trans_producer_state.index)],
                        tma_bar_ptr=a_load2trans_pipeline.producer_get_barrier(
                            a_load2trans_producer_state
                        ),
                        mcast_mask=a_full_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_slice[(None, b_load2mma_producer_state.count)],
                        tBsB[(None, b_load2mma_producer_state.index)],
                        tma_bar_ptr=b_load2mma_pipeline.producer_get_barrier(
                            b_load2mma_producer_state
                        ),
                        mcast_mask=b_full_mcast_mask,
                    )
                    a_load2trans_pipeline.producer_commit(a_load2trans_producer_state)
                    b_load2mma_pipeline.producer_commit(b_load2mma_producer_state)
                    a_load2trans_producer_state.advance()
                    b_load2mma_producer_state.advance()
                    if a_load2trans_producer_state.count < k_tile_cnt:
                        peek_load2trans_empty_status = (
                            a_load2trans_pipeline.producer_try_acquire(
                                a_load2trans_producer_state
                            )
                        )
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # Wait A/B buffer empty
            a_load2trans_pipeline.producer_tail(a_load2trans_producer_state)
            b_load2mma_pipeline.producer_tail(b_load2mma_producer_state)

        # Specialized TMA load for scale tensor
        if warp_idx == self.scale_tma_warp_id:
            cute.arch.setmaxregister_decrease(self.num_regs_tma_warps)
            if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
                # Persistent tile scheduling loop
                tile_sched = utils.StaticPersistentTileScheduler.create(
                    tile_sched_params, (bidx, bidy, bidz), cute.arch.grid_dim()
                )
                work_tile = tile_sched.initial_work_tile_info()
                scale_load2trans_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.num_scale_load2trans_stage
                )
                scale_k_tile_cnt = cute.size(mS_mkl.layout.shape[1][1])

                while work_tile.is_valid_tile:
                    cur_tile_coord = work_tile.tile_idx
                    mma_tile_coord_mnl = (
                        cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                        cur_tile_coord[1],
                        cur_tile_coord[2],
                    )
                    # ((atom_v, rest_v), RestK)
                    tSgS_slice = tSgS[
                        (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                    ]
                    # Filter zeros in rest mode
                    rest_filtered = cute.filter_zeros(tSgS_slice[(0, None)].layout)
                    tSgS_slice_filtered = cute.make_tensor(
                        tSgS_slice.iterator,
                        cute.make_layout(
                            (tSgS_slice.layout[0].shape, rest_filtered.shape),
                            stride=(tSgS_slice.layout[0].stride, rest_filtered.stride),
                        ),
                    )

                    scale_load2trans_producer_state.reset_count()
                    peek_scale_load2trans_empty_status = cutlass.Boolean(1)
                    if scale_load2trans_producer_state.count < scale_k_tile_cnt:
                        peek_scale_load2trans_empty_status = (
                            scale_load2trans_pipeline.producer_try_acquire(
                                scale_load2trans_producer_state
                            )
                        )
                    for k_tile in cutlass.range(0, scale_k_tile_cnt, 1, unroll=1):
                        scale_load2trans_pipeline.producer_acquire(
                            scale_load2trans_producer_state,
                            peek_scale_load2trans_empty_status,
                        )
                        # TMA load scale
                        cute.copy(
                            tma_atom_s,
                            tSgS_slice_filtered[
                                (None, scale_load2trans_producer_state.count)
                            ],
                            tSsS[(None, scale_load2trans_producer_state.index)],
                            tma_bar_ptr=scale_load2trans_pipeline.producer_get_barrier(
                                scale_load2trans_producer_state
                            ),
                            mcast_mask=s_full_mcast_mask,
                        )

                        scale_load2trans_producer_state.advance()
                        peek_scale_load2trans_empty_status = cutlass.Boolean(1)
                        if scale_load2trans_producer_state.count < scale_k_tile_cnt:
                            peek_scale_load2trans_empty_status = (
                                scale_load2trans_pipeline.producer_try_acquire(
                                    scale_load2trans_producer_state
                                )
                            )
                    # Advance to next tile
                    tile_sched.advance_to_next_work()
                    work_tile = tile_sched.get_current_work()
                # Wait scale buffer empty
                scale_load2trans_pipeline.producer_tail(scale_load2trans_producer_state)

        # Specialized transform warps
        if warp_idx >= self.transform_warp_id[0]:
            cute.arch.setmaxregister_increase(self.num_regs_transform_warps)
            transform_local_tidx = tidx - 32 * self.transform_warp_id[0]
            # Partition tensors for transform input and output and set up the copy atom
            # used for loading and storing transformed A tensor
            (
                src_copy_a,
                dst_copy_a,
                tAsA_input,
                tAsA_transform,
            ) = mixed_input_utils.transform_partition(
                self.transform_a_source,
                self.scale_mode,
                copy_atom_a_input,
                copy_atom_a_transform,
                sA_input,
                (
                    tCrA
                    if self.transform_a_source == tcgen05.OperandSource.TMEM
                    else sA_transform
                ),
                transform_local_tidx,
            )
            # make rmem tensor for input A and transformed A
            tArA = cute.make_rmem_tensor(
                tAsA_input[(None, None, None, None, 0)].shape, tAsA_input.element_type
            )
            tArA_transform = cute.make_rmem_tensor(
                tAsA_input[(None, None, None, None, 0)].shape, self.mma_dtype
            )
            # Partition scale tensor
            smem_thr_copy_S = None
            tSsS_trans = None
            tSrS_copy = None
            tSrS = None
            if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
                smem_thr_copy_S, tSsS_trans, tSrS_copy, tSrS = (
                    mixed_input_utils.scale_partition(
                        src_copy_a, tCsS, transform_local_tidx, self.mma_dtype
                    )
                )
                assert cute.size(tSrS, mode=[0]) == cute.size(tArA, mode=[0]), (
                    "tSrS and tArA have different leading dimension"
                )
                assert cute.size(tSrS) == cute.size(tArA), (
                    "tSrS and tArA have different shape"
                )
            # Deduce a sub-tile size and tile tensors
            transform_tiler_size = min(
                cute.size(cute.coalesce(tAsA_input.layout), mode=[0]), 64
            )
            transform_tiler = cute.make_layout(transform_tiler_size)
            tArA_load = cute.flat_divide(tArA, transform_tiler)
            tArA_load = cute.group_modes(tArA_load, 1, cute.rank(tArA_load))
            tSrS_load = (
                cute.flat_divide(tSrS, transform_tiler)
                if self.scale_mode is TransformMode.ConvertScale
                else None
            )
            tSrS_load = (
                cute.group_modes(tSrS_load, 1, cute.rank(tSrS_load))
                if self.scale_mode is TransformMode.ConvertScale
                else None
            )
            tArA_transform_store = cute.flat_divide(tArA_transform, transform_tiler)
            tArA_transform_store = cute.group_modes(
                tArA_transform_store, 1, cute.rank(tArA_transform_store)
            )

            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, (bidx, bidy, bidz), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()
            a_load2trans_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer,
                self.num_load2trans_stage,
            )
            scale_load2trans_consumer_state = (
                pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer,
                    self.num_scale_load2trans_stage,
                )
                if self.scale_mode is TransformMode.ConvertScale
                else None
            )
            trans2mma_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer,
                self.num_trans2mma_stage,
            )
            while work_tile.is_valid_tile:
                a_load2trans_consumer_state.reset_count()
                peek_load2trans_full_status = cutlass.Boolean(1)
                if a_load2trans_consumer_state.count < k_tile_cnt:
                    peek_load2trans_full_status = (
                        a_load2trans_pipeline.consumer_try_wait(
                            a_load2trans_consumer_state
                        )
                    )
                peek_scale_load2trans_full_status = cutlass.Boolean(1)
                if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
                    scale_load2trans_consumer_state.reset_count()
                    peek_scale_load2trans_full_status = (
                        scale_load2trans_pipeline.consumer_try_wait(
                            scale_load2trans_consumer_state
                        )
                    )
                trans2mma_producer_state.reset_count()
                peek_trans2mma_empty_status = cutlass.Boolean(1)
                if trans2mma_producer_state.count < k_tile_cnt:
                    peek_trans2mma_empty_status = (
                        trans2mma_pipeline.producer_try_acquire(
                            trans2mma_producer_state
                        )
                    )

                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    a_load2trans_pipeline.consumer_wait(
                        a_load2trans_consumer_state, peek_load2trans_full_status
                    )
                    # Load A from shared memory
                    tAsA_input_slice = tAsA_input[
                        (None, None, None, None, a_load2trans_consumer_state.index)
                    ]
                    tAsA_input_slice = cute.flat_divide(
                        tAsA_input_slice, transform_tiler
                    )
                    tAsA_input_slice = cute.group_modes(
                        tAsA_input_slice, 1, cute.rank(tAsA_input_slice)
                    )
                    if cutlass.const_expr(
                        self.scale_mode == TransformMode.ConvertScale
                    ):
                        scale_load2trans_pipeline.consumer_wait(
                            scale_load2trans_consumer_state,
                            peek_scale_load2trans_full_status,
                        )
                    trans2mma_pipeline.producer_acquire(
                        trans2mma_producer_state, peek_trans2mma_empty_status
                    )
                    # load scale tensor when needed
                    if cutlass.const_expr(
                        self.scale_mode == TransformMode.ConvertScale
                    ):
                        if k_tile % num_k_tiles_per_scale == 0:
                            tSsS_slice = tSsS_trans[
                                (
                                    None,
                                    None,
                                    None,
                                    None,
                                    scale_load2trans_consumer_state.index,
                                )
                            ]
                            tSsS_slice_filtered = cute.make_tensor(
                                tSsS_slice.iterator,
                                cute.filter_zeros(tSsS_slice.layout),
                            )
                            cute.autovec_copy(tSsS_slice_filtered, tSrS_copy)
                        cur_scale_load2trans_consumer_state = (
                            scale_load2trans_consumer_state.clone()
                        )
                        if (k_tile + 1) % num_k_tiles_per_scale == 0:
                            scale_load2trans_consumer_state.advance()

                    cur_a_load2trans_consumer_state = (
                        a_load2trans_consumer_state.clone()
                    )
                    for idx in cutlass.range_constexpr(cute.size(tArA_load, mode=[1])):
                        # Load A from shared memory
                        cute.autovec_copy(
                            tAsA_input_slice[(None, idx)],
                            tArA_load[(None, idx)],
                        )
                        if cutlass.const_expr(
                            idx == cute.size(tArA_load, mode=[1]) - 1
                        ):
                            a_load2trans_consumer_state.advance()
                            if a_load2trans_consumer_state.count < k_tile_cnt:
                                peek_load2trans_full_status = (
                                    a_load2trans_pipeline.consumer_try_wait(
                                        a_load2trans_consumer_state
                                    )
                                )
                                if cutlass.const_expr(
                                    self.scale_mode == TransformMode.ConvertScale
                                ):
                                    peek_scale_load2trans_full_status = (
                                        scale_load2trans_pipeline.consumer_try_wait(
                                            scale_load2trans_consumer_state
                                        )
                                    )
                        # Convert it to mma dtype
                        tensor_transformed = mixed_input_utils.cvt_tensor_a(
                            tArA_load[(None, idx)], self.mma_dtype, self.shuffle_a
                        )
                        if cutlass.const_expr(
                            self.scale_mode == TransformMode.ConvertScale
                        ):
                            scale = cute.TensorSSA(
                                tSrS_load[(None, idx)].load(),
                                tensor_transformed.shape,
                                self.mma_dtype,
                            )
                            # Apply scale
                            tensor_transformed = tensor_transformed * scale
                        tArA_transform_store[(None, idx)].store(tensor_transformed)
                    # Store transformed A to tensor memory or shared memory
                    mixed_input_utils.store_transformed_a(
                        tArA_transform,
                        tAsA_transform[
                            (None, None, None, None, trans2mma_producer_state.index)
                        ],
                        dst_copy_a,
                    )
                    # Ensure all transform threads have finished the copy and reached the fence
                    self.transform_sync_barrier.arrive_and_wait()
                    if cutlass.const_expr(
                        self.transform_a_source == tcgen05.OperandSource.TMEM
                    ):
                        cute.arch.fence_view_async_tmem_store()
                    else:
                        cute.arch.fence_proxy(
                            "async.shared",
                            space="cta",
                        )
                    # Signal the completion of transformation
                    if cutlass.const_expr(
                        self.scale_mode == TransformMode.ConvertScale
                    ):
                        scale_load2trans_pipeline.consumer_release(
                            cur_scale_load2trans_consumer_state
                        )
                    a_load2trans_pipeline.consumer_release(
                        cur_a_load2trans_consumer_state
                    )
                    # Signal the completion of transformation
                    trans2mma_pipeline.producer_commit(trans2mma_producer_state)
                    trans2mma_producer_state.advance()
                    if trans2mma_producer_state.count < k_tile_cnt:
                        peek_trans2mma_empty_status = (
                            trans2mma_pipeline.producer_try_acquire(
                                trans2mma_producer_state
                            )
                        )
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # Wait a_transform buffer empty
            trans2mma_pipeline.producer_tail(trans2mma_producer_state)

        # Specialized MMA warp
        if warp_idx == self.mma_warp_id:
            cute.arch.setmaxregister_decrease(self.num_regs_mma_warp)
            tCtAcc_base = accumulators
            # Persistent tile scheduling loop
            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, (bidx, bidy, bidz), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()
            trans2mma_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_trans2mma_stage
            )
            b_load2mma_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_load2trans_stage
            )
            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )
            while work_tile.is_valid_tile:
                cur_tile_coord = work_tile.tile_idx
                # (MMA, MMA_M, MMA_N)
                tCtAcc = tCtAcc_base[(None, None, None, acc_producer_state.index)]
                b_load2mma_consumer_state.reset_count()
                trans2mma_consumer_state.reset_count()
                peek_trans2mma_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    if trans2mma_consumer_state.count < k_tile_cnt:
                        peek_trans2mma_full_status = (
                            trans2mma_pipeline.consumer_try_wait(
                                trans2mma_consumer_state
                            )
                        )
                    acc_pipeline.producer_acquire(acc_producer_state)

                    tiled_mma.set(tcgen05.Field.ACCUMULATE, False)
                    # Mma mainloop
                    for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                        trans2mma_pipeline.consumer_wait(
                            trans2mma_consumer_state, peek_trans2mma_full_status
                        )
                        b_load2mma_pipeline.consumer_wait(b_load2mma_consumer_state)
                        num_kblocks = cute.size(tCrA, mode=[2])
                        for kblock_idx in cutlass.range(num_kblocks, unroll_full=True):
                            kblock_coord_a = (
                                None,
                                None,
                                kblock_idx,
                                trans2mma_consumer_state.index,
                            )
                            kblock_coord_b = (
                                None,
                                None,
                                kblock_idx,
                                b_load2mma_consumer_state.index,
                            )

                            cute.gemm(
                                tiled_mma,
                                tCtAcc,
                                tCrA[kblock_coord_a],
                                tCrB[kblock_coord_b],
                                tCtAcc,
                            )
                            # Enable accumulate on tCtAcc after first kblock
                            tiled_mma.set(tcgen05.Field.ACCUMULATE, True)
                        trans2mma_pipeline.consumer_release(trans2mma_consumer_state)
                        b_load2mma_pipeline.consumer_release(b_load2mma_consumer_state)
                        trans2mma_consumer_state.advance()
                        b_load2mma_consumer_state.advance()
                        peek_trans2mma_full_status = cutlass.Boolean(1)
                        if trans2mma_consumer_state.count < k_tile_cnt:
                            peek_trans2mma_full_status = (
                                trans2mma_pipeline.consumer_try_wait(
                                    trans2mma_consumer_state
                                )
                            )
                    # Async arrive accumulator buffer full
                    acc_pipeline.producer_commit(acc_producer_state)
                acc_producer_state.advance()

                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # Wait for accumulator buffer empty
            acc_pipeline.producer_tail(acc_producer_state)

        # Specialized epilogue warps
        if warp_idx < self.mma_warp_id:
            cute.arch.setmaxregister_increase(self.num_regs_epilogue_warps)
            epi_tidx = tidx
            tCtAcc_base = accumulators
            # Partition for epilogue
            (
                tiled_copy_t2r,
                tTR_tAcc_base,
                tTR_rAcc,
            ) = mixed_input_utils.epilog_tmem_copy_and_partition(
                self.cta_tile_shape_mnk,
                self.c_layout,
                self.c_dtype,
                self.acc_dtype,
                epi_tidx,
                tCtAcc_base,
                tCgC,
                epi_tile,
                self.use_2cta_instrs,
            )

            tTR_rC = None
            tiled_copy_r2s = None
            simt_atom = None
            tRS_rC = None
            tRS_sC = None
            bSG_sC = None
            bSG_gC_partitioned = None
            tTR_gC_partitioned = None
            if cutlass.const_expr(self.use_tma_store):
                tTR_rC = cute.make_rmem_tensor(tTR_rAcc.shape, self.c_dtype)
                tiled_copy_r2s, tRS_rC, tRS_sC = (
                    mixed_input_utils.epilog_smem_copy_and_partition(
                        self.c_layout,
                        self.c_dtype,
                        self.acc_dtype,
                        tiled_copy_t2r,
                        tTR_rC,
                        epi_tidx,
                        sC,
                    )
                )
                (
                    tma_atom_c,
                    bSG_sC,
                    bSG_gC_partitioned,
                ) = self.epilog_gmem_copy_and_partition(
                    epi_tidx, tma_atom_c, tCgC, epi_tile, sC
                )
            else:
                (
                    simt_atom,
                    tTR_rC,
                    tTR_gC_partitioned,
                ) = self.epilog_gmem_copy_and_partition(
                    epi_tidx, tiled_copy_t2r, tCgC, epi_tile, sC
                )
            # Persistent tile scheduling loop
            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, (bidx, bidy, bidz), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()
            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )

            c_pipeline = None
            if cutlass.const_expr(self.use_tma_store):
                c_producer_group = pipeline.CooperativeGroup(
                    pipeline.Agent.Thread,
                    32 * len(self.epilog_warp_id),
                )
                c_pipeline = pipeline.PipelineTmaStore.create(
                    num_stages=self.num_c_stage,
                    producer_group=c_producer_group,
                )

            while work_tile.is_valid_tile:
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                bSG_gC = None
                tTR_gC = None
                if cutlass.const_expr(self.use_tma_store):
                    bSG_gC = bSG_gC_partitioned[(None, None, None, *mma_tile_coord_mnl)]
                else:
                    tTR_gC = tTR_gC_partitioned[
                        (None, None, None, None, None, *mma_tile_coord_mnl)
                    ]

                tTR_tAcc = tTR_tAcc_base[
                    (None, None, None, None, None, acc_consumer_state.index)
                ]
                # Wait for accumulator buffer full
                acc_pipeline.consumer_wait(acc_consumer_state)

                tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
                if cutlass.const_expr(self.use_tma_store):
                    bSG_gC = cute.group_modes(bSG_gC, 1, cute.rank(bSG_gC))
                else:
                    tTR_gC = cute.group_modes(tTR_gC, 3, cute.rank(tTR_gC))

                # Store accumulator to global memory in subtiles
                subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])
                num_prev_subtiles = tile_sched.num_tiles_executed * subtile_cnt
                for subtile_idx in cutlass.range(subtile_cnt):
                    # Load accumulator from tensor memory buffer to register
                    tTR_tAcc_mn = tTR_tAcc[(None, None, None, subtile_idx)]
                    cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)
                    if cutlass.const_expr(self.use_tma_store):
                        # Convert to C type
                        acc_vec = tiled_copy_r2s.retile(tTR_rAcc).load()
                        acc_vec = acc_vec.to(self.c_dtype)
                        tRS_rC.store(acc_vec)
                        c_buffer = (num_prev_subtiles + subtile_idx) % self.num_c_stage
                        # Store C to shared memory
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
                        # TMA store C to global memory
                        if warp_idx == self.epilog_warp_id[0]:
                            cute.copy(
                                tma_atom_c,
                                bSG_sC[(None, c_buffer)],
                                bSG_gC[(None, subtile_idx)],
                            )
                            c_pipeline.producer_commit()
                            c_pipeline.producer_acquire()
                        self.epilog_sync_barrier.arrive_and_wait()
                    else:
                        # Convert to C type
                        acc_vec = tTR_rAcc.load()
                        acc_vec = acc_vec.to(self.c_dtype)
                        tTR_rC.store(acc_vec)
                        # Store C to global memory
                        cute.autovec_copy(
                            tTR_rC, tTR_gC[(None, None, None, subtile_idx)]
                        )
                # Async arrive accumulator buffer empty
                with cute.arch.elect_one():
                    acc_pipeline.consumer_release(acc_consumer_state)
                acc_consumer_state.advance()
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            # Dealloc the tensor memory buffer
            tmem.relinquish_alloc_permit()
            self.epilog_sync_barrier.arrive_and_wait()
            tmem.free(tmem_ptr)
            if cutlass.const_expr(self.use_tma_store):
                c_pipeline.producer_tail()

        # Idle warp
        if warp_idx == self.idle_warp_id:
            cute.arch.setmaxregister_decrease(self.num_regs_idle_warp)

    def epilog_gmem_copy_and_partition(
        self,
        tidx: cutlass.Int32,
        atom: cute.CopyAtom | cute.TiledCopy,
        gC_mnl: cute.Tensor,
        epi_tile: cute.Tile,
        sC: cute.Tensor,
    ) -> tuple[cute.CopyAtom, cute.Tensor, cute.Tensor]:
        """Partitions source and destination tensors for a TMA store or SIMT store.
        """
        if self.use_tma_store:
            tma_atom_c, bSG_sC, bSG_gC, _, _ = (
                mixed_input_utils.epilog_gmem_copy_and_partition(
                    self.c_dtype, tidx, atom, None, gC_mnl, None, epi_tile, sC
                )
            )
            return tma_atom_c, bSG_sC, bSG_gC
        else:
            _, _, _, simt_atom, tTR_gC = (
                mixed_input_utils.epilog_gmem_copy_and_partition(
                    self.c_dtype, tidx, None, atom, None, gC_mnl, epi_tile, sC
                )
            )
            # (T2R, T2R_M, T2R_N)
            tTR_rC = cute.make_rmem_tensor(
                tTR_gC[(None, None, None, 0, 0, 0, 0, 0)].shape, self.c_dtype
            )
            simt_atom = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), self.c_dtype)
            return simt_atom, tTR_rC, tTR_gC
