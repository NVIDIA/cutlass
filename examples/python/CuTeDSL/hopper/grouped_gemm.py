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
import functools
import os
from typing import List, Optional, Tuple, Type
from inspect import isclass
import math
import cuda.bindings.driver as cuda

import torch
import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
import cutlass.utils as utils
import cutlass.utils.hopper_helpers as sm90_utils
import cutlass.torch as cutlass_torch
from cutlass.cutlass_dsl import extract_mlir_values, new_from_mlir_values
from cutlass.cute.core import (
    AddressSpace as _CuteAddressSpace,
    make_ptr as _cute_make_ptr,
)
from cutlass._mlir.dialects import nvvm as _nvvm_d
from cutlass._mlir.dialects._nvvm_enum_gen import (
    CpAsyncBulkTensorLoadMode as _CpAsyncBulkTensorLoadMode,
)
from cutlass.cutlass_dsl import dsl_user_op as _dsl_user_op, T as _T
from cutlass.cute.typing import Int32 as _Int32, Pointer as _Pointer


def _env_flag(name: str, default: bool) -> bool:
    val = os.getenv(name)
    if val is None:
        return default
    return val.strip().lower() in {"1", "true", "yes", "on"}


# Debug switch: force `cute.copy` path for non-mcast loads.
_ENABLE_NVVM_NON_MCAST_LOAD = not _env_flag("GROUPED_GEMM_FORCE_CUTE_COPY", False)
# Experimental switch: enable true SMEM tensor map update/publish path in
# _FixedTensorMapManager for investigation.
_ENABLE_TRUE_SMEM_TMAP = _env_flag("GROUPED_GEMM_ENABLE_TRUE_SMEM_TMAP", False)
_ENABLE_TRUE_SMEM_TMAP_PREUPDATE = _env_flag(
    "GROUPED_GEMM_ENABLE_TRUE_SMEM_TMAP_PREUPDATE", True
)
_ENABLE_TRUE_SMEM_TMAP_PUBLISH = _env_flag(
    "GROUPED_GEMM_ENABLE_TRUE_SMEM_TMAP_PUBLISH", True
)

"""
Grouped GEMM (C_g = A_g * B_g for each group g) for the NVIDIA Hopper architecture
using CuTe DSL.

This kernel extends hopper/dense_gemm_persistent.py with per-group TMA tensor map updates
and a group-aware persistent tile scheduler (StaticPersistentGroupTileScheduler).

Key features:
    - WGMMA + TMA + persistent warp-specialized kernel (inherited from dense_gemm_persistent)
    - Per-group A/B/C TMA descriptor updates (tensor map) via GMEM or SMEM mode
    - DMA warp group: loads A/B tiles, updates tensor maps A/B on group boundary
    - MMA warp group: performs WGMMA, updates tensor map C on group boundary, stores C

To run:

.. code-block:: bash

    python hopper/grouped_gemm.py                                             \\
      --num_groups 4                                                           \\
      --problem_sizes_mnkl "(8192,1280,32,1),(16,384,1536,1),(640,1280,16,1),(640,160,16,1)" \\
      --tile_shape_mn 128,256 --cluster_shape_mn 1,1                          \\
      --a_dtype Float16 --b_dtype Float16 --c_dtype Float16 --acc_dtype Float32 \\
      --a_major k --b_major k --c_major n                                      \\
      --tensormap_update_mode SMEM

Constraints (same as dense_gemm_persistent.py plus):
* Only fp16/bf16 inputs are supported for grouped mode
* l (batch) must be 1 for each group
* CTA tile M: 64/128, N: 64/128/256
* Cluster shape M/N: power of 2, total <= 4
* Contiguous dim must be 16-byte aligned

Debug environment knobs:
* `GROUPED_GEMM_FORCE_CUTE_COPY=1`
    Disable the non-mcast NVVM TMA load path and always use `cute.copy`.
"""


@_dsl_user_op
def _tma_load_ab_nvvm_no_mcast(
    k_coord: _Int32,
    m_coord: _Int32,
    n_coord: _Int32,
    desc_a: _Pointer,
    desc_b: _Pointer,
    smem_a: _Pointer,
    smem_b: _Pointer,
    mbar: _Pointer,
    *,
    loc=None,
    ip=None,
) -> None:
    """Issue TMA A + TMA B loads via NVVM dialect ops for the non-mcast case.

    By passing the elect_sync predicate directly to the NVVM TMA op (instead of
    using scf.IfOp), all operands (k_coord, m_coord, desc_a, smem_a, mbar) are
    computed unconditionally at the MLIR/LLVM level.  PTXAS therefore emits any
    required R2UR conversions outside the predicated ELECT block, which is legal
    on sm_90a.  The scf.IfOp path, by contrast, causes PTXAS to sink the R2UR
    into the @P0-predicated elected-thread block, producing the illegal
    "@P0 R2UR" instruction (CUDA_ERROR_ILLEGAL_INSTRUCTION / error 715).
    """
    l_coord = _Int32(0).ir_value(loc=loc, ip=ip)
    # llvm_ptr is a @property on _Pointer — access without call syntax.
    smem_a_llvm = smem_a.llvm_ptr
    smem_b_llvm = smem_b.llvm_ptr
    mbar_llvm = mbar.llvm_ptr
    desc_a_llvm = desc_a.llvm_ptr
    desc_b_llvm = desc_b.llvm_ptr
    # TMA A: elect one thread and issue the load with predicate.
    is_elected_a = _nvvm_d.elect_sync(_T.bool(), loc=loc, ip=ip)
    _nvvm_d.CpAsyncBulkTensorGlobalToSharedClusterOp(
        dstMem=smem_a_llvm,
        tmaDescriptor=desc_a_llvm,
        coordinates=[
            k_coord.ir_value(loc=loc, ip=ip),
            m_coord.ir_value(loc=loc, ip=ip),
            l_coord,
        ],
        mbar=mbar_llvm,
        im2colOffsets=[],
        predicate=is_elected_a,
        loadMode=_CpAsyncBulkTensorLoadMode.TILE,
        loc=loc,
        ip=ip,
    )
    # TMA B: elect one thread and issue the load with predicate.
    is_elected_b = _nvvm_d.elect_sync(_T.bool(), loc=loc, ip=ip)
    _nvvm_d.CpAsyncBulkTensorGlobalToSharedClusterOp(
        dstMem=smem_b_llvm,
        tmaDescriptor=desc_b_llvm,
        coordinates=[
            k_coord.ir_value(loc=loc, ip=ip),
            n_coord.ir_value(loc=loc, ip=ip),
            l_coord,
        ],
        mbar=mbar_llvm,
        im2colOffsets=[],
        predicate=is_elected_b,
        loadMode=_CpAsyncBulkTensorLoadMode.TILE,
        loc=loc,
        ip=ip,
    )


class _GroupedWorkTileInfo:
    """Work tile info for grouped GEMM: carries is_valid_tile + group_search_result."""

    def __init__(self, is_valid_tile, group_search_result):
        self._is_valid_tile = is_valid_tile
        self.group_search_result = group_search_result

    @property
    def is_valid_tile(self):
        return self._is_valid_tile

    def __extract_mlir_values__(self):
        values = extract_mlir_values(self._is_valid_tile)
        values.extend(extract_mlir_values(self.group_search_result))
        return values

    def __new_from_mlir_values__(self, values):
        n_valid = len(extract_mlir_values(self._is_valid_tile))
        is_valid = new_from_mlir_values(self._is_valid_tile, values[:n_valid])
        gsr = new_from_mlir_values(self.group_search_result, values[n_valid:])
        return _GroupedWorkTileInfo(is_valid, gsr)


class StaticPersistentGroupTileScheduler:
    """Grouped-GEMM-aware persistent tile scheduler.

    Wraps StaticPersistentTileScheduler + GroupedGemmTileSchedulerHelper.
    This class is not yet in cutlass.utils 4.3.5, so it is defined locally.
    """

    def __init__(self, tile_sched, group_helper, problem_sizes_mnkl):
        self._tile_sched = tile_sched
        self._group_helper = group_helper
        self._problem_sizes_mnkl = problem_sizes_mnkl

    def __extract_mlir_values__(self):
        values = extract_mlir_values(self._tile_sched)
        values.extend(extract_mlir_values(self._group_helper))
        return values

    def __new_from_mlir_values__(self, values):
        n_tile = len(extract_mlir_values(self._tile_sched))
        tile_sched = new_from_mlir_values(self._tile_sched, values[:n_tile])
        group_helper = new_from_mlir_values(self._group_helper, values[n_tile:])
        return StaticPersistentGroupTileScheduler(
            tile_sched, group_helper, self._problem_sizes_mnkl
        )

    @staticmethod
    def create(
        tile_sched_params,
        bid,
        grid_dim,
        cluster_tile_shape_mnk,
        search_state,
        group_count,
        problem_sizes_mnkl,
    ):
        tile_sched = utils.StaticPersistentTileScheduler.create(
            tile_sched_params, bid, grid_dim
        )
        group_helper = utils.GroupedGemmTileSchedulerHelper(
            group_count, tile_sched_params, cluster_tile_shape_mnk, search_state
        )
        return StaticPersistentGroupTileScheduler(
            tile_sched, group_helper, problem_sizes_mnkl
        )

    @staticmethod
    def get_grid_shape(tile_sched_params, max_active_clusters):
        return utils.StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )

    def initial_work_tile_info(self):
        return self.get_current_work()

    def get_current_work(self):
        base = self._tile_sched.get_current_work()
        # For invalid tiles (linear_idx >= total_tiles), delinearize_z's inner
        # while-loop would infinite-loop.  Clamp the z coordinate to 0 by
        # multiplying with is_valid_tile (i1 zero-extended to i32).  z=0 is
        # always a valid tile index, so the group search terminates cleanly;
        # the resulting GroupSearchResult is discarded because the caller only
        # accesses it inside "while work_tile.is_valid_tile:".
        valid_int = base.is_valid_tile.to(cutlass.Int32)
        safe_tile_idx = (
            base.tile_idx[0],
            base.tile_idx[1],
            base.tile_idx[2] * valid_int,
        )
        gsr = self._group_helper.delinearize_z(safe_tile_idx, self._problem_sizes_mnkl)
        return _GroupedWorkTileInfo(base.is_valid_tile, gsr)

    def advance_to_next_work(self, *, advance_count=1):
        self._tile_sched.advance_to_next_work(advance_count=advance_count)

    @property
    def num_tiles_executed(self):
        return self._tile_sched.num_tiles_executed


