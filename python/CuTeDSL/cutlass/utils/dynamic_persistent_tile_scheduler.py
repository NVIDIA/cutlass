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

from typing import Tuple

from cutlass.cutlass_dsl import (
    Boolean,
    Integer,
    Int32,
    min,
    extract_mlir_values,
    new_from_mlir_values,
    dsl_user_op,
    T,
)
from cutlass._mlir import ir
from cutlass.utils.static_persistent_tile_scheduler import (
    WorkTileInfo,
)
import cutlass.cute as cute

class ClcDynamicPersistentTileSchedulerParams:
    """A class to represent parameters for a dynamic persistent tile scheduler.

    This class is designed to manage and compute the layout of clusters and tiles
    in a batched gemm problem.

    :ivar cluster_shape_mn: Shape of the cluster in (m, n) dimensions (K dimension cta count must be 1).
    :type cluster_shape_mn: tuple
    """

    def __init__(
        self,
        problem_shape_ntile_mnl: cute.Shape,
        cluster_shape_mnk: cute.Shape,
        *,
        loc=None,
        ip=None,
    ):
        """
        Initializes the ClcDynamicPersistentTileSchedulerParams with the given parameters.

        :param problem_shape_ntile_mnl: The shape of the problem in terms of
            number of CTA (Cooperative Thread Array) in (m, n, l) dimensions.
        :type problem_shape_ntile_mnl: cute.Shape
        :param cluster_shape_mnk: The shape of the cluster in (m, n) dimensions.
        :type cluster_shape_mnk: cute.Shape

        :raises ValueError: If cluster_shape_k is not 1.
        """

        if cluster_shape_mnk[2] != 1:
            raise ValueError(f"unsupported cluster_shape_k {cluster_shape_mnk[2]}")

        self.problem_shape_ntile_mnl = problem_shape_ntile_mnl
        # cluster_shape_mnk is kept for reconstruction
        self._cluster_shape_mnk = cluster_shape_mnk
        self.cluster_shape_mn = cluster_shape_mnk[:2]
        self._loc = loc

    def __extract_mlir_values__(self):
        values, self._values_pos = [], []
        for obj in [self.problem_shape_ntile_mnl, self._cluster_shape_mnk]:
            obj_values = extract_mlir_values(obj)
            values += obj_values
            self._values_pos.append(len(obj_values))
        return values

    def __new_from_mlir_values__(self, values):
        obj_list = []
        for obj, n_items in zip(
            [self.problem_shape_ntile_mnl, self._cluster_shape_mnk], self._values_pos
        ):
            obj_list.append(new_from_mlir_values(obj, values[:n_items]))
            values = values[n_items:]
        return ClcDynamicPersistentTileSchedulerParams(
            *(tuple(obj_list)), loc=self._loc
        )

    @dsl_user_op
    def get_grid_shape(self, *, loc=None, ip=None) -> Tuple[Integer, Integer, Integer]:
        """
        Computes the grid shape based on the problem shape and cluster shape.

        :return: the grid is the CTA numbers that has aligned with cluster shape.
        """

        problem_ceiling_cta_mnl = cute.round_up(
            self.problem_shape_ntile_mnl, self._cluster_shape_mnk
        )
        return problem_ceiling_cta_mnl

