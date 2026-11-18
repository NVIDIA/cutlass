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

"""Reduction strategy for the data-parallel (``split_k == 1``) case.

Each output tile is produced in full by one work unit, so there are no partial
results to combine. ``fixup`` is a no-op, ``split_work_tile`` passes the work
tile through unchanged, and both workspace sizes are 0 bytes.
"""

from dataclasses import dataclass

import cutlass.cute as cute
from cutlass.cutlass_dsl import dsl_user_op
from cutlass.kernels.utils.tile_scheduler.base import BaseReductionStrategy
from cutlass.kernels.utils.tile_scheduler.params import (
    TileSchedulerRuntimeParams,
    TileSchedulerTemplateParams,
)
from cutlass.kernels.utils.tile_scheduler.tile_scheduler import WorkTileInfo


@dataclass(frozen=True)
class NoReductionStrategy(BaseReductionStrategy):
    """Reduction strategy for the data-parallel (no-split) case.

    When every output tile is computed in full by a single work unit
    (``split_k == 1``), there are no partial accumulators to combine:
    the accumulator handed to the epilogue is already the final result.
    Therefore ``fixup`` is a no-op, and the strategy needs neither GMEM nor
    SMEM workspace.

    The strategy is stateless (its only field, ``template_params``, is
    compile-time config), so it is a frozen dataclass and needs no extract/new
    protocol.
    """

    template_params: TileSchedulerTemplateParams

    @staticmethod
    def create(
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
    ) -> "NoReductionStrategy":
        """Build a strategy from the template params; runtime params are unused.

        Args:
            template_params (TileSchedulerTemplateParams): Compile-time scheduler
                config carried by the strategy.
            runtime_params (TileSchedulerRuntimeParams): Runtime scheduler params;
                ignored because the no-reduction case derives no state and needs no
                workspace.

        Returns:
            NoReductionStrategy: A stateless strategy wrapping ``template_params``.
        """
        # Nothing to derive; runtime_params (and any workspace pointers) are unused.
        return NoReductionStrategy(template_params)

    @dsl_user_op
    def split_work_tile(
        self, next_work_tile_info: WorkTileInfo, *, loc=None, ip=None
    ) -> WorkTileInfo:
        """No-op for the no-reduction strategy: returns the work tile unchanged."""
        return next_work_tile_info

    @staticmethod
    def get_smem_workspace_size(template_params: TileSchedulerTemplateParams) -> int:
        """0: the no-reduction strategy needs no workspace."""
        return 0

    @staticmethod
    def get_gmem_workspace_size(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnkl: cute.Shape,
    ) -> int:
        """0: the no-reduction strategy needs no workspace."""
        return 0

    @staticmethod
    def initialize_workspace(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnl: cute.Shape,
        host_workspace,
    ) -> None:
        """No-op for the no-reduction strategy: no workspace to populate."""