class _FixedTensorMapManager(utils.TensorMapManager):
    """Local stability manager for environments using older cutlass.utils.

    By default, SMEM update/publish is routed through the GMEM branch for
    stability. Set GROUPED_GEMM_ENABLE_TRUE_SMEM_TMAP=1 to test the true SMEM
    path during investigation.
    """

    @_dsl_user_op
    @cute.jit
    def update_tensormap(
        self,
        tensor_gmem,
        tma_copy_atom,
        tensormap_gmem_ptr,
        warp_id: int,
        tensormap_smem_ptr,
        *,
        loc=None,
        ip=None,
    ) -> None:
        warp_idx = cute.arch.make_warp_uniform(
            cute.arch.warp_idx(loc=loc, ip=ip), loc=loc, ip=ip
        )
        if cutlass.const_expr(
            self.tensormap_update_mode == utils.TensorMapUpdateMode.SMEM
        ):
            # Hoist SMEM pointer uniformization outside predicated blocks to avoid
            # predicated R2UR generation on sm_90a.
            uniform_smem_ptrs = tuple(
                _cute_make_ptr(
                    p.dtype,
                    cute.arch.make_warp_uniform(p.toint(), loc=loc, ip=ip),
                    mem_space=_CuteAddressSpace.smem,
                    assumed_align=p.alignment,
                )
                for p in tensormap_smem_ptr
            )
        else:
            uniform_smem_ptrs = tensormap_smem_ptr
        if warp_idx == warp_id:
            if cutlass.const_expr(
                self.tensormap_update_mode == utils.TensorMapUpdateMode.SMEM
                and _ENABLE_TRUE_SMEM_TMAP
                and _ENABLE_TRUE_SMEM_TMAP_PREUPDATE
            ):
                for atom, tensor, sptr in zip(
                    tma_copy_atom, tensor_gmem, uniform_smem_ptrs
                ):
                    cute.nvgpu.cpasync.update_tma_descriptor(
                        atom, tensor, sptr, loc=loc, ip=ip
                    )
            with cute.arch.elect_one(loc=loc, ip=ip):
                cute.arch.cp_async_bulk_commit_group(loc=loc, ip=ip)
                cute.arch.cp_async_bulk_wait_group(0, read=True, loc=loc, ip=ip)
            cute.arch.sync_warp(loc=loc, ip=ip)
            if cutlass.const_expr(
                self.tensormap_update_mode == utils.TensorMapUpdateMode.SMEM
                and _ENABLE_TRUE_SMEM_TMAP
                and _ENABLE_TRUE_SMEM_TMAP_PUBLISH
            ):
                for gptr, sptr in zip(tensormap_gmem_ptr, uniform_smem_ptrs):
                    cute.nvgpu.cpasync.cp_fence_tma_desc_release(
                        gptr, sptr, loc=loc, ip=ip
                    )
            else:
                for atom, tensor, gptr in zip(
                    tma_copy_atom, tensor_gmem, tensormap_gmem_ptr
                ):
                    cute.nvgpu.cpasync.update_tma_descriptor(
                        atom, tensor, gptr, loc=loc, ip=ip
                    )
                cute.arch.sync_warp(loc=loc, ip=ip)
                cute.nvgpu.cpasync.fence_tma_desc_release(loc=loc, ip=ip)