class ClcDynamicPersistentTileScheduler:
    """A scheduler for dynamic persistent tile execution in CUTLASS/CuTe kernels.

    :ivar params: Tile schedule related params, including cluster shape.
    :type params: ClcDynamicPersistentTileSchedulerParams
    :ivar cta_id_in_cluster: ID of the CTA within its cluster
    :type cta_id_in_cluster: cute.Coord
    :ivar _num_tiles_executed: Counter for executed tiles
    :type _num_tiles_executed: Int32
    """

    def __init__(
        self,
        params: ClcDynamicPersistentTileSchedulerParams,
        cta_id_in_cluster: cute.Coord,
        num_tiles_executed: Int32,
        clc_response_ptr: cute.Pointer,
        block_idx: Tuple[Integer, Integer, Integer],
    ):
        """
        Initializes the ClcDynamicPersistentTileScheduler with the given parameters.

        :param params: Tile schedule related params, including cluster shape.
        :type params: ClcDynamicPersistentTileSchedulerParams
        :param cta_id_in_cluster: ID of the CTA within its cluster.
        :type cta_id_in_cluster: cute.Coord
        :param num_tiles_executed: Counter for executed tiles.
        :type num_tiles_executed: Int32
        :param clc_response_ptr: Pointer of the clc rsponse.
        :type clc_response_ptr: Tuple[Integer, Integer, Integer, Integer]
        :param block_idx: The block index.
        :type block_idx: Tuple[Integer, Integer, Integer]
        """
        self.params = params
        self.cta_id_in_cluster = cta_id_in_cluster
        self._num_tiles_executed = num_tiles_executed
        self._clc_response_ptr = clc_response_ptr
        self._block_idx = block_idx

    def __extract_mlir_values__(self) -> list[ir.Value]:
        values = extract_mlir_values(self.cta_id_in_cluster)
        values.extend(extract_mlir_values(self._num_tiles_executed))
        values.extend(extract_mlir_values(self._clc_response_ptr))
        values.extend(extract_mlir_values(self._block_idx))
        return values

    def __new_from_mlir_values__(
        self, values: list[ir.Value]
    ) -> "ClcDynamicPersistentTileScheduler":
        assert len(values) == 8
        new_cta_id_in_cluster = new_from_mlir_values(
            self.cta_id_in_cluster, values[0:3]
        )
        new_num_tiles_executed = new_from_mlir_values(
            self._num_tiles_executed, [values[3]]
        )
        new_clc_response_ptr = new_from_mlir_values(self._clc_response_ptr, [values[4]])
        new_block_idx = new_from_mlir_values(self._block_idx, values[5:8])
        return ClcDynamicPersistentTileScheduler(
            self.params,
            new_cta_id_in_cluster,
            new_num_tiles_executed,
            new_clc_response_ptr,
            new_block_idx,
        )

    @dsl_user_op
    @staticmethod
    def create(
        params: ClcDynamicPersistentTileSchedulerParams,
        block_idx: Tuple[Integer, Integer, Integer],
        grid_dim: Tuple[Integer, Integer, Integer],
        clc_response_ptr: cute.Pointer,
        *,
        loc=None,
        ip=None,
    ):
        """Initialize the dynamic persistent tile scheduler.

        :param params: Parameters for the persistent
            tile scheduler.
        :type params: ClcDynamicPersistentTileSchedulerParams
        :param block_idx: The 3d block index in the format (bidx, bidy, bidz).
        :type block_idx: Tuple[Integer, Integer, Integer]
        :param grid_dim: The 3d grid dimensions for kernel launch.
        :type grid_dim: Tuple[Integer, Integer, Integer]

        :return: A ClcDynamicPersistentTileScheduler object.
        :rtype: ClcDynamicPersistentTileScheduler
        """
        params = params

        bidx, bidy, bidz = block_idx

        # CTA id in the cluster
        cta_id_in_cluster = (
            Int32(bidx % params.cluster_shape_mn[0]),
            Int32(bidy % params.cluster_shape_mn[1]),
            Int32(0),
        )

        # Initialize number of tiles executed to zero
        num_tiles_executed = Int32(0)
        # Initialize clc response pointer
        clc_response_ptr = clc_response_ptr
        # The block index
        block_idx = block_idx

        return ClcDynamicPersistentTileScheduler(
            params,
            cta_id_in_cluster,
            num_tiles_executed,
            clc_response_ptr,
            block_idx,
        )

    # called by host
    @dsl_user_op
    def get_grid_shape(
        params: ClcDynamicPersistentTileSchedulerParams,
        *,
        loc=None,
        ip=None,
    ) -> Tuple[Integer, Integer, Integer]:
        """Calculates the grid shape to be launched on GPU using problem shape,
        threadblock shape, and active cluster size.

        :param params: Parameters for grid shape calculation.
        :type params: ClcDynamicPersistentTileSchedulerParams

        :return: The calculated 3d grid shape.
        :rtype: Tuple[Integer, Integer, Integer]
        """

        return params.get_grid_shape(loc=loc, ip=ip)

    @dsl_user_op
    def work_tile_info_from_clc_response(
        self, result_addr: Int32, *, loc=None, ip=None
    ) -> WorkTileInfo:
        """
        Simulates parsing CLC response data in Python.
        result_addr: 16-byte response data (simulating shared memory access)
        """
        m_idx, n_idx, l_idx, vld = cute.arch.clc_response(result_addr, loc=loc, ip=ip)
        cute.arch.fence_proxy(
            cute.arch.ProxyKind.async_shared,
            space=cute.arch.SharedSpace.shared_cta,
        )
        cta_idx_in_cluster, cta_idy_in_cluster, _ = self.cta_id_in_cluster
        cur_tile_coord = (m_idx + cta_idx_in_cluster, n_idx + cta_idy_in_cluster, l_idx)
        return WorkTileInfo(cur_tile_coord, vld)

    @dsl_user_op
    def get_current_work(self, *, loc=None, ip=None) -> WorkTileInfo:
        smem_addr = self._clc_response_ptr
        work_tile = self.work_tile_info_from_clc_response(smem_addr)
        return work_tile

    @dsl_user_op
    def initial_work_tile_info(self, *, loc=None, ip=None) -> WorkTileInfo:
        bidx, bidy, bidz = self._block_idx
        return WorkTileInfo((bidx, bidy, bidz), True)

    @dsl_user_op
    def advance_to_next_work(self, mbarrier_addr, loc=None, ip=None):
        # Query new work tile
        with cute.arch.elect_one():
            cute.arch.issue_clc_query(
                mbarrier_addr, self._clc_response_ptr, loc=loc, ip=ip
            )
        self._num_tiles_executed += Int32(1)

    @property
    def num_tiles_executed(self) -> Int32:
        return self._num_tiles_executed
