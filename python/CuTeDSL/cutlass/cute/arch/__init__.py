# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from .elect import *
from .mbar import *
from .numeric_conversion import *
from .nvvm_wrappers import *
from .smem import *
from .tmem import *
from .numeric_conversion import *

# __all__ is required here for documentation generation
__all__ = [
    #
    # elect.py
    #
    "make_warp_uniform",
    "elect_one",
    #
    # mbar.py
    #
    "mbarrier_init",
    "mbarrier_init_fence",
    "mbarrier_arrive_and_expect_tx",
    "mbarrier_expect_tx",
    "mbarrier_wait",
    "mbarrier_try_wait",
    "mbarrier_conditional_try_wait",
    "mbarrier_arrive",
    #
    # nvvm_wrappers.py
    #
    "lane_idx",
    "warp_idx",
    "thread_idx",
    "block_dim",
    "block_idx",
    "grid_dim",
    "cluster_idx",
    "cluster_dim",
    "cluster_size",
    "block_in_cluster_idx",
    "block_in_cluster_dim",
    "block_idx_in_cluster",
    "shuffle_sync",
    "shuffle_sync_up",
    "shuffle_sync_down",
    "shuffle_sync_bfly",
    "barrier",
    "barrier_arrive",
    "sync_threads",
    "sync_warp",
    "fence_acq_rel_cta",
    "fence_acq_rel_cluster",
    "fence_acq_rel_gpu",
    "fence_acq_rel_sys",
    "cp_async_commit_group",
    "cp_async_wait_group",
    "cp_async_bulk_commit_group",
    "cp_async_bulk_wait_group",
    "cluster_wait",
    "cluster_arrive",
    "cluster_arrive_relaxed",
    "vote_ballot_sync",
    "vote_any_sync",
    "vote_all_sync",
    "vote_uni_sync",
    "popc",
    "fence_proxy",
    "fence_view_async_tmem_load",
    "fence_view_async_tmem_store",
    "warpgroup_reg_alloc",
    "warpgroup_reg_dealloc",
    "fma_packed_f32x2",
    "mul_packed_f32x2",
    "add_packed_f32x2",
    "fmax",
    "rcp_approx",
    "exp2",
    # Constants
    "WARP_SIZE",
    # Forward from auto-generated nvvm python
    "ProxyKind",
    "SharedSpace",
    "RoundingModeKind",
    #
    # smem.py
    #
    "alloc_smem",
    "get_dyn_smem",
    "get_dyn_smem_size",
    #
    # tmem.py
    #
    "retrieve_tmem_ptr",
    "alloc_tmem",
    "relinquish_tmem_alloc_permit",
    "dealloc_tmem",
    #
    # numeric_conversion.py
    #
    "prmt",
    "cvt_i8_bf16_intrinsic",
    "cvt_i4_bf16_intrinsic",
    "cvt_f4e2m1_f16_intrinsic",
    "cvt_i8x4_to_f32x4",
    "cvt_i8x2_to_f32x2",
    "cvt_i8_bf16",
    "cvt_f32x2_bf16x2",
]
