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

from __future__ import annotations

import warnings
from typing import TYPE_CHECKING

import cutlass.utils as utils

if TYPE_CHECKING:
    from cutlass.operators.utils.layout import TupleRank2Or3


def query_max_active_clusters(cluster_shape: TupleRank2Or3, device_id: int = 0) -> int:
    """Ask a device how many clusters of ``cluster_shape`` fit.

    Args:
        cluster_shape (TupleRank2Or3): M and N extents determine the size.
        device_id (int): ID of the CUDA device to query. Occupancy is computed
            for the context current on the calling thread, so this must name
            that context's device.

    Returns:
        int: Maximum number of concurrently resident clusters.
    """
    return utils.HardwareInfo(device_id).get_max_active_clusters(
        cluster_shape[0] * cluster_shape[1]
    )


def get_max_active_clusters(cluster_shape: TupleRank2Or3) -> int:
    """Return how many clusters of ``cluster_shape`` fit on the current GPU.

    .. deprecated::
        Use :meth:`DeviceProperties.max_active_clusters`, which also honours a
        caller-supplied override. This function will be removed.

    Args:
        cluster_shape (TupleRank2Or3): M and N extents determine the size.

    Returns:
        int: Maximum number of concurrently resident clusters.
    """
    warnings.warn(
        "get_max_active_clusters is deprecated; use "
        "DeviceProperties().max_active_clusters(cluster_shape) instead.",
        DeprecationWarning,
        stacklevel=2,
    )
    return query_max_active_clusters(cluster_shape)


class DeviceProperties:
    """Properties of one GPU, queried on demand.

    Values come from the device named by :attr:`device_id` and are cached for
    the instance's lifetime. Querying needs a live device, so use only from an
    operator's ``_run``, never ``_compile`` -- compilation stays device-free so
    it works without a GPU and yields artifacts not tied to one device's SM
    count.

    .. note::
        Queries answer for the CUDA context that is current on the calling
        thread, and nothing here checks that it belongs to :attr:`device_id`.
        Callers must make a context on :attr:`device_id` current before
        querying, and keep one instance per context.

    Operators never select a device: :meth:`Operator.run` defaults to device 0.
    """

    def __init__(self, device_id: int = 0) -> None:
        if device_id < 0:
            raise ValueError(f"device_id must not be negative, got {device_id}")
        self._device_id = device_id
        self._max_active_clusters: dict[int, int] = {}

    def __repr__(self) -> str:
        """Return the device and the values queried for it so far."""
        return (
            f"{type(self).__name__}(device_id={self._device_id}, "
            f"max_active_clusters={self._max_active_clusters})"
        )

    @property
    def device_id(self) -> int:
        """The ID of the CUDA device that these properties describe."""
        return self._device_id

    def max_active_clusters(self, cluster_shape: TupleRank2Or3) -> int:
        """Return how many clusters of ``cluster_shape`` can be resident at once.

        Args:
            cluster_shape (TupleRank2Or3): Cluster shape, of which the M and N
                extents determine the cluster size.

        Returns:
            int: Maximum number of concurrently resident clusters.
        """
        cluster_size = cluster_shape[0] * cluster_shape[1]
        if cluster_size not in self._max_active_clusters:
            self._max_active_clusters[cluster_size] = query_max_active_clusters(
                cluster_shape, self._device_id
            )
        return self._max_active_clusters[cluster_size]


_default_device_properties: dict[int, DeviceProperties] = {}


def get_default_device_properties(device_id: int = 0) -> DeviceProperties:
    """Return shared :class:`DeviceProperties` for ``device_id``.

    Operators call this so that a value is queried once per device instead of
    once per launch -- an occupancy query compiles a kernel. The instance is
    never discarded, so callers that replace the CUDA context must pass their
    own.

    Args:
        device_id (int): ID of the CUDA device to describe.

    Returns:
        DeviceProperties: Instance shared by every caller for ``device_id``.

    Raises:
        ValueError: If ``device_id`` is negative. An ID past the last device is
            only rejected once a value is queried, which needs a device count.
    """
    if device_id not in _default_device_properties:
        _default_device_properties[device_id] = DeviceProperties(device_id)
    return _default_device_properties[device_id]
