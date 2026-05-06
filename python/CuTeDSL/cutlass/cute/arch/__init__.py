# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from .elect import *
from .mbar import *
from .nvvm_wrappers import *
from .smem import *
from .tmem import *
from .numeric_conversion import *
from .clc import *

import cutlass.cutlass_dsl as cutlass_dsl

# Forward from auto-generated nvvm python: only export on 12.9 wheel
_nvvm_forward_exports_12_9 = (
    ["ProxyKind", "SharedSpace", "RoundingModeKind", "ReduxKind", "AtomicOpKind"]
    if cutlass_dsl.target_version(exact_version="12.9")
    else []
)

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
    "physical_warp_id",
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
    "dynamic_smem_size",
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
    "warp_redux_sync",
    "atomic_max_float32",  # Deprecated: use atomic_fmax
    "atomic_add",
    "atomic_and",
    "atomic_or",
    "atomic_xor",
    "atomic_max",
    "atomic_min",
    "atomic_exch",
    "atomic_cas",
    "store",
    "load",
    "red",
    "popc",
    "fence_proxy",
    "fence_view_async_tmem_load",
    "fence_view_async_tmem_store",
    "warpgroup_reg_alloc",
    "warpgroup_reg_dealloc",
    "setmaxregister_increase",
    "setmaxregister_decrease",
    "fma_packed_f32x2",
    "mul_packed_f32x2",
    "add_packed_f32x2",
    "sub_packed_f32x2",
    "fmax",
    "fmin",
    "rcp_approx",
    "exp2",
    "cvt_i8x4_to_f32x4",
    "cvt_i8x2_to_f32x2",
    "cvt_i8_bf16",
    "cvt_i8x2_to_bf16x2",
    "cvt_i8x4_to_bf16x4",
    "cvt_f32x2_bf16x2",
    "smid",
    "nsmid",
    "clock",
    "clock64",
    "match_sync",
    "clz",
    "bfind",
    "brev",
    "bfe",
    "bfi",
    "mul_hi",
    "mul_wide",
    "mul24",
    "mad24",
    "add_cc",
    "addc",
    "sub_cc",
    "subc",
    "mad_cc",
    "madc",
    "activemask",
    "lanemask_lt",
    "lanemask_le",
    "lanemask_eq",
    "lanemask_ge",
    "lanemask_gt",
    "add_sat_int",
    "sub_sat_int",
    "lop3",
    "shf",
    # Constants
    "WARP_SIZE",
    *_nvvm_forward_exports_12_9,
    #
    # smem.py
    #
    "alloc_smem",
    "get_dyn_smem",
    "get_dyn_smem_size",
    #
    # tmem.py
    #
    "get_max_tmem_alloc_cols",
    "get_min_tmem_alloc_cols",
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
    #
    # clc.py
    #
    "issue_clc_query",
    "clc_response",
]