class HopperGroupedGemmPersistentKernel:
    """
    This class implements batched matrix multiplication (C = A x B) with support for various data types
    and architectural features specific to Hopper GPUs.

    :param acc_dtype: Data type for accumulation during computation
    :type acc_dtype: type[cutlass.Numeric]
    :param tile_shape_mn: Shape of the CTA tile (M,N)
    :type tile_shape_mn: Tuple[int, int]
    :param cluster_shape_mn: Cluster dimensions (M,N) for parallel processing
    :type cluster_shape_mn: Tuple[int, int]

    :note: Supported A/B data types:
        - Float16
          A and B must have the same data type
        - Float8E4M3FN/Float8E5M2
          A and B can have different types (Float8E4M3FN/Float8E5M2)
          only support k-major layout
        - Int8/Uint8
          A and B can have different types (Int8/Uint8)
          only support k-major layout

    :note: Supported accumulation types:
        - Float32/Float16 (for all floating point inputs)
        - Int32 (for Int8/Uint8 inputs)

    :note: Constraints:
        - CTA tile M must be 64/128
        - CTA tile N must be 64/128/256
        - CTA tile K must be 64
        - Cluster shape M/N must be positive and power of 2, total cluster size <= 4

    Example:
        >>> gemm = HopperGroupedGemmPersistentKernel(
        ...     acc_dtype=cutlass.Float32,
        ...     tile_shape_mn=(128, 256),
        ...     cluster_shape_mn=(1, 1)
        ... )
        >>> gemm(a_tensor, b_tensor, c_tensor, stream)
    """

    bytes_per_tensormap = 128
    num_tensormaps = 3  # A, B, C

    def __init__(
        self,
        acc_dtype: type[cutlass.Numeric],
        tile_shape_mn: tuple[int, int],
        cluster_shape_mn: tuple[int, int],
        swizzle_size: int,
        raster_along_m: bool,
        tensormap_update_mode: utils.TensorMapUpdateMode = utils.TensorMapUpdateMode.SMEM,
    ):
        """
        Initializes the configuration for a Hopper dense GEMM kernel.

        This configuration includes data types for operands, tile shape, cluster configuration,
        and thread layout.

        :param acc_dtype: Data type for accumulation during computation
        :type acc_dtype: type[cutlass.Numeric]
        :param tile_shape_mn: Shape of the CTA tile (M,N)
        :type tile_shape_mn: Tuple[int, int]
        :param cluster_shape_mn: Cluster dimensions (M,N) for parallel processing
        :type cluster_shape_mn: Tuple[int, int]
        """

        self.acc_dtype = acc_dtype

        self.cluster_shape_mn = cluster_shape_mn
        self.swizzle_size = swizzle_size
        self.raster_along_m = raster_along_m
        self.mma_inst_shape_mn = None
        # K dimension is deferred in _setup_attributes
        self.tile_shape_mnk = (*tile_shape_mn, 1)
        # For large tile size, using two warp groups is preferred because using only one warp
        # group may result in register spill
        self.atom_layout_mnk = (
            (2, 1, 1)
            if self.tile_shape_mnk[0] > 64 and self.tile_shape_mnk[1] > 128
            else (1, 1, 1)
        )
        self.num_mcast_ctas_a = None
        self.num_mcast_ctas_b = None
        self.is_a_mcast = False
        self.is_b_mcast = False
        self.tiled_mma = None

        self.occupancy = 1
        self.num_dma_warp_groups = 1
        self.num_mma_warp_groups = math.prod(self.atom_layout_mnk)
        self.num_warps_per_warp_group = 4
        self.num_threads_per_warp_group = self.num_warps_per_warp_group * 32
        self.threads_per_cta = (
            self.num_dma_warp_groups + self.num_mma_warp_groups
        ) * self.num_threads_per_warp_group
        self.load_warp_id = 0
        self.epi_store_warp_id = (
            self.num_dma_warp_groups * self.num_warps_per_warp_group
        )
        self.load_register_requirement = 40
        self.mma_register_requirement = 232
        self.smem_capacity = utils.get_smem_capacity_in_bytes("sm_90")

        self.ab_stage = None
        self.epi_stage = None

        self.a_smem_layout_staged = None
        self.b_smem_layout_staged = None
        self.epi_smem_layout_staged = None
        self.epi_tile = None

        self.shared_storage = None
        self.buffer_align_bytes = 1024

        self.num_mma_threads = (
            self.num_mma_warp_groups * self.num_threads_per_warp_group
        )
        self.epilog_sync_barrier = pipeline.NamedBarrier(
            barrier_id=1, num_threads=self.num_mma_threads
        )

        # Grouped GEMM: tensor map update mode
        self.tensormap_update_mode = tensormap_update_mode
        # Delegate A/B tensor map init to MMA warp for better latency hiding (SMEM mode)
        self.delegate_tensormap_ab_init = (
            tensormap_update_mode == utils.TensorMapUpdateMode.SMEM
        )
        # barrier_id=2 (barrier_id=1 is already used by epilog_sync_barrier)
        # Only the load warp (32 threads) + all MMA threads participate:
        # DMA warps 1-3 are idle and never reach this barrier.
        self.tensormap_ab_init_barrier = pipeline.NamedBarrier(
            barrier_id=2,
            num_threads=self.num_mma_threads + 32,
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
        """

        # check the cta tile shape
        if self.tile_shape_mnk[0] not in [64, 128]:
            raise ValueError("CTA tile shape M must be 64/128")
        if self.tile_shape_mnk[1] not in [64, 128, 256]:
            raise ValueError("CTA tile shape N must be 64/128/256")

        self.tiled_mma = sm90_utils.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_layout.sm90_mma_major_mode(),
            self.b_layout.sm90_mma_major_mode(),
            self.acc_dtype,
            self.atom_layout_mnk,
            tiler_mn=(64, self.tile_shape_mnk[1]),
        )
        mma_inst_shape_k = cute.size(self.tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        self.tile_shape_mnk = (
            self.tile_shape_mnk[0],
            self.tile_shape_mnk[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )

        self.cta_layout_mnk = cute.make_layout((*self.cluster_shape_mn, 1))
        self.num_mcast_ctas_a = self.cluster_shape_mn[1]
        self.num_mcast_ctas_b = self.cluster_shape_mn[0]
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1

        # Cluster tile shape used by group tile scheduler
        self.cluster_tile_shape_mnk = (
            self.tile_shape_mnk[0] * self.cluster_shape_mn[0],
            self.tile_shape_mnk[1] * self.cluster_shape_mn[1],
            self.tile_shape_mnk[2],
        )

        is_cooperative = self.atom_layout_mnk == (2, 1, 1)
        self.epi_tile = self._sm90_compute_tile_shape_or_override(
            self.tile_shape_mnk, self.c_dtype, is_cooperative=is_cooperative
        )

        # Compute stage before compute smem layout
        self.ab_stage, self.epi_stage = self._compute_stages(
            self.tile_shape_mnk,
            self.a_dtype,
            self.b_dtype,
            self.epi_tile,
            self.c_dtype,
            self.smem_capacity,
            self.occupancy,
        )

        (
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.epi_smem_layout_staged,
        ) = self._make_smem_layouts(
            self.tile_shape_mnk,
            self.epi_tile,
            self.a_dtype,
            self.a_layout,
            self.b_dtype,
            self.b_layout,
            self.ab_stage,
            self.c_dtype,
            self.c_layout,
            self.epi_stage,
        )

    @cute.jit
    def __call__(
        self,
        initial_a: cute.Tensor,
        initial_b: cute.Tensor,
        initial_c: cute.Tensor,
        group_count: cutlass.Constexpr[int],
        problem_shape_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        tensor_address_abc: cute.Tensor,
        total_num_clusters: cutlass.Constexpr[int],
        tensormap_cute_tensor: cute.Tensor,
        max_active_clusters: cutlass.Constexpr[int],
        stream: cuda.CUstream,
    ):
        """Execute the grouped GEMM operation.

        :param initial_a: Carries dtype+majorness only (shape irrelevant).
        :param initial_b: Carries dtype+majorness only (shape irrelevant).
        :param initial_c: Carries dtype+majorness only (shape irrelevant).
        :param group_count: Number of GEMM groups (compile-time constant).
        :param problem_shape_mnkl: Device tensor of shape (G, 4) Int32 with (M,N,K,L) per group.
        :param strides_abc: Device tensor of shape (G, 3, 2) Int32 with strides per group.
        :param tensor_address_abc: Device tensor of shape (G, 3) Int64 with base ptrs per group.
        :param total_num_clusters: Total clusters across all groups (compile-time constant).
        :param tensormap_cute_tensor: Tensor map workspace, shape (num_sms, 3, 16) Int64.
        :param max_active_clusters: Max active clusters (compile-time constant).
        :param stream: CUDA stream.
        """

        # Setup static attributes from initial tensor dtype/layout
        self.a_dtype = initial_a.element_type
        self.b_dtype = initial_b.element_type
        self.c_dtype = initial_c.element_type
        self.a_layout = utils.LayoutEnum.from_tensor(initial_a)
        self.b_layout = utils.LayoutEnum.from_tensor(initial_b)
        self.c_layout = utils.LayoutEnum.from_tensor(initial_c)

        if cutlass.const_expr(
            self.a_dtype.width == 16 and self.a_dtype != self.b_dtype
        ):
            raise TypeError(f"Type mismatch: {self.a_dtype} != {self.b_dtype}")
        if cutlass.const_expr(self.a_dtype.width != self.b_dtype.width):
            raise TypeError(
                f"Type width mismatch: {self.a_dtype.width} != {self.b_dtype.width}"
            )
        if cutlass.const_expr(self.a_dtype.width != 16 and self.a_dtype.width != 8):
            raise TypeError("a_dtype should be float16, float8, or int8")

        self._setup_attributes()

        tma_atom_a, tma_tensor_a = self._make_tma_atoms_and_tensors(
            initial_a,
            self.a_smem_layout_staged,
            (self.tile_shape_mnk[0], self.tile_shape_mnk[2]),
            self.cluster_shape_mn[1],
        )

        tma_atom_b, tma_tensor_b = self._make_tma_atoms_and_tensors(
            initial_b,
            self.b_smem_layout_staged,
            (self.tile_shape_mnk[1], self.tile_shape_mnk[2]),
            self.cluster_shape_mn[0],
        )

        tma_atom_c, tma_tensor_c = self._make_tma_store_atoms_and_tensors(
            initial_c,
            self.epi_smem_layout_staged,
            self.epi_tile,
        )

        tile_sched_params, grid = self._compute_grid(
            total_num_clusters,
            self.cluster_shape_mn,
            max_active_clusters,
        )

        # Number of Int64 words needed for the SMEM tensor map buffer (0 in GMEM mode)
        self.size_tensormap_in_i64 = (
            0
            if self.tensormap_update_mode == utils.TensorMapUpdateMode.GMEM
            else HopperGroupedGemmPersistentKernel.num_tensormaps
            * HopperGroupedGemmPersistentKernel.bytes_per_tensormap
            // 8
        )

        @cute.struct
        class SharedStorage:
            tensormap_buffer: cute.struct.MemRange[
                cutlass.Int64, self.size_tensormap_in_i64
            ]
            mainloop_pipeline_array_ptr: cute.struct.MemRange[
                cutlass.Int64, self.ab_stage * 2
            ]
            sA: cute.struct.Align[
                cute.struct.MemRange[
                    self.a_dtype, cute.cosize(self.a_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            sB: cute.struct.Align[
                cute.struct.MemRange[
                    self.b_dtype, cute.cosize(self.b_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            sC: cute.struct.Align[
                cute.struct.MemRange[
                    self.c_dtype,
                    cute.cosize(self.epi_smem_layout_staged),
                ],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        # Launch the kernel synchronously
        self.kernel(
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_c,
            tma_tensor_c,
            self.tiled_mma,
            self.cta_layout_mnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.epi_smem_layout_staged,
            tile_sched_params,
            group_count,
            problem_shape_mnkl,
            strides_abc,
            tensor_address_abc,
            tensormap_cute_tensor,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            min_blocks_per_mp=1,
            stream=stream,
        )
        return

    # GPU device kernel
    @cute.kernel
    def kernel(
        self,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom,
        mC_mnl: cute.Tensor,
        tiled_mma: cute.TiledMma,
        cta_layout_mnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        epi_smem_layout_staged: cute.ComposedLayout,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        group_count: cutlass.Constexpr[int],
        problem_sizes_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        ptrs_abc: cute.Tensor,
        tensormaps: cute.Tensor,
    ):
        """
        GPU device kernel performing the batched GEMM computation.

        :param tma_atom_a: TMA copy atom for A tensor
        :type tma_atom_a: cute.CopyAtom
        :param mA_mkl: Input tensor A
        :type mA_mkl: cute.Tensor
        :param tma_atom_b: TMA copy atom for B tensor
        :type tma_atom_b: cute.CopyAtom
        :param mB_nkl: Input tensor B
        :type mB_nkl: cute.Tensor
        :param tma_atom_c: TMA copy atom for C tensor
        :type tma_atom_c: cute.CopyAtom
        :param mC_mnl: Output tensor C
        :type mC_mnl: cute.Tensor
        :param tiled_mma: Tiled MMA object
        :type tiled_mma: cute.TiledMma
        :param cta_layout_mnk: CTA layout
        :type cta_layout_mnk: cute.Layout
        :param a_smem_layout_staged: Shared memory layout for A
        :type a_smem_layout_staged: cute.ComposedLayout
        :param b_smem_layout_staged: Shared memory layout for B
        :type b_smem_layout_staged: cute.ComposedLayout
        :param epi_smem_layout_staged: Shared memory layout for epilogue
        :type epi_smem_layout_staged: cute.ComposedLayout
        :param tile_sched_params: Parameters for the persistent tile scheduler
        :type tile_sched_params: utils.PersistentTileSchedulerParams
        """

        tidx, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        # Prefetch Tma desc
        if warp_idx == 0:
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_a)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_b)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_c)

        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        cluster_coord_mnk = cta_layout_mnk.get_flat_coord(cta_rank_in_cluster)

        a_mcast_mask = cute.make_layout_image_mask(
            cta_layout_mnk, cluster_coord_mnk, mode=1
        )
        b_mcast_mask = cute.make_layout_image_mask(
            cta_layout_mnk, cluster_coord_mnk, mode=0
        )

        a_mcast_mask = a_mcast_mask if self.is_a_mcast else 0
        b_mcast_mask = b_mcast_mask if self.is_b_mcast else 0
        a_smem_layout = cute.slice_(a_smem_layout_staged, (None, None, 0))
        b_smem_layout = cute.slice_(b_smem_layout_staged, (None, None, 0))
        tma_copy_bytes = cute.size_in_bytes(
            self.a_dtype, a_smem_layout
        ) + cute.size_in_bytes(self.b_dtype, b_smem_layout)

        # Alloc and init AB full/empty + ACC full mbar (pipeline)
        smem = cutlass.utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # mbar arrays
        mainloop_pipeline_array_ptr = storage.mainloop_pipeline_array_ptr.data_ptr()

        # Threads/warps participating in this pipeline
        mainloop_pipeline_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread
        )
        # Each warp will constribute to the arrive count with the number of mcast size
        mcast_size = self.num_mcast_ctas_a + self.num_mcast_ctas_b - 1
        consumer_arrive_cnt = (
            mcast_size * self.num_mma_warp_groups * self.num_warps_per_warp_group
        )
        mainloop_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, consumer_arrive_cnt
        )

        mainloop_pipeline = pipeline.PipelineTmaAsync.create(
            barrier_storage=mainloop_pipeline_array_ptr,
            num_stages=self.ab_stage,
            producer_group=mainloop_pipeline_producer_group,
            consumer_group=mainloop_pipeline_consumer_group,
            tx_count=tma_copy_bytes,
            cta_layout_vmnk=cute.make_layout((1, *cta_layout_mnk.shape)),
            defer_sync=True,
        )

        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=self.cluster_shape_mn, is_relaxed=True)

        # Generate smem tensor A/B
        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        sB = storage.sB.get_tensor(
            b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
        )
        sC = storage.sC.get_tensor(
            epi_smem_layout_staged.outer, swizzle=epi_smem_layout_staged.inner
        )

        # Local_tile partition global tensors
        # (bM, bK, RestM, RestK, RestL)
        gA_mkl = cute.local_tile(
            mA_mkl,
            cute.slice_(self.tile_shape_mnk, (None, 0, None)),
            (None, None, None),
        )
        # (bN, bK, RestN, RestK, RestL)
        gB_nkl = cute.local_tile(
            mB_nkl,
            cute.slice_(self.tile_shape_mnk, (0, None, None)),
            (None, None, None),
        )
        # (bM, bN, RestM, RestN, RestL)
        gC_mnl = cute.local_tile(
            mC_mnl,
            cute.slice_(self.tile_shape_mnk, (None, None, 0)),
            (None, None, None),
        )

        # Partition shared tensor for TMA load A/B
        # TMA load A partition_S/D
        a_cta_layout = cute.make_layout(cute.slice_(cta_layout_mnk, (0, None, 0)).shape)
        a_cta_crd = cluster_coord_mnk[1]
        tAsA, tAgA = cute.nvgpu.cpasync.tma_partition(
            tma_atom_a,
            a_cta_crd,
            a_cta_layout,
            cute.group_modes(sA, 0, 2),
            cute.group_modes(gA_mkl, 0, 2),
        )

        # TMA load B partition_S/D
        b_cta_layout = cute.make_layout(cute.slice_(cta_layout_mnk, (None, 0, 0)).shape)
        b_cta_crd = cluster_coord_mnk[0]
        tBsB, tBgB = cute.nvgpu.cpasync.tma_partition(
            tma_atom_b,
            b_cta_crd,
            b_cta_layout,
            cute.group_modes(sB, 0, 2),
            cute.group_modes(gB_nkl, 0, 2),
        )

        # Partition global tensor for TiledMMA_A/B/C
        warp_group_idx = cute.arch.make_warp_uniform(
            tidx // self.num_threads_per_warp_group
        )
        mma_warp_group_thread_layout = cute.make_layout(
            self.num_mma_warp_groups, stride=self.num_threads_per_warp_group
        )
        thr_mma = tiled_mma.get_slice(
            mma_warp_group_thread_layout(warp_group_idx - self.num_dma_warp_groups)
        )

        # Make fragments
        tCsA = thr_mma.partition_A(sA)
        tCsB = thr_mma.partition_B(sB)
        tCrA = tiled_mma.make_fragment_A(tCsA)
        tCrB = tiled_mma.make_fragment_B(tCsB)

        tCgC = thr_mma.partition_C(gC_mnl)
        acc_shape = tCgC.shape[:3]
        accumulators = cute.make_rmem_tensor(acc_shape, self.acc_dtype)

        # Cluster wait for barrier init
        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        #
        # Setup per-SM tensor map pointers (shared by DMA and MMA warps)
        #
        grid_dim = cute.arch.grid_dim()
        bid = cute.arch.block_idx()
        sm_idx = bid[2] * grid_dim[1] * grid_dim[0] + bid[1] * grid_dim[0] + bid[0]

        tensormap_manager = _FixedTensorMapManager(
            self.tensormap_update_mode,
            HopperGroupedGemmPersistentKernel.bytes_per_tensormap,
        )
        tensormap_a_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(sm_idx, 0, None)].iterator
        )
        tensormap_b_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(sm_idx, 1, None)].iterator
        )
        tensormap_c_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(sm_idx, 2, None)].iterator
        )

        # SMEM buffer pointers for tensor maps (only non-None in SMEM mode)
        if cutlass.const_expr(
            self.tensormap_update_mode == utils.TensorMapUpdateMode.SMEM
        ):
            smem_tm_base = storage.tensormap_buffer.data_ptr()
            tensormap_a_smem_ptr = smem_tm_base
            tensormap_b_smem_ptr = (
                smem_tm_base
                + HopperGroupedGemmPersistentKernel.bytes_per_tensormap // 8
            )
            tensormap_c_smem_ptr = (
                smem_tm_base
                + 2 * HopperGroupedGemmPersistentKernel.bytes_per_tensormap // 8
            )
        else:
            tensormap_a_smem_ptr = None
            tensormap_b_smem_ptr = None
            tensormap_c_smem_ptr = None

        tile_sched_params_for_sched = tile_sched_params

        is_dma_warp_group = warp_group_idx < self.num_dma_warp_groups
        if is_dma_warp_group:
            cute.arch.warpgroup_reg_dealloc(self.load_register_requirement)

        #
        # DMA warp group (load A/B with TMA, update tensor maps A/B per group)
        #
        if warp_idx == self.load_warp_id:
            # Initialize tensor maps A/B (either here or delegated to MMA warp)
            if cutlass.const_expr(not self.delegate_tensormap_ab_init):
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_a, tensormap_a_ptr, self.load_warp_id
                )
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_b, tensormap_b_ptr, self.load_warp_id
                )
                tensormap_manager.fence_tensormap_initialization()
            else:
                # Delegate path: wait for MMA warp to finish A/B tensor map init.
                # Must be unconditional (before the tile loop) so every CTA
                # participates even when it processes zero tiles.
                self.tensormap_ab_init_barrier.arrive_and_wait()

            last_group_idx = cutlass.Int32(-1)

            # Create a per-warp scheduler (same state — each warp runs its own instance)
            tile_sched = StaticPersistentGroupTileScheduler.create(
                tile_sched_params_for_sched,
                bid,
                grid_dim,
                self.cluster_tile_shape_mnk,
                utils.create_initial_search_state(),
                group_count,
                problem_sizes_mnkl,
            )
            work_tile = tile_sched.initial_work_tile_info()

            mainloop_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.ab_stage
            )

            while work_tile.is_valid_tile:
                grouped_info = work_tile.group_search_result
                cur_group_idx = grouped_info.group_idx
                cur_k_tile_cnt = grouped_info.cta_tile_count_k

                if cur_k_tile_cnt != 0:
                    is_group_changed = cur_group_idx != last_group_idx

                    if is_group_changed:
                        real_a = self.make_tensor_for_tensormap_update(
                            cur_group_idx,
                            self.a_dtype,
                            (
                                grouped_info.problem_shape_m,
                                grouped_info.problem_shape_n,
                                grouped_info.problem_shape_k,
                            ),
                            strides_abc,
                            ptrs_abc,
                            0,
                        )
                        real_b = self.make_tensor_for_tensormap_update(
                            cur_group_idx,
                            self.b_dtype,
                            (
                                grouped_info.problem_shape_m,
                                grouped_info.problem_shape_n,
                                grouped_info.problem_shape_k,
                            ),
                            strides_abc,
                            ptrs_abc,
                            1,
                        )
                        tensormap_manager.update_tensormap(
                            (real_a, real_b),
                            (tma_atom_a, tma_atom_b),
                            (tensormap_a_ptr, tensormap_b_ptr),
                            self.load_warp_id,
                            (tensormap_a_smem_ptr, tensormap_b_smem_ptr),
                        )
                        tensormap_manager.fence_tensormap_update(tensormap_a_ptr)
                        tensormap_manager.fence_tensormap_update(tensormap_b_ptr)

                    mma_tile_coord_mnl = (
                        grouped_info.cta_tile_idx_m,
                        grouped_info.cta_tile_idx_n,
                        0,
                    )
                    tAgA_slice = tAgA[
                        (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                    ]
                    tBgB_slice = tBgB[
                        (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                    ]

                    # Cache loop-invariant TMA descriptor pointers before K-loop.
                    # Keep two variants:
                    # - gmem descriptors for direct NVVM cp.async.bulk.tensor ops
                    # - generic descriptors for cute.copy fallback (mcast path)
                    #
                    # Using explicit gmem descriptors in the direct NVVM path avoids
                    # relying on generic-pointer lowering for the descriptor operand.
                    tma_a_desc_ptr_nvvm = tensormap_manager.get_tensormap_ptr(
                        tensormap_a_ptr, cute.AddressSpace.gmem
                    )
                    tma_b_desc_ptr_nvvm = tensormap_manager.get_tensormap_ptr(
                        tensormap_b_ptr, cute.AddressSpace.gmem
                    )
                    tma_a_desc_ptr_copy = tensormap_manager.get_tensormap_ptr(
                        tensormap_a_ptr, cute.AddressSpace.generic
                    )
                    tma_b_desc_ptr_copy = tensormap_manager.get_tensormap_ptr(
                        tensormap_b_ptr, cute.AddressSpace.generic
                    )
                    # Pre-compute loop-invariant TMA coordinates (m, n).
                    # For the non-mcast case (cluster 1x1), the TMA box offset is
                    # simply cta_tile_idx * tile_size.  k_coord is computed inside
                    # the loop because it varies per K-tile.
                    _tile_k = self.tile_shape_mnk[2]
                    _tile_m = self.tile_shape_mnk[0]
                    _tile_n = self.tile_shape_mnk[1]
                    use_nvvm_non_mcast_load = cutlass.const_expr(
                        _ENABLE_NVVM_NON_MCAST_LOAD
                        and not self.is_a_mcast
                        and not self.is_b_mcast
                    )
                    mainloop_producer_state.reset_count()
                    for k_tile in cutlass.range(0, cur_k_tile_cnt, 1, unroll=1):
                        mainloop_pipeline.producer_acquire(mainloop_producer_state)
                        if use_nvvm_non_mcast_load:
                            # Non-mcast path: use NVVM dialect TMA op with
                            # predicate= so operands are computed outside any
                            # predicated block.  This prevents PTXAS from
                            # generating the illegal @P0 R2UR instruction on
                            # sm_90a (CUDA_ERROR_ILLEGAL_INSTRUCTION / 715).
                            _tma_load_ab_nvvm_no_mcast(
                                k_tile * _tile_k,
                                mma_tile_coord_mnl[0] * _tile_m,
                                mma_tile_coord_mnl[1] * _tile_n,
                                tma_a_desc_ptr_nvvm,
                                tma_b_desc_ptr_nvvm,
                                tAsA[(None, mainloop_producer_state.index)].iterator,
                                tBsB[(None, mainloop_producer_state.index)].iterator,
                                mainloop_pipeline.producer_get_barrier(
                                    mainloop_producer_state
                                ),
                            )
                        else:
                            # Mcast path: fall back to cute.copy which handles
                            # the multicast mask for multi-CTA clusters.
                            cute.copy(
                                tma_atom_a,
                                tAgA_slice[(None, k_tile)],
                                tAsA[(None, mainloop_producer_state.index)],
                                tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                                    mainloop_producer_state
                                ),
                                mcast_mask=a_mcast_mask,
                                tma_desc_ptr=tma_a_desc_ptr_copy,
                            )
                            cute.copy(
                                tma_atom_b,
                                tBgB_slice[(None, k_tile)],
                                tBsB[(None, mainloop_producer_state.index)],
                                tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                                    mainloop_producer_state
                                ),
                                mcast_mask=b_mcast_mask,
                                tma_desc_ptr=tma_b_desc_ptr_copy,
                            )
                        mainloop_pipeline.producer_commit(mainloop_producer_state)
                        mainloop_producer_state.advance()
                else:
                    pass  # k_tile_cnt == 0: tensor map init already done before loop

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                last_group_idx = cur_group_idx

            mainloop_pipeline.producer_tail(mainloop_producer_state)

        #
        # MMA warp group (WGMMA + epilogue, update tensor map C per group)
        #
        if not is_dma_warp_group:
            cute.arch.warpgroup_reg_alloc(self.mma_register_requirement)

            # MMA warp always initializes tensor map C
            tensormap_manager.init_tensormap_from_atom(
                tma_atom_c, tensormap_c_ptr, self.epi_store_warp_id
            )
            # When delegating, MMA warp also initializes A/B and signals DMA warp
            if cutlass.const_expr(self.delegate_tensormap_ab_init):
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_a, tensormap_a_ptr, self.epi_store_warp_id
                )
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_b, tensormap_b_ptr, self.epi_store_warp_id
                )
                self.tensormap_ab_init_barrier.arrive_and_wait()

            tensormap_manager.fence_tensormap_initialization()

            tile_sched = StaticPersistentGroupTileScheduler.create(
                tile_sched_params_for_sched,
                bid,
                grid_dim,
                self.cluster_tile_shape_mnk,
                utils.create_initial_search_state(),
                group_count,
                problem_sizes_mnkl,
            )
            work_tile = tile_sched.initial_work_tile_info()

            mainloop_consumer_read_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.ab_stage
            )
            mainloop_consumer_release_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.ab_stage
            )

            num_k_blocks = cute.size(tCrA, mode=[2])

            # Partition for epilogue
            copy_atom_r2s = sm90_utils.sm90_get_smem_store_op(
                self.c_layout,
                elem_ty_d=self.c_dtype,
                elem_ty_acc=self.acc_dtype,
            )

            copy_atom_C = cute.make_copy_atom(
                cute.nvgpu.warp.StMatrix8x8x16bOp(
                    self.c_layout.is_m_major_c(),
                    4,
                ),
                self.c_dtype,
            )

            tiled_copy_C_Atom = cute.make_tiled_copy_C_atom(copy_atom_C, tiled_mma)

            tiled_copy_r2s = cute.make_tiled_copy_S(
                copy_atom_r2s,
                tiled_copy_C_Atom,
            )

            # (R2S, R2S_M, R2S_N, PIPE_D)
            thr_copy_r2s = tiled_copy_r2s.get_slice(
                tidx - self.num_dma_warp_groups * self.num_threads_per_warp_group
            )
            # (t)hread-partition for (r)egister to (s)mem copy (tRS_)
            tRS_sD = thr_copy_r2s.partition_D(sC)
            # (R2S, R2S_M, R2S_N)
            tRS_rAcc = tiled_copy_r2s.retile(accumulators)

            # Allocate D registers.
            rD_shape = cute.shape(thr_copy_r2s.partition_S(sC))
            tRS_rD_layout = cute.make_layout(rD_shape[:3])
            tRS_rD = cute.make_rmem_tensor(tRS_rD_layout.shape, self.acc_dtype)
            tRS_rD_out = cute.make_rmem_tensor(tRS_rD_layout.shape, self.c_dtype)
            size_tRS_rD = cute.size(tRS_rD)

            k_pipe_mmas = 1

            # Initialize tma store pipeline
            tma_store_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                self.num_mma_threads,
            )
            tma_store_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.epi_stage,
                producer_group=tma_store_producer_group,
            )

            last_group_idx_mma = cutlass.Int32(-1)

            while work_tile.is_valid_tile:
                grouped_info = work_tile.group_search_result
                cur_group_idx = grouped_info.group_idx
                cur_k_tile_cnt = grouped_info.cta_tile_count_k

                # Per-group tensor map C update (only epi_store warp issues it)
                is_group_changed = cur_group_idx != last_group_idx_mma
                if is_group_changed and warp_idx == self.epi_store_warp_id:
                    real_c = self.make_tensor_for_tensormap_update(
                        cur_group_idx,
                        self.c_dtype,
                        (
                            grouped_info.problem_shape_m,
                            grouped_info.problem_shape_n,
                            grouped_info.problem_shape_k,
                        ),
                        strides_abc,
                        ptrs_abc,
                        2,
                    )
                    tensormap_manager.update_tensormap(
                        (real_c,),
                        (tma_atom_c,),
                        (tensormap_c_ptr,),
                        self.epi_store_warp_id,
                        (tensormap_c_smem_ptr,),
                    )
                    tensormap_manager.fence_tensormap_update(tensormap_c_ptr)

                mma_tile_coord_mnl = (
                    grouped_info.cta_tile_idx_m,
                    grouped_info.cta_tile_idx_n,
                    0,
                )
                gC_mnl_slice = gC_mnl[(None, None, *mma_tile_coord_mnl)]

                # MAINLOOP
                mainloop_consumer_read_state.reset_count()
                mainloop_consumer_release_state.reset_count()
                accumulators.fill(0.0)
                tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, True)
                cute.nvgpu.warpgroup.fence()

                prologue_mma_cnt = cutlass.min(k_pipe_mmas, cur_k_tile_cnt)

                for k_tile in cutlass.range(0, prologue_mma_cnt, 1, unroll=1):
                    # Wait for TMA copies to complete
                    mainloop_pipeline.consumer_wait(mainloop_consumer_read_state)
                    # WGMMA
                    for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                        k_block_coord = (
                            None,
                            None,
                            k_block_idx,
                            mainloop_consumer_read_state.index,
                        )
                        cute.gemm(
                            tiled_mma,
                            accumulators,
                            tCrA[k_block_coord],
                            tCrB[k_block_coord],
                            accumulators,
                        )

                    cute.nvgpu.warpgroup.commit_group()
                    mainloop_consumer_read_state.advance()

                for k_tile in cutlass.range(prologue_mma_cnt, cur_k_tile_cnt, 1, unroll=1):
                    # Wait for TMA copies to complete
                    mainloop_pipeline.consumer_wait(mainloop_consumer_read_state)
                    # WGMMA
                    for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                        k_block_coord = (
                            None,
                            None,
                            k_block_idx,
                            mainloop_consumer_read_state.index,
                        )
                        cute.gemm(
                            tiled_mma,
                            accumulators,
                            tCrA[k_block_coord],
                            tCrB[k_block_coord],
                            accumulators,
                        )

                    cute.nvgpu.warpgroup.commit_group()
                    # Wait on the wgmma barrier for WGMMA to complete
                    cute.nvgpu.warpgroup.wait_group(k_pipe_mmas)

                    mainloop_pipeline.consumer_release(mainloop_consumer_release_state)
                    mainloop_consumer_release_state.advance()
                    mainloop_consumer_read_state.advance()

                cute.nvgpu.warpgroup.wait_group(0)
                for k_tile in cutlass.range(0, prologue_mma_cnt, 1, unroll=1):
                    mainloop_pipeline.consumer_release(mainloop_consumer_release_state)
                    mainloop_consumer_release_state.advance()

                # Epilogue
                tCgC_for_tma_partition = cute.zipped_divide(gC_mnl_slice, self.epi_tile)

                # thread(b)lock-partition for (s)mem to (g)mem copy (bSG_)
                bSG_sD, bSG_gD = cute.nvgpu.cpasync.tma_partition(
                    tma_atom_c,
                    0,
                    cute.make_layout(1),
                    cute.group_modes(sC, 0, 2),
                    tCgC_for_tma_partition,
                )

                epi_tile_num = cute.size(tCgC_for_tma_partition, mode=[1])
                epi_tile_shape = tCgC_for_tma_partition.shape[1]
                epi_tile_layout = cute.make_layout(
                    epi_tile_shape, stride=(epi_tile_shape[1], 1)
                )

                num_prev_epi_tiles = tile_sched.num_tiles_executed * epi_tile_num
                for epi_idx in cutlass.range_constexpr(epi_tile_num):
                    # Copy from accumulators to D registers
                    for epi_v in cutlass.range_constexpr(size_tRS_rD):
                        tRS_rD[epi_v] = tRS_rAcc[epi_idx * size_tRS_rD + epi_v]

                    # Type conversion
                    acc_vec = tRS_rD.load()
                    tRS_rD_out.store(acc_vec.to(self.c_dtype))

                    # Copy from D registers to shared memory
                    epi_buffer = (num_prev_epi_tiles + epi_idx) % cute.size(
                        tRS_sD, mode=[3]
                    )
                    cute.copy(
                        tiled_copy_r2s,
                        tRS_rD_out,
                        tRS_sD[(None, None, None, epi_buffer)],
                    )

                    cute.arch.fence_proxy(
                        "async.shared",
                        space="cta",
                    )
                    self.epilog_sync_barrier.arrive_and_wait()

                    gmem_coord = epi_tile_layout.get_hier_coord(epi_idx)
                    # Copy from shared memory to global memory (TMA store with updated desc)
                    if warp_idx == self.epi_store_warp_id:
                        cute.copy(
                            tma_atom_c,
                            bSG_sD[(None, epi_buffer)],
                            bSG_gD[(None, gmem_coord)],
                            tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                tensormap_c_ptr, cute.AddressSpace.generic
                            ),
                        )
                        tma_store_pipeline.producer_commit()
                        tma_store_pipeline.producer_acquire()

                    self.epilog_sync_barrier.arrive_and_wait()

                last_group_idx_mma = cur_group_idx
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            tma_store_pipeline.producer_tail()

    @cute.jit
    def make_tensor_for_tensormap_update(
        self,
        group_idx: cutlass.Int32,
        dtype: Type[cutlass.Numeric],
        problem_shape_mnk: tuple,
        strides_abc: cute.Tensor,
        tensor_address_abc: cute.Tensor,
        tensor_index: int,
    ):
        """Construct a global tensor for tensormap update from per-group metadata.

        :param group_idx: Index of the current group.
        :param dtype: Element type of the tensor (A, B, or C).
        :param problem_shape_mnk: (M, N, K) of the current group.
        :param strides_abc: Tensor of strides, shape (G, 3, 2), dtype Int32.
        :param tensor_address_abc: Tensor of base ptrs, shape (G, 3), dtype Int64.
        :param tensor_index: 0=A, 1=B, 2=C.
        """
        ptr_i64 = tensor_address_abc[(group_idx, tensor_index)]
        if cutlass.const_expr(
            not isclass(dtype) or not issubclass(dtype, cutlass.Numeric)
        ):
            raise TypeError(
                f"dtype must be a type of cutlass.Numeric, got {type(dtype)}"
            )
        tensor_gmem_ptr = cute.make_ptr(
            dtype, ptr_i64, cute.AddressSpace.gmem, assumed_align=16
        )

        strides_tensor_gmem = strides_abc[(group_idx, tensor_index, None)]
        strides_tensor_reg = cute.make_rmem_tensor(
            cute.make_layout(2),
            strides_abc.element_type,
        )
        cute.autovec_copy(strides_tensor_gmem, strides_tensor_reg)
        stride_mn = strides_tensor_reg[0]
        stride_k = strides_tensor_reg[1]
        c1 = cutlass.Int32(1)
        c0 = cutlass.Int32(0)

        if cutlass.const_expr(tensor_index == 0):  # tensor A
            m = problem_shape_mnk[0]
            k = problem_shape_mnk[2]
            return cute.make_tensor(
                tensor_gmem_ptr,
                cute.make_layout((m, k, c1), stride=(stride_mn, stride_k, c0)),
            )
        elif cutlass.const_expr(tensor_index == 1):  # tensor B
            n = problem_shape_mnk[1]
            k = problem_shape_mnk[2]
            return cute.make_tensor(
                tensor_gmem_ptr,
                cute.make_layout((n, k, c1), stride=(stride_mn, stride_k, c0)),
            )
        else:  # tensor C
            m = problem_shape_mnk[0]
            n = problem_shape_mnk[1]
            return cute.make_tensor(
                tensor_gmem_ptr,
                cute.make_layout((m, n, c1), stride=(stride_mn, stride_k, c0)),
            )

    @staticmethod
    def _compute_stages(
        tile_shape_mnk: tuple[int, int, int],
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        epi_tile: tuple[int, int],
        c_dtype: type[cutlass.Numeric],
        smem_capacity: int,
        occupancy: int,
    ) -> tuple[int, int]:
        """Computes the number of stages for A/B/C operands based on heuristics.

        :param tile_shape_mnk: The shape (M, N, K) of the CTA tile.
        :type tile_shape_mnk: tuple[int, int, int]
        :param a_dtype: Data type of operand A.
        :type a_dtype: type[cutlass.Numeric]
        :param b_dtype: Data type of operand B.
        :type b_dtype: type[cutlass.Numeric]
        :param epi_tile: Epilogue tile shape
        :type epi_tile: Tuple[int, int]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: type[cutlass.Numeric]
        :param smem_capacity: Total available shared memory capacity in bytes.
        :type smem_capacity: int
        :param occupancy: Target number of CTAs per SM (occupancy).
        :type occupancy: int

        :return: A tuple containing the computed number of stages for:
                 (A/B operand stages, epilogue stages)
        :rtype: tuple[int, int]
        """

        a_shape = cute.slice_(tile_shape_mnk, (None, 0, None))
        b_shape = cute.slice_(tile_shape_mnk, (0, None, None))
        ab_bytes_per_stage = (
            cute.size(a_shape) * a_dtype.width // 8
            + cute.size(b_shape) * b_dtype.width // 8
        )
        c_bytes_per_stage = cute.size(epi_tile) * c_dtype.width // 8
        epi_stage = 4
        epi_bytes = c_bytes_per_stage * epi_stage

        mbar_helpers_bytes = 1024

        ab_stage = (
            smem_capacity // occupancy - (mbar_helpers_bytes + epi_bytes)
        ) // ab_bytes_per_stage
        return ab_stage, epi_stage

    @staticmethod
    def _sm90_compute_tile_shape_or_override(
        tile_shape_mnk: tuple[int, int, int],
        element_type: type[cutlass.Numeric],
        is_cooperative: bool = False,
        epi_tile_override: Optional[tuple[int, int]] = None,
    ) -> tuple[int, int]:
        """Compute the epilogue tile shape or use override if provided.

        :param tile_shape_mnk: CTA tile shape (M,N,K)
        :type tile_shape_mnk: Tuple[int, int, int]
        :param element_type: Data type of elements
        :type element_type: type[cutlass.Numeric]
        :param is_cooperative: Whether to use cooperative approach
        :type is_cooperative: bool
        :param epi_tile_override: Optional override for epilogue tile shape
        :type epi_tile_override: Tuple[int, int] or None

        :return: Computed epilogue tile shape
        :rtype: Tuple[int, int]
        """
        if epi_tile_override is not None:
            return epi_tile_override
        if is_cooperative:
            tile_m = min(128, cute.size(tile_shape_mnk, mode=[0]))
            tile_n = min(32, cute.size(tile_shape_mnk, mode=[1]))
            return (tile_m, tile_n)
        else:
            n_perf = 64 if element_type.width == 8 else 32
            tile_m = min(64, cute.size(tile_shape_mnk, mode=[0]))
            tile_n = min(n_perf, cute.size(tile_shape_mnk, mode=[1]))
            return (tile_m, tile_n)

    @staticmethod
    def _make_smem_layouts(
        tile_shape_mnk: tuple[int, int, int],
        epi_tile: tuple[int, int],
        a_dtype: type[cutlass.Numeric],
        a_layout: utils.LayoutEnum,
        b_dtype: type[cutlass.Numeric],
        b_layout: utils.LayoutEnum,
        ab_stage: int,
        c_dtype: type[cutlass.Numeric],
        c_layout: utils.LayoutEnum,
        epi_stage: int,
    ) -> tuple[cute.ComposedLayout, cute.ComposedLayout, cute.ComposedLayout]:
        """Create shared memory layouts for A, B, and C tensors.

        :param tile_shape_mnk: CTA tile shape (M,N,K)
        :type tile_shape_mnk: Tuple[int, int, int]
        :param epi_tile: Epilogue tile shape
        :type epi_tile: Tuple[int, int]
        :param a_dtype: Data type for matrix A
        :type a_dtype: type[cutlass.Numeric]
        :param a_layout: Layout enum for matrix A
        :type a_layout: utils.LayoutEnum
        :param b_dtype: Data type for matrix B
        :type b_dtype: type[cutlass.Numeric]
        :param b_layout: Layout enum for matrix B
        :type b_layout: utils.LayoutEnum
        :param ab_stage: Number of stages for A/B tensors
        :type ab_stage: int
        :param c_dtype: Data type for output matrix C
        :type c_dtype: type[cutlass.Numeric]
        :param c_layout: Layout enum for the output matrix C
        :type c_layout: utils.LayoutEnum
        :param epi_stage: Number of epilogue stages
        :type epi_stage: int

        :return: Tuple of shared memory layouts for A, B, and C
        :rtype: Tuple[cute.ComposedLayout, cute.ComposedLayout, cute.ComposedLayout]
        """
        a_smem_shape = cute.slice_(tile_shape_mnk, (None, 0, None))

        a_is_k_major = (
            a_layout.sm90_mma_major_mode() == cute.nvgpu.warpgroup.OperandMajorMode.K
        )
        b_is_k_major = (
            b_layout.sm90_mma_major_mode() == cute.nvgpu.warpgroup.OperandMajorMode.K
        )
        a_major_mode_size = tile_shape_mnk[2 if a_is_k_major else 0]
        a_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(
                a_layout,
                a_dtype,
                a_major_mode_size,
            ),
            a_dtype,
        )
        a_smem_layout_staged = cute.tile_to_shape(
            a_smem_layout_atom,
            cute.append(a_smem_shape, ab_stage),
            order=(0, 1, 2) if a_is_k_major else (1, 0, 2),
        )

        b_smem_shape = cute.slice_(tile_shape_mnk, (0, None, None))

        b_major_mode_size = tile_shape_mnk[2 if b_is_k_major else 1]
        b_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(
                b_layout,
                b_dtype,
                b_major_mode_size,
            ),
            b_dtype,
        )
        b_smem_layout_staged = cute.tile_to_shape(
            b_smem_layout_atom,
            cute.append(b_smem_shape, ab_stage),
            order=(0, 1, 2) if b_is_k_major else (1, 0, 2),
        )

        c_smem_shape = epi_tile
        c_major_mode_size = epi_tile[1] if c_layout.is_n_major_c() else epi_tile[0]
        c_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(
                c_layout,
                c_dtype,
                c_major_mode_size,
            ),
            c_dtype,
        )
        epi_smem_layout_staged = cute.tile_to_shape(
            c_smem_layout_atom,
            cute.append(c_smem_shape, epi_stage),
            order=(1, 0, 2) if c_layout.is_m_major_c() else (0, 1, 2),
        )

        return a_smem_layout_staged, b_smem_layout_staged, epi_smem_layout_staged

    @staticmethod
    def _compute_grid(
        total_num_clusters: int,
        cluster_shape_mn: tuple[int, int],
        max_active_clusters: cutlass.Constexpr,
    ) -> tuple[utils.PersistentTileSchedulerParams, tuple]:
        """Compute tile scheduler params and grid shape for grouped GEMM.

        :param total_num_clusters: Total clusters across all groups.
        :type total_num_clusters: int
        :param cluster_shape_mn: Shape of each cluster in M, N dimensions.
        :type cluster_shape_mn: tuple[int, int]
        :param max_active_clusters: Maximum number of active clusters.
        :type max_active_clusters: cutlass.Constexpr

        :return: (tile_sched_params, grid)
        :rtype: tuple
        """
        problem_shape_ntile_mnl = (
            cluster_shape_mn[0],
            cluster_shape_mn[1],
            cutlass.Int32(total_num_clusters),
        )
        tile_sched_params = utils.PersistentTileSchedulerParams(
            problem_shape_ntile_mnl, (*cluster_shape_mn, 1)
        )
        grid = StaticPersistentGroupTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )
        return tile_sched_params, grid

    @staticmethod
    def _make_tma_store_atoms_and_tensors(
        tensor_c: cute.Tensor,
        epi_smem_layout_staged: cute.ComposedLayout,
        epi_tile: tuple[int, int],
    ) -> tuple[cute.CopyAtom, cute.Tensor]:
        """Create TMA atoms and tensors for C tensor storage.

        :param tensor_c: Output tensor C
        :type tensor_c: cute.Tensor
        :param epi_smem_layout_staged: Shared memory layout for epilogue
        :type epi_smem_layout_staged: cute.ComposedLayout
        :param epi_tile: Epilogue tile shape
        :type epi_tile: Tuple[int, int]

        :return: TMA atom and tensor for C
        :rtype: Tuple[cute.CopyAtom, cute.Tensor]
        """
        epi_smem_layout = cute.slice_(epi_smem_layout_staged, (None, None, 0))
        tma_atom_c, tma_tensor_c = cute.nvgpu.cpasync.make_tiled_tma_atom(
            cute.nvgpu.cpasync.CopyBulkTensorTileS2GOp(),
            tensor_c,
            epi_smem_layout,
            epi_tile,
        )

        return tma_atom_c, tma_tensor_c

    @staticmethod
    def _make_tma_atoms_and_tensors(
        tensor: cute.Tensor,
        smem_layout_staged: cute.ComposedLayout,
        smem_tile: tuple[int, int],
        mcast_dim: int,
    ) -> tuple[cute.CopyAtom, cute.Tensor]:
        """Create TMA atoms and tensors for input tensors.

        :param tensor: Input tensor (A or B)
        :type tensor: cute.Tensor
        :param smem_layout_staged: Shared memory layout for the tensor
        :type smem_layout_staged: cute.ComposedLayout
        :param smem_tile: Shared memory tile shape
        :type smem_tile: Tuple[int, int]
        :param mcast_dim: Multicast dimension
        :type mcast_dim: int

        :return: TMA atom and tensor
        :rtype: Tuple[cute.CopyAtom, cute.Tensor]
        """
        op = (
            cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp()
            if mcast_dim == 1
            else cute.nvgpu.cpasync.CopyBulkTensorTileG2SMulticastOp()
        )

        smem_layout = cute.slice_(smem_layout_staged, (None, None, 0))
        tma_atom, tma_tensor = cute.nvgpu.cpasync.make_tiled_tma_atom(
            op,
            tensor,
            smem_layout,
            smem_tile,
            num_multicast=mcast_dim,
        )
        return tma_atom, tma_tensor

    @staticmethod
    def is_valid_dtypes(
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
    ) -> bool:
        """
        Check if the dtypes are valid

        :param a_dtype: The data type of tensor A
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: The data type of tensor B
        :type b_dtype: Type[cutlass.Numeric]
        :param acc_dtype: The data type of the accumulator
        :type acc_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param a_major: major mode of tensor A
        :type a_major: str
        :param b_major: major mode of tensor B
        :type b_major: str

        :return: True if the dtypes are valid, False otherwise
        :rtype: bool
        """
        is_valid = True

        valid_ab_dtypes = {
            cutlass.Float16,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
            cutlass.Uint8,
            cutlass.Int8,
        }
        if a_dtype not in valid_ab_dtypes:
            is_valid = False
        if b_dtype not in valid_ab_dtypes:
            is_valid = False

        # make sure a_dtype == b_dtype for Float16
        if a_dtype.width == 16 and a_dtype != b_dtype:
            is_valid = False
        if a_dtype.width != b_dtype.width:
            is_valid = False
        if not a_dtype.is_same_kind(b_dtype):
            is_valid = False

        # for 8-bit types, this implementation only supports k-major layout
        if (a_dtype.width == 8 and a_major != "k") or (
            b_dtype.width == 8 and b_major != "k"
        ):
            is_valid = False

        # Define compatibility mapping between accumulator type and AB type
        acc_ab_compatibility = {
            cutlass.Float32: {
                cutlass.Float16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },
            cutlass.Float16: {
                cutlass.Float16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },
            cutlass.Int32: {cutlass.Uint8, cutlass.Int8},
        }
        # Check compatibility between accumulator type and A type
        if a_dtype not in acc_ab_compatibility[acc_dtype]:
            is_valid = False

        # Define compatibility mapping between accumulator type and C type
        acc_c_compatibility = {
            cutlass.Float32: {
                cutlass.Float32,
                cutlass.Float16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },
            cutlass.Float16: {
                cutlass.Float32,
                cutlass.Float16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },
            cutlass.Int32: {
                cutlass.Float32,
                cutlass.Float16,
                cutlass.Int32,
                cutlass.Int8,
                cutlass.Uint8,
            },
        }
        # Check compatibility between accumulator type and C type
        if c_dtype not in acc_c_compatibility[acc_dtype]:
            is_valid = False

        return is_valid

    @staticmethod
    def is_valid_tensor_alignment(
        m: int,
        n: int,
        k: int,
        l: int,
        ab_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
    ) -> bool:
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
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param a_major: The major axis of the A tensor
        :type a_major: str
        :param b_major: The major axis of the B tensor
        :type b_major: str
        :param c_major: The major axis of the C tensor
        :type c_major: str

        :return: True if the problem shape is valid, False otherwise
        :rtype: bool
        """
        is_valid = True

        def check_contigous_16B_alignment(dtype, is_mode0_major, tensor_shape):
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            num_contiguous_elements = 16 * 8 // dtype.width
            return num_major_elements % num_contiguous_elements == 0

        if (
            not check_contigous_16B_alignment(ab_dtype, a_major == "m", (m, k, l))
            or not check_contigous_16B_alignment(ab_dtype, b_major == "n", (n, k, l))
            or not check_contigous_16B_alignment(c_dtype, c_major == "m", (m, n, l))
        ):
            is_valid = False
        return is_valid


# ---------------------------------------------------------------------------
# Helper functions for tensor creation (ported from blackwell/grouped_gemm.py)
# ---------------------------------------------------------------------------

def create_tensor_and_stride(
    l: int,
    mode0: int,
    mode1: int,
    is_mode0_major: bool,
    dtype: Type[cutlass.Numeric],
    is_dynamic_layout: bool = True,
    torch_tensor_cpu: "torch.Tensor" = None,
) -> tuple:
    """Create a GPU tensor and return its pointer, torch tensor, cute tensor, CPU tensor, and strides."""
    if torch_tensor_cpu is None:
        torch_tensor_cpu = cutlass_torch.matrix(l, mode0, mode1, is_mode0_major, dtype)
    cute_tensor, torch_tensor = cutlass_torch.cute_tensor_like(
        torch_tensor_cpu, dtype, is_dynamic_layout, assumed_align=16
    )
    return (
        torch_tensor.data_ptr(),
        torch_tensor,
        cute_tensor,
        torch_tensor_cpu,
        torch_tensor.stride()[:-1],
    )


def create_tensors_for_all_groups(
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    torch_fp32_tensors_abc: List[List] = None,
) -> tuple:
    """Create A/B/C tensors for all groups."""
    if torch_fp32_tensors_abc is not None and len(torch_fp32_tensors_abc) != len(
        problem_sizes_mnkl
    ):
        raise ValueError("torch_fp32_tensors_abc must have one entry per group")

    new_torch_fp32_tensors_abc = (
        [] if torch_fp32_tensors_abc is None else torch_fp32_tensors_abc
    )
    torch_tensors_abc = []
    cute_tensors_abc = []
    strides_abc = []
    ptrs_abc = []

    for group_idx, (m, n, k, l) in enumerate(problem_sizes_mnkl):
        existing_cpu_a = (
            torch_fp32_tensors_abc[group_idx][0] if torch_fp32_tensors_abc else None
        )
        existing_cpu_b = (
            torch_fp32_tensors_abc[group_idx][1] if torch_fp32_tensors_abc else None
        )
        existing_cpu_c = (
            torch_fp32_tensors_abc[group_idx][2] if torch_fp32_tensors_abc else None
        )

        ptr_a, torch_a, cute_a, fp32_a, stride_mk_a = create_tensor_and_stride(
            l, m, k, a_major == "m", a_dtype, torch_tensor_cpu=existing_cpu_a
        )
        ptr_b, torch_b, cute_b, fp32_b, stride_nk_b = create_tensor_and_stride(
            l, n, k, b_major == "n", b_dtype, torch_tensor_cpu=existing_cpu_b
        )
        ptr_c, torch_c, cute_c, fp32_c, stride_mn_c = create_tensor_and_stride(
            l, m, n, c_major == "m", c_dtype, torch_tensor_cpu=existing_cpu_c
        )

        if torch_fp32_tensors_abc is None:
            new_torch_fp32_tensors_abc.append([fp32_a, fp32_b, fp32_c])

        ptrs_abc.append([ptr_a, ptr_b, ptr_c])
        torch_tensors_abc.append([torch_a, torch_b, torch_c])
        strides_abc.append([stride_mk_a, stride_nk_b, stride_mn_c])
        cute_tensors_abc.append((cute_a, cute_b, cute_c))

    return (
        ptrs_abc,
        torch_tensors_abc,
        cute_tensors_abc,
        strides_abc,
        new_torch_fp32_tensors_abc,
    )


def create_group_metadata(
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    a_major: str,
    b_major: str,
    c_major: str,
) -> tuple[list[list[int]], list[list[tuple[int, int]]]]:
    """Create per-group pointer/stride metadata without allocating operand tensors."""

    def get_stride(mode0: int, mode1: int, is_mode0_major: bool) -> tuple[int, int]:
        # Matches the layout produced by cutlass_torch.matrix(...).permute(...).
        return (1, mode0) if is_mode0_major else (mode1, 1)

    ptrs_abc = []
    strides_abc = []

    for m, n, k, _ in problem_sizes_mnkl:
        ptrs_abc.append([0, 0, 0])
        strides_abc.append(
            [
                get_stride(m, k, a_major == "m"),
                get_stride(n, k, b_major == "n"),
                get_stride(m, n, c_major == "m"),
            ]
        )

    return ptrs_abc, strides_abc


def _to_reference_operand_fp32(
    tensor: "torch.Tensor", dtype: Type[cutlass.Numeric]
) -> "torch.Tensor":
    """Convert an operand tensor to fp32 for host-side reference GEMM.

    For FP8 dtypes, tensors are stored as int8 bit-patterns by
    `cutlass_torch.matrix`, so we must reinterpret before casting.
    """
    tensor_cpu = tensor.cpu()
    if dtype == cutlass.Float8E4M3FN:
        return tensor_cpu.view(torch.float8_e4m3fn).to(dtype=torch.float32)
    if dtype == cutlass.Float8E5M2:
        return tensor_cpu.view(torch.float8_e5m2).to(dtype=torch.float32)
    return tensor_cpu.to(dtype=torch.float32)


def run(
    num_groups: int,
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    tile_shape_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    tensormap_update_mode: utils.TensorMapUpdateMode = utils.TensorMapUpdateMode.SMEM,
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    **kwargs,
):
    """Prepare per-group tensors, compile, launch, and validate the Hopper grouped GEMM kernel.

    :return: Execution time in microseconds.
    :rtype: float
    """
    print("Running Hopper Grouped GEMM test with:")
    print(f"{num_groups} groups")
    for i, (m, n, k, l) in enumerate(problem_sizes_mnkl):
        print(f"Group {i}: {m}x{n}x{k}x{l}")
    print(
        f"A dtype: {a_dtype}, B dtype: {b_dtype}, C dtype: {c_dtype}, Acc dtype: {acc_dtype}"
    )
    print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
    print(f"Tile Shape: {tile_shape_mn}, Cluster Shape: {cluster_shape_mn}")
    print(f"Tensor map update mode: {tensormap_update_mode}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    # Validate dtypes (reuse existing static method, check each group)
    for m, n, k, l in problem_sizes_mnkl:
        if not HopperGroupedGemmPersistentKernel.is_valid_dtypes(
            a_dtype, b_dtype, acc_dtype, c_dtype, a_major, b_major
        ):
            raise TypeError(
                f"unsupported dtype combination: A {a_dtype}, B {b_dtype}, "
                f"Acc {acc_dtype}, C {c_dtype}, {a_major=}, {b_major=}"
            )
        if not HopperGroupedGemmPersistentKernel.is_valid_tensor_alignment(
            m, n, k, l, a_dtype, c_dtype, a_major, b_major, c_major
        ):
            raise TypeError(
                f"Group {m}x{n}x{k}x{l}: contiguous dimension not 16-byte aligned"
            )

    compile_only = skip_ref_check and iterations <= 0

    if compile_only:
        ptrs_abc, strides_abc = create_group_metadata(
            problem_sizes_mnkl, a_major, b_major, c_major
        )
        torch_tensors_abc = []
        torch_fp32_tensors_abc = []
    else:
        # Create per-group tensors only when we will execute or validate.
        (
            ptrs_abc,
            torch_tensors_abc,
            _,
            strides_abc,
            torch_fp32_tensors_abc,
        ) = create_tensors_for_all_groups(
            problem_sizes_mnkl, a_dtype, b_dtype, c_dtype, a_major, b_major, c_major
        )

    # Build small "initial" tensors that carry only dtype+majorness (used for TMA atom init)
    alignment = 16
    min_ab_size = alignment * 8 // a_dtype.width
    min_c_size = alignment * 8 // c_dtype.width
    initial_cute_tensors_abc = [
        create_tensor_and_stride(1, min_ab_size, min_ab_size, a_major == "m", a_dtype)[2],
        create_tensor_and_stride(1, min_ab_size, min_ab_size, b_major == "n", b_dtype)[2],
        create_tensor_and_stride(1, min_c_size, min_c_size, c_major == "m", c_dtype)[2],
    ]

    hardware_info = utils.HardwareInfo()
    sm_count = hardware_info.get_max_active_clusters(1)
    max_active_clusters = hardware_info.get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    # Tensor map workspace: (num_sms, 3, bytes_per_tensormap // 8) of Int64
    tensormap_shape = (
        sm_count,
        HopperGroupedGemmPersistentKernel.num_tensormaps,
        HopperGroupedGemmPersistentKernel.bytes_per_tensormap // 8,
    )
    tensor_of_tensormap, tensor_of_tensormap_torch = cutlass_torch.cute_tensor_like(
        torch.empty(tensormap_shape, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
    )

    grouped_gemm = HopperGroupedGemmPersistentKernel(
        acc_dtype, tile_shape_mn, cluster_shape_mn,
        swizzle_size=1, raster_along_m=True,
        tensormap_update_mode=tensormap_update_mode,
    )

    # Build device tensors for problem shapes, strides, and pointers
    tensor_of_dim_size_mnkl, tensor_of_dim_size_mnkl_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(problem_sizes_mnkl, dtype=torch.int32),
        cutlass.Int32,
        is_dynamic_layout=False,
        assumed_align=16,
    )
    tensor_of_strides_abc, tensor_of_strides_abc_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(strides_abc, dtype=torch.int32),
        cutlass.Int32,
        is_dynamic_layout=False,
        assumed_align=16,
    )
    tensor_of_ptrs_abc, tensor_of_ptrs_abc_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(ptrs_abc, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    # Compute total number of cluster tiles across all groups
    def compute_total_num_clusters(
        problem_sizes: List[Tuple[int, int, int, int]],
        cluster_tile_shape_mn: Tuple[int, int],
    ) -> int:
        total = 0
        for m, n, _, _ in problem_sizes:
            nm = (m + cluster_tile_shape_mn[0] - 1) // cluster_tile_shape_mn[0]
            nn = (n + cluster_tile_shape_mn[1] - 1) // cluster_tile_shape_mn[1]
            total += nm * nn
        return total

    # cluster tile shape for Hopper: tile_shape_mn * cluster_shape_mn
    cluster_tile_shape_mn = (
        tile_shape_mn[0] * cluster_shape_mn[0],
        tile_shape_mn[1] * cluster_shape_mn[1],
    )
    total_num_clusters = compute_total_num_clusters(
        problem_sizes_mnkl, cluster_tile_shape_mn
    )

    current_stream = cutlass_torch.default_stream()

    # Compile kernel
    _compiler = cute.compile
    if os.environ.get("CUTE_DSL_KEEP_PTX"):
        _compiler = cute.compile[cute.KeepPTX()]
    compiled_grouped_gemm = _compiler(
        grouped_gemm,
        initial_cute_tensors_abc[0],
        initial_cute_tensors_abc[1],
        initial_cute_tensors_abc[2],
        num_groups,
        tensor_of_dim_size_mnkl,
        tensor_of_strides_abc,
        tensor_of_ptrs_abc,
        total_num_clusters,
        tensor_of_tensormap,
        max_active_clusters,
        current_stream,
    )

    if not skip_ref_check:
        compiled_grouped_gemm(
            initial_cute_tensors_abc[0],
            initial_cute_tensors_abc[1],
            initial_cute_tensors_abc[2],
            tensor_of_dim_size_mnkl,
            tensor_of_strides_abc,
            tensor_of_ptrs_abc,
            tensor_of_tensormap,
            current_stream,
        )
        torch.cuda.synchronize()

        for i, (a_t, b_t, c_t) in enumerate(torch_tensors_abc):
            a_ref = _to_reference_operand_fp32(a_t, a_dtype)
            b_ref = _to_reference_operand_fp32(b_t, b_dtype)
            ref = torch.einsum(
                "mkl,nkl->mnl",
                a_ref,
                b_ref,
            )
            print(f"Checking group {i}...")
            torch.testing.assert_close(
                c_t.cpu(),
                ref.to(cutlass_torch.dtype(c_dtype)),
                atol=tolerance,
                rtol=1e-03,
            )

    if iterations <= 0:
        return 0

    def generate_tensors():
        (
            ptrs_abc_ws,
            torch_tensors_abc_ws,
            _,
            strides_abc_ws,
            __,
        ) = create_tensors_for_all_groups(
            problem_sizes_mnkl, a_dtype, b_dtype, c_dtype, a_major, b_major, c_major,
            torch_fp32_tensors_abc,
        )
        init_ws = [
            create_tensor_and_stride(1, min_ab_size, min_ab_size, a_major == "m", a_dtype)[2],
            create_tensor_and_stride(1, min_ab_size, min_ab_size, b_major == "n", b_dtype)[2],
            create_tensor_and_stride(1, min_c_size, min_c_size, c_major == "m", c_dtype)[2],
        ]
        strides_ws, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(strides_abc_ws, dtype=torch.int32),
            cutlass.Int32, is_dynamic_layout=False, assumed_align=16,
        )
        ptrs_ws, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(ptrs_abc_ws, dtype=torch.int64),
            cutlass.Int64, is_dynamic_layout=False, assumed_align=16,
        )
        tensormap_ws, _ = cutlass_torch.cute_tensor_like(
            torch.empty(tensormap_shape, dtype=torch.int64),
            cutlass.Int64, is_dynamic_layout=False,
        )
        args = testing.JitArguments(
            init_ws[0], init_ws[1], init_ws[2],
            tensor_of_dim_size_mnkl,
            strides_ws, ptrs_ws, tensormap_ws,
            current_stream,
        )
        return args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = sum(
            t.numel() * t.element_size()
            for group in torch_tensors_abc
            for t in group
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_grouped_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    runtime_s = exec_time / 1.0e6
    fmas = sum(m * n * k for m, n, k, _ in problem_sizes_mnkl)
    gflops = (2 * fmas / 1.0e9) / runtime_s
    print(f"Average Runtime : {exec_time / 1000:.3f} ms")
    print(f"GFLOPS          : {gflops:.1f}")

    return exec_time


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _parse_comma_separated_ints(s: str) -> tuple:
    try:
        return tuple(int(x.strip()) for x in s.split(","))
    except ValueError:
        raise argparse.ArgumentTypeError("Expected comma-separated integers.")


def _parse_problem_sizes(s: str) -> List[Tuple[int, ...]]:
    """Parse e.g. '(4096,4096,4096,1),(512,512,512,1)' into a list of tuples."""
    s = s.strip()
    if s.startswith("("):
        tuples = s.strip("()").split("),(")
        result = []
        for t in tuples:
            nums = [int(x.strip()) for x in t.split(",")]
            result.append(tuple(nums))
        return result
    raise argparse.ArgumentTypeError(
        "Expected a list of tuples like '(M,N,K,L),(M,N,K,L)'"
    )


def _validate_problem_sizes_args(args, parser: argparse.ArgumentParser) -> None:
    if len(args.problem_sizes_mnkl) not in (0, args.num_groups):
        parser.error("--problem_sizes_mnkl must contain exactly --num_groups tuples")

    for _, _, _, l in args.problem_sizes_mnkl:
        if l != 1:
            parser.error("l (batch size) must be 1 for all groups")


def _resolve_tensormap_update_mode(
    mode: str, parser: argparse.ArgumentParser
) -> utils.TensorMapUpdateMode:
    if mode == "GMEM":
        return utils.TensorMapUpdateMode.GMEM
    if mode == "SMEM":
        return utils.TensorMapUpdateMode.SMEM
    parser.error("--tensormap_update_mode must be GMEM or SMEM")
    return utils.TensorMapUpdateMode.SMEM


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Hopper Grouped GEMM (CuTe DSL)"
    )
    parser.add_argument(
        "--num_groups", type=int, default=1, help="Number of groups"
    )
    parser.add_argument(
        "--problem_sizes_mnkl",
        type=_parse_problem_sizes,
        default=((4096, 4096, 4096, 1),),
        help="Problem sizes per group, e.g. '(4096,4096,4096,1),(512,512,512,1)'",
    )
    parser.add_argument(
        "--tile_shape_mn",
        type=_parse_comma_separated_ints,
        choices=[(128, 128), (128, 256), (128, 64), (64, 64)],
        default=(128, 128),
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=_parse_comma_separated_ints,
        choices=[(1, 1), (2, 1), (1, 2), (2, 2)],
        default=(1, 1),
    )
    parser.add_argument(
        "--tensormap_update_mode",
        type=str,
        choices=["GMEM", "SMEM"],
        default="SMEM",
        help="Tensor map update mode",
    )
    parser.add_argument("--a_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--b_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--a_major", choices=["k", "m"], default="k")
    parser.add_argument("--b_major", choices=["k", "n"], default="k")
    parser.add_argument("--c_major", choices=["n", "m"], default="n")
    parser.add_argument("--tolerance", type=float, default=1e-1)
    parser.add_argument("--warmup_iterations", type=int, default=0, help="Warmup iterations")
    parser.add_argument(
        "--iterations", type=int, default=1, help="Number of iterations to run the kernel"
    )
    parser.add_argument("--skip_ref_check", action="store_true", help="Skip reference checking")
    parser.add_argument("--use_cold_l2", action="store_true", default=False, help="Use cold L2")

    args = parser.parse_args()

    _validate_problem_sizes_args(args, parser)
    tensormap_update_mode = _resolve_tensormap_update_mode(
        args.tensormap_update_mode, parser
    )

    torch.manual_seed(2025)

    run(
        args.num_groups,
        args.problem_sizes_mnkl,
        args.a_dtype,
        args.b_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.tile_shape_mn,
        args.cluster_shape_mn,
        tensormap_update_mode,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
    )
    print("PASS")
