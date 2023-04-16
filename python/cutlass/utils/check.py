#################################################################################################
#
# Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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
#
#################################################################################################

"""
Utility functions for checking constraints on kernels and calculating kernel attributes
"""

import ctypes

import cutlass_bindings
import cutlass
from cutlass.backend.library import DataTypeSize, TileDescription


def calculate_smem_usage_per_stage(tile_description, operation_kind):
    """
    Returns the amount of shared memory in bytes consumed in a single stage of a kernel.

    :return: number of bytes of shared memory consumed by a single stage
    :rtype: int
    """
    m, n, k = tile_description.threadblock_shape

    if operation_kind == cutlass.OperationKind.Gemm:
        stage_barrier_bytes = 32
        return (
            (DataTypeSize[tile_description.math_instruction.element_a] * m * k // 8)
            + (DataTypeSize[tile_description.math_instruction.element_b] * k * n // 8)
            + stage_barrier_bytes
        )
    else:
        raise Exception(f"No available shared memory calculation for operation kind {operation.operation_kind}")


def calculate_smem_usage(operation):
    """
    Returns the amount of shared memory in bytes consumed by a kernel.

    :return: number of bytes of shared memory consumed by the operation
    :return: int
    """
    _per_stage = calculate_smem_usage_per_stage(operation.tile_description, operation.operation_kind)
    return _per_stage * operation.tile_description.stages


def valid_stage_count(cc: int, td: TileDescription) -> tuple:
    """
    Checks whether a device with `cc` supports the number of stages within `tile_description`, both
    based on raw limits on the number of stages and based on shared memory capacity

    :param cc: compute capability of device in question
    :type cc: int
    :param td: tile description to check
    :type td: TileDescription

    :return: tuple with the first element indicating whether the provided tile description is
             valid for the provided device and the second element being an error message
    :rtype: tuple
    """
    if cc == 90 and (td.stages is None or td.stages == 0):
        # Stage count of None or 0 for SM90 indicates that the CollectiveBuilder automatically
        # determines the stage count to use. Thus, all settings are valid in these scenarios.
        return (True, "")

    if td.stages <= 0:
        return (False, f"Stage counts must be positive integers. Tile description has stage count of {td.stages}.")

    if cc < 80 and td.stages != 2:
        return (False, f"Tile description has stage count of {td.stages}, "
                       f"but only 2 stages are supported on SM{cc}.")

    smem_per_stage = calculate_smem_usage_per_stage(td, cutlass.OperationKind.Gemm)
    smem_arch = cutlass.SharedMemPerCC[cc] << 10
    if (smem_per_stage * td.stages) > smem_arch:
        return ( False,
            "Configuration uses too much shared memory. Consider reducing stage count or tile shape.\n"
            f"Details: configuration uses {smem_per_stage} bytes of shared memory per stage, and "
            f"{td.stages} stages for a total of {smem_per_stage * td.stages} bytes.\n"
            f"The maxmium amoung of shared memory that can be used per block on CC {cc} is {smem_arch}.")

    return (True, "")


def valid_cluster_shape(cc: int, cluster_shape: list) -> tuple:
    """
    Checks whether a device with `cc` supports a thread block cluster of shape `cluster_shape`.

    :param cc: compute capability of device in question
    :type cc: int
    :param cluster_shape: dimensions of thread block cluster shape to check
    :type cluster_shape: list

    :return: tuple with the first element indicating whether the provided cluster shape is
             valid for the provided device and the second element being an error message
    :rtype: tuple
    """

    if cc < 90:
        if cluster_shape != [1, 1, 1]:
            return (False,
                    f"Cluster shape for pre-SM90 architectures must be [1, 1, 1]. Received cluster shape of "
                    f"{cluster_shape} for SM{cc}.")
        else:
            return (True, "")

    if len(cluster_shape) != 3:
        return (False,
                f"Cluster shapes must be rank-3. Received {cluster_shape} (rank {len(cluster_shape)}")

    if cluster_shape[2] != 1:
        return (False,
                "CUTLASS kernels currently require the third dimension of cluster shape to be 1. "
                f"Received cluster shape of {cluster_shape}.")

    # The CUDA programming guide currently defines a maximum of 8 thread blocks per cluster
    # as being portably supported (https://docs.nvidia.com/cuda/cuda-c-programming-guide/#thread-block-clusters).
    # Current CUTLASS kernels only have non-unit cluster dimensions within the first two dimensions,
    # so we check that the first two dimensions of the cluster shape do not exceed 8 thread blocks in total.
    blocks_in_2d = cluster_shape[0] * cluster_shape[1]
    if blocks_in_2d > 8:
        return (False,
            f"Thread block clusters with more than 8 thread blocks are currently unsupported on SM{cc}. "
            f"Received cluster shape {cluster_shape}, which has {blocks_in_2d} thread blocks.")
    return (True, "")


def valid_kernel_schedule(cc: int, kernel_schedule: cutlass.KernelScheduleType) -> tuple:
    """
    Checks whether a device with ``cc`` supports ``kernel_schedule``.

    :param cc: compute capability of device in question
    :type cc: int
    :param kernel_schedule: kernel schedule type
    :type KernelScheduleType: cutlass.KernelScheduleType

    :return: tuple with the first element indicating whether the provided kernel schedule is
             valid for the provided device and the second element being an error message
    :rtype: tuple
    """
    if kernel_schedule != cutlass.KernelScheduleType.ScheduleAuto and cc < 90:
        return (False, "Non-default kernel schedules are only supported on SM90 and beyond")
    return (True, "")


def alignment_or_default(alignment_provided: int, default_alignment: int) -> int:
    """
    Returns `alignment_provided` if it is set, otherwise `default_alignment` and checks
    that `alignment_provided` does not exceed `default_alignment`.

    :param alignment_provided: alignment preference specified. Can be None.
    :type alignment_provided: int
    :param default_alignment: alignment to use if `alignment_provided` is None
    :type default_alignment: int

    :return: alignment to use
    :rtype: int
    """
    if alignment_provided is not None:
        if alignment_provided > default_alignment:
            raise Exception(f"Alignment {alignment_provided} exceeds the maximum supported of {default_alignment}.")
        return alignment_provided

    return default_alignment
