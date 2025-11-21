# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from .static_persistent_tile_scheduler import (
    WorkTileInfo,
    PersistentTileSchedulerParams,
    StaticPersistentTileScheduler,
    StaticPersistentRuntimeTileScheduler,
)

from .hardware_info import (
    HardwareInfo,
)

from .blackwell_helpers import (
    compute_epilogue_tile_shape,
    get_smem_store_op,
    get_tmem_load_op,
    get_num_tmem_alloc_cols,
    make_smem_layout_a,
    make_smem_layout_b,
    make_smem_layout_epi,
    make_trivial_tiled_mma,
    make_blockscaled_trivial_tiled_mma,
)

from .hopper_helpers import (
    sm90_get_smem_store_op,
    make_smem_layout_a as sm90_make_smem_layout_a,
    make_smem_layout_b as sm90_make_smem_layout_b,
    make_smem_layout_epi as sm90_make_smem_layout_epi,
    compute_tile_shape_or_override,
)

from .blockscaled_layout import (
    BlockScaledBasicChunk,
    tile_atom_to_shape_SF,
    make_smem_layout_sfa,
    make_smem_layout_sfb,
    make_tmem_layout_sfa,
    make_tmem_layout_sfb,
)

from .grouped_gemm_tile_scheduler_helper import (
    GroupSearchResult,
    GroupedGemmGroupSearchState,
    GroupedGemmTileSchedulerHelper,
    create_initial_search_state,
)

from .tensormap_manager import (
    TensorMapUpdateMode,
    TensorMapManager,
)

from .smem_allocator import SmemAllocator, get_smem_capacity_in_bytes
from .tmem_allocator import TmemAllocator

from .layout import LayoutEnum

from . import distributed

from .mixed_input_helpers import (
    TransformMode,
    scale_tma_partition,
    transform_partition,
    scale_partition,
    get_gmem_layout_scale,
    get_smem_layout_scale,
    compute_smem_layout,
    get_transform_a_source,
    get_tma_atom_kind,
    get_copy_atom_a_transform,
    is_valid_scale_granularity,
    get_divisibility,
)

from . import hopper_helpers as sm90
from . import blackwell_helpers as sm100

from .print_latex import print_latex, print_latex_tv

__all__ = [
    "get_smem_capacity_in_bytes",
    "SmemAllocator",
    "TmemAllocator",
    "LayoutEnum",
    "WorkTileInfo",
    "PersistentTileSchedulerParams",
    "StaticPersistentTileScheduler",
    "StaticPersistentRuntimeTileScheduler",
    "TensorMapUpdateMode",
    "TensorMapManager",
    "GroupSearchResult",
    "GroupedGemmGroupSearchState",
    "create_initial_search_state",
    "GroupedGemmTileSchedulerHelper",
    "HardwareInfo",
    "TransformMode",
    "scale_tma_partition",
    "transform_partition",
    "scale_partition",
    "get_gmem_layout_scale",
    "get_smem_layout_scale",
    "compute_smem_layout",
    "get_transform_a_source",
    "get_tma_atom_kind",
    "get_copy_atom_a_transform",
    "is_valid_scale_granularity",
    "get_divisibility",
    "compute_epilogue_tile_shape",
    "get_smem_store_op",
    "get_tmem_load_op",
    "get_num_tmem_alloc_cols",
    "make_smem_layout_a",
    "make_smem_layout_b",
    "make_smem_layout_epi",
    "make_trivial_tiled_mma",
    "make_blockscaled_trivial_tiled_mma",
    "sm90",
    "sm100",
    "print_latex",
    "print_latex_tv",
    "distributed",
]
