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

import math

import cutlass
import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass.cutlass_dsl import (
    Int32,
    dsl_user_op,
    extract_mlir_values,
    new_from_mlir_values,
)
from cutlass.kernels.utils.tile_scheduler.base import BaseReductionStrategy
from cutlass.kernels.utils.tile_scheduler.params import (
    TileSchedulerRuntimeParams,
    TileSchedulerTemplateParams,
)
from cutlass.kernels.utils.tile_scheduler.tile_scheduler import WorkTileInfo


def ceil_div(a: int, b: int) -> int:
    """Return the ceiling of ``a / b`` for non-negative integers."""
    return (a + b - 1) // b


class SplitKReductionStrategy(BaseReductionStrategy):
    """Out-of-kernel (GMEM two-kernel) split-K reduction strategy.

    Each output tile is split across ``split_k`` work units along K. Kernel 1
    computes each split's partial accumulator and writes it to its own L slot
    of a GMEM workspace (sized by :meth:`get_gmem_workspace_size`); a second
    reduction kernel then sums the ``split_k`` partials into the user's C.
    In-kernel :meth:`pre_fixup` / :meth:`fixup_and_epilogue` are therefore
    no-ops here: :meth:`split_work_tile` only de-expands the scheduler's
    split-expanded L index into the real ``(M, N, L)`` tile plus this split's
    accumulator slot and ``[k_start, k_end)`` K-tile range.
    """

    @dsl_user_op
    def __init__(
        self,
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
        split_k_fdd: cute.FastDivmodDivisor,
        k_tiles_base: Int32,
        k_tiles_rem: Int32,
        *,
        loc=None,
        ip=None,
    ):
        self.template_params = template_params
        self.runtime_params = runtime_params
        self.split_k_fdd = split_k_fdd
        self.k_tiles_base = k_tiles_base
        self.k_tiles_rem = k_tiles_rem

        self._loc = loc

    @staticmethod
    @cute.jit
    def create(
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
        *,
        loc=None,
        ip=None,
    ) -> "SplitKReductionStrategy":
        """Build a strategy for the calling CTA.

        Precomputes the per-work-tile invariants once instead of per fetch: the
        FastDivmod divisor for the ``split_k`` de-expansion in
        :meth:`split_work_tile`, and the balanced per-split K-tile counts
        (base count plus the remainder spread over the leading splits).

        :param template_params: scheduler template parameters (split_k, tile/cluster shape)
        :param runtime_params: runtime parameters (k_tile_cnt, workspace pointers)
        :return: a strategy bound to the given parameters
        :rtype: SplitKReductionStrategy
        """
        split_k_fdd = cute.fast_divmod_create_divisor(
            template_params.split_k, loc=loc, ip=ip
        )
        k_tiles_base = runtime_params.k_tile_cnt // template_params.split_k
        k_tiles_rem = runtime_params.k_tile_cnt % template_params.split_k
        return SplitKReductionStrategy(
            template_params,
            runtime_params,
            split_k_fdd,
            k_tiles_base,
            k_tiles_rem,
        )

    @dsl_user_op
    def pre_fixup(self):
        """No-op: the GMEM split-K reduction runs in a separate kernel."""

    @dsl_user_op
    @cute.jit
    def fixup_and_epilogue(self):
        """No-op: the GMEM split-K reduction runs in a separate kernel."""

    @dsl_user_op
    def split_k_equally(self, next_work_tile_info, *, loc=None, ip=None):
        """Split the K-tile range as evenly as possible across the splits.

        The first ``k_tile_cnt % split_k`` splits take one extra K-tile. When
        ``split_k`` exceeds the K-tile count the trailing splits are empty
        (``k_start == k_end == k_tile_cnt``) and the reduction kernel skips
        their uninitialized slots.

        :param next_work_tile_info: work tile with the split-expanded tile index
        :return: ``(new_tile_idx, acc_l_idx, k_start, k_end)`` -- the
            de-expanded ``(M, N, L)`` tile index, the split-expanded
            (accumulator slot) L index, and this split's K-tile range
        :rtype: tuple
        """
        acc_l_idx = next_work_tile_info.tile_idx[2]
        # One fast-divmod (magic-number multiply/shift, precomputed in create())
        # yields both the de-expanded batch index and this split's rank.
        ab_l_idx, split_idx = divmod(next_work_tile_info.tile_idx[2], self.split_k_fdd)

        # Every split gets base = k_tile_cnt // split_k tiles, and the first
        # rem = k_tile_cnt % split_k splits take one extra. min(i, rem) is how
        # many extras were handed out before split i, so split i starts at
        # i * base + min(i, rem) and ends where split i + 1 starts.
        # E.g. 6 tiles, split_k=4: base=1, rem=2 -> starts 0,2,4,5 -> sizes 2,2,1,1.
        next_split_idx = split_idx + 1
        k_start = self.k_tiles_base * split_idx + cute.min(split_idx, self.k_tiles_rem)
        k_end = self.k_tiles_base * next_split_idx + cute.min(
            next_split_idx, self.k_tiles_rem
        )

        new_tile_idx = (
            next_work_tile_info.tile_idx[0],
            next_work_tile_info.tile_idx[1],
            ab_l_idx,
        )

        return new_tile_idx, acc_l_idx, k_start, k_end

    @dsl_user_op
    def split_work_tile(self, next_work_tile_info: WorkTileInfo, *, loc=None, ip=None):
        """Map a split-expanded work tile back to its real output tile + K-range.

        The scheduler expands the L dimension by ``split_k`` (see
        :func:`get_problem_shape_ntile`), so the incoming L index addresses a
        (tile, split) pair. This divides it out to recover the real L tile index
        and attaches the split's accumulator slot (``acc_l_idx``) and
        ``[k_start, k_end)`` K-range.

        :param next_work_tile_info: work tile with the split-expanded tile index
        :return: a work tile with the de-expanded ``(M, N, L)`` index, the
            split's ``acc_l_idx``, and its ``k_start`` / ``k_end``
        :rtype: WorkTileInfo
        """
        if cutlass.const_expr(self.template_params.reduction_strategy == "gmem-splitk"):
            new_tile_idx, acc_l_idx, k_start, k_end = self.split_k_equally(
                next_work_tile_info
            )
        else:
            raise ValueError(
                "Received invalid reduction strategy type: "
                f"{self.template_params.reduction_strategy}"
            )

        return WorkTileInfo(
            new_tile_idx,
            next_work_tile_info.is_valid_tile,
            acc_l_idx=acc_l_idx,
            k_start=k_start,
            k_end=k_end,
        )

    @staticmethod
    def can_implement(
        template_params, problem_shape_mnkl, swizzle_size, raster_along
    ) -> bool:
        """Reject unlaunchable shapes.

        Splits beyond the K-tile count are allowed: they are empty, and the
        reduction kernel skips their slots. The reduction kernel folds its ``(m_tiles, n_tiles, L)`` tile counts
        onto ``grid.x`` (see
        :func:`splitk_reduction_impl.get_reduction_grid_block`), which bounds
        ``grid.x``; the split-expanded L index space (``L * split_k``) is
        bounded as well. The GEMM kernel's own launch grid is bounded by the work
        strategy's ``can_implement``.

        :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
        :param swizzle_size: tiles per swizzle group (unused here)
        :param raster_along: one of :data:`RASTERIZATION_ORDERS` (unused here)
        """
        m, n, _, prob_l = problem_shape_mnkl
        if ceil_div(m, 32) * ceil_div(n, 32) * prob_l > 2**31 - 1:
            return False
        return prob_l * template_params.split_k <= 2**31 - 1

    @staticmethod
    def get_smem_workspace_size(template_params: TileSchedulerTemplateParams) -> int:
        """SMEM workspace required, in bytes: 0.

        The reduction happens in a separate kernel through the GMEM workspace,
        so no SMEM mailbox is needed.

        :param template_params: scheduler template parameters (CTA tile shape, split_k)
        :return: SMEM workspace size in bytes (always 0)
        :rtype: int
        """
        return 0

    @staticmethod
    def get_gmem_workspace_size(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnl: cute.Shape,
    ) -> int:
        """GMEM workspace required, in bytes.

        Holds the split-K partial accumulators: ``split_k`` copies of the full
        ``(M, N, L)`` output in ``acc_dtype`` (full accumulation precision, so
        partials are not round-tripped through a narrower C dtype). Kernel 1
        writes each split's partial to its own L slot; kernel 2 reduces them
        into the user's C, casting to the C dtype at the final store.

        :param template_params: scheduler template parameters
        :param problem_shape_mnl: problem extents (M, N, L) in elements
        :return: GMEM workspace size in bytes
        :rtype: int
        """
        num_bytes = (
            math.prod(problem_shape_mnl)
            * template_params.split_k
            * template_params.acc_dtype.width
            // 8
        )
        # Round up to a 16B multiple so the following strategy's slice -- and
        # thus every workspace partition offset -- stays 16-byte aligned.
        return ceil_div(num_bytes, 16) * 16

    @staticmethod
    def initialize_workspace(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnl: cute.Shape,
        host_workspace,
    ) -> None:
        """No host-side initialization for the partial-accumulator workspace.

        The GEMM (kernel 1) stores a partial to every ``(m, n, acc_l)`` slot
        the reduction (kernel 2) reads -- kernel 2 skips the slots of empty
        splits (``split_k`` > K-tiles), which kernel 1 wrote but never
        initialized -- so the workspace never needs a zero-fill.

        :param template_params: scheduler template parameters
        :param problem_shape_mnl: problem extents (M, N, L) in elements
        :param host_workspace: 1-D int8 host staging buffer (untouched)
        """

    def __extract_mlir_values__(self) -> list[ir.Value]:
        # Carry the precomputed split-K invariants across the persistent loop
        # (order must match the constructor's positional arguments).
        values, self._values_pos = [], []
        for obj in [self.split_k_fdd, self.k_tiles_base, self.k_tiles_rem]:
            obj_values = extract_mlir_values(obj)
            values += obj_values
            self._values_pos.append(len(obj_values))
        return values

    def __new_from_mlir_values__(
        self, values: list[ir.Value]
    ) -> "SplitKReductionStrategy":
        # template_params is compile-time config, re-supplied as-is.
        obj_list, values_copy = [], list(values)
        for obj, n_items in zip(
            [self.split_k_fdd, self.k_tiles_base, self.k_tiles_rem], self._values_pos
        ):
            obj_list.append(new_from_mlir_values(obj, values_copy[:n_items]))
            values_copy = values_copy[n_items:]
        return SplitKReductionStrategy(
            self.template_params, self.runtime_params, *(tuple(obj_list)), loc=self._loc
        )
