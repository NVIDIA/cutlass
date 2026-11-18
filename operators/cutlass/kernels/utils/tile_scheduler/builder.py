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

"""Host-side selection and assembly of tile-scheduler strategy classes.

Everything here is untraced host-side Python -- it emits no IR, so it may
also run while a kernel is being traced (e.g. the kernels' template refresh
in ``_setup_attributes``): given a fully-populated
:class:`TileSchedulerTemplateParams`, the ``select_*`` helpers pick concrete
work / reduction / rasterization strategy *classes* (not instances), and
:func:`build_tile_scheduler_template` packages them into a
:class:`TileSchedulerTemplate`. The template is later instantiated at runtime
via ``TileScheduler.create`` inside a traced kernel.
"""

from cutlass.kernels.utils.tile_scheduler.params import TileSchedulerTemplateParams
from cutlass.kernels.utils.tile_scheduler.rasterization_strategies import (
    AffineRasterizationStrategy,
    NoRasterizationStrategy,
)
from cutlass.kernels.utils.tile_scheduler.reduction_strategies import (
    ClusterSplitKReductionStrategy,
    NoReductionStrategy,
    SplitKReductionStrategy,
)
from cutlass.kernels.utils.tile_scheduler.tile_scheduler import TileSchedulerTemplate
from cutlass.kernels.utils.tile_scheduler.work_strategies import (
    ClcDynamicPersistentWorkStrategy,
    GridWorkStrategy,
    StaticPersistentWorkStrategy,
)

_WORK_STRATEGIES = {
    "grid": GridWorkStrategy,
    "static": StaticPersistentWorkStrategy,
    "clc": ClcDynamicPersistentWorkStrategy,
}
_RASTERIZATION_STRATEGIES = {
    "none": NoRasterizationStrategy,
    "affine": AffineRasterizationStrategy,
}
_REDUCTION_STRATEGIES = {
    "none": NoReductionStrategy,
    "gmem-splitk": SplitKReductionStrategy,
    "cluster-splitk": ClusterSplitKReductionStrategy,
}


def select_work_strategy(work_strategy: str):
    """Pick the work-strategy class named by ``work_strategy``.

    ``'clc'`` uses CLC-driven dynamic persistent scheduling, ``'static'`` uses a
    fixed persistent grid, and ``'grid'`` maps one tile per CTA.

    :param work_strategy: One of ``'grid'``, ``'static'``, ``'clc'``.
    :type work_strategy: str
    :return: The selected work-strategy class (not an instance).
    """
    return _WORK_STRATEGIES[work_strategy]


def select_reduction_strategy(reduction_strategy: str):
    """Pick the reduction-strategy class named by ``reduction_strategy``.

    ``'none'`` selects :class:`NoReductionStrategy`, ``'gmem-splitk'`` selects
    :class:`SplitKReductionStrategy` (two-kernel GMEM split-K), and
    ``'cluster-splitk'`` selects :class:`ClusterSplitKReductionStrategy`
    (in-kernel DSMEM split-K).

    :param reduction_strategy: One of ``'none'``, ``'gmem-splitk'``,
        ``'cluster-splitk'``.
    :type reduction_strategy: str
    :return: The selected reduction-strategy class (not an instance).
    """
    return _REDUCTION_STRATEGIES[reduction_strategy]


def select_rasterization_strategy(rasterization_strategy: str):
    """Pick the rasterization-strategy class named by ``rasterization_strategy``.

    ``'none'`` selects :class:`NoRasterizationStrategy`, the identity rasterizer
    (the work strategy already returns this CTA's own per-CTA tile coordinate, so
    it is wrapped unchanged; the work strategy also emits a grid proportional to
    the tile shape for it). ``'affine'`` selects
    :class:`AffineRasterizationStrategy`, the decoding rasterizer that maps the
    cluster-linear grid through the runtime swizzle / raster reorder.

    :param rasterization_strategy: One of ``'none'``, ``'affine'``.
    :type rasterization_strategy: str
    :return: The rasterization-strategy class (not an instance).
    """
    return _RASTERIZATION_STRATEGIES[rasterization_strategy]


def build_tile_scheduler_template(params: TileSchedulerTemplateParams):
    """Select all strategy classes and assemble a :class:`TileSchedulerTemplate`.

    Runs entirely on the host before JIT tracing. The returned template bundles
    the static params with the chosen work / reduction / rasterization strategy
    classes; instances are created later at runtime via ``TileScheduler.create``.

    :param params: Fully-populated static template parameters.
    :type params: TileSchedulerTemplateParams
    :return: The assembled tile-scheduler template.
    :rtype: TileSchedulerTemplate
    """
    return TileSchedulerTemplate(
        params,
        select_work_strategy(params.work_strategy),
        select_reduction_strategy(params.reduction_strategy),
        select_rasterization_strategy(params.rasterization_strategy),
    )
