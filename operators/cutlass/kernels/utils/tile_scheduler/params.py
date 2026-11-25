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

"""Parameter containers for the persistent tile scheduler.

Three records live here:

* :class:`TileSchedulerTemplateParams` -- host-side, non-JIT compile-time parameters
  that select which scheduler implementation is dispatched.
* :class:`TileSchedulerRuntimeParams` -- a transient JIT container that carries
  workspace pointers, problem shapes, and the runtime-tunable swizzle / raster
  settings into the ``create()`` functions.
* :class:`TileSchedulerPrecomputedParams` -- grid-invariant values prepared by the
  host launcher and transported to the device without recomputation.
"""

from dataclasses import dataclass
from typing import Literal

import cutlass.cute as cute
from cutlass import Float32, Int8, Int32, testing
from cutlass.cutlass_dsl import Boolean


@dataclass(frozen=True)
class TileSchedulerTemplateParams:
    """Host-side, non-JIT compile-time parameters selecting the scheduler dispatch.

    Retracing occurs for every new combination of these values; the scheduler
    class composition is chosen from them. All compile-time / specialization
    parameters live here. Runtime-tunable settings -- the swizzle size and the
    rasterization order -- deliberately do **not** live here: they flow through
    :class:`TileSchedulerRuntimeParams` so changing them does not force a
    retrace (see :attr:`TileSchedulerRuntimeParams.swizzle_size` and
    ``raster_along_m``).

    :ivar acc_dtype: Element type of the GMEM split-K partial-accumulator
        workspace (the kernel's accumulation precision, not the user's C
        dtype). Sizes the workspace and types kernel 1's partial stores; the
        reduction kernel casts to the user's C dtype when storing the final
        output.
    :ivar work_strategy: Which work strategy to dispatch: ``'grid'`` launches
        one tile per CTA (non-persistent); ``'static'`` uses a fixed persistent
        grid with the work index assigned once from the block/cluster id;
        ``'clc'`` uses CLC-driven dynamic persistent scheduling (work fetched from
        the hardware cluster-launch-control counter).
    :ivar rasterization_strategy: Which rasterization strategy: ``'none'``
        is the identity rasterizer (the work strategy already hands back this
        CTA's own tile coordinate, so it is wrapped unchanged; requires a
        per-CTA-coordinate work strategy -- ``'grid'`` or ``'clc'``), and
        ``'affine'`` decodes a cluster-linear index, honoring the runtime
        swizzle size and rasterization order.
    :ivar reduction_strategy: Which reduction strategy: ``'none'`` (no
        split-K), ``'gmem-splitk'`` (two-kernel GMEM split-K -- each split's
        partials go to a GMEM workspace and are summed by a second kernel,
        partitioning K into equal-sized ranges), or ``'cluster-splitk'``
        (in-kernel DSMEM cluster split-K -- splits co-located along cluster-Z
        and reduced via DSMEM). Future variants (e.g. deterministic split-K)
        extend this literal rather than adding new flags.
    :ivar num_scheduler_stages: Pipeline depth of the scheduler's work fetch.
    :ivar cluster_shape_mn: Preferred cluster extent in (M, N); the physical
        cluster-Z is derived from the split-K variant (see :attr:`cluster_shape`).
    :ivar split_k: Number of partitions of the work iteration space (the split
        count). Must be > 1 exactly when a split-K reduction strategy is
        selected.
    :ivar cta_tile_shape_mnk: CTA tile (M, N, K), set by the kernel.
    :ivar fallback_cluster_shape_mn: Fallback cluster extent in (M, N) for mixed
        cluster; defaults to ``cluster_shape_mn`` (no fallback). ``cluster_shape_mn``
        must be a multiple of it.

    All fields except ``fallback_cluster_shape_mn`` are required (no defaults):
    construction raises if any is missing.
    """

    acc_dtype: type[Float32]
    work_strategy: Literal["grid", "static", "clc"]
    rasterization_strategy: Literal["none", "affine"]
    reduction_strategy: Literal["none", "gmem-splitk", "cluster-splitk"]
    num_scheduler_stages: int
    cluster_shape_mn: tuple[int, int]
    split_k: int
    cta_tile_shape_mnk: tuple[int, int, int]
    fallback_cluster_shape_mn: tuple[int, int] | None = None

    @property
    def cluster_shape(self):
        """Physical launch cluster (M, N, Z).

        Cluster split-K co-locates the splits along cluster-Z (they reduce
        via DSMEM), so Z = ``split_k``; every other mode -- including
        two-kernel (GMEM) split-K, whose splits are independent waves reduced
        by a second kernel -- keeps Z = 1. Mirrors the cluster the kernel
        actually launches.
        """
        return (*self.cluster_shape_mn, self.split_k if self.is_cluster_splitk else 1)

    @property
    def fallback_cluster_shape(self):
        """Fallback physical launch cluster (M, N, Z).

        Mirrors :attr:`cluster_shape` for the fallback (M, N) extent; the Z
        extent is derived from the split-K variant identically.
        """
        return (
            *self.fallback_cluster_shape_mn,
            self.split_k if self.is_cluster_splitk else 1,
        )

    @property
    def is_cluster_splitk(self):
        """Return True when cluster (in-kernel DSMEM) split-K is active."""
        return self.reduction_strategy == "cluster-splitk"

    @property
    def is_gmem_splitk(self):
        """Return True when two-kernel (GMEM) split-K is active."""
        return self.reduction_strategy == "gmem-splitk"

    @property
    def is_splitk(self):
        """Return True when any split-K variant is active."""
        return self.split_k > 1

    def gmem_output_type(self, c_dtype):
        """Return the element type kernel 1 stores to its GMEM output.

        For two-kernel (GMEM) split-K, kernel 1 stores full-precision partials
        to the workspace, so the store dtype is ``acc_dtype``; the reduction
        kernel later casts to the user's C dtype. Every other mode stores the
        user's C directly in ``c_dtype``.

        :param c_dtype: the user's C element type
        :return: the dtype of the tensor kernel 1 stores
        """
        return self.acc_dtype if self.is_gmem_splitk else c_dtype

    def __post_init__(self):
        """Validate the compile-time parameters and default the fallback cluster."""

        def _validate_cluster_shape(cluster_shape_mn: tuple[int, int]):
            if len(cluster_shape_mn) != 2:
                raise ValueError(
                    f"`cluster_shape_mn` takes only the (M, N) cluster extents, got "
                    f"{cluster_shape_mn}; the physical cluster-Z is derived "
                    "from the split-K variant (see `cluster_shape`)"
                )
            if any(d <= 0 for d in cluster_shape_mn):
                raise ValueError(
                    f"`cluster_shape_mn` dims must be positive, got {cluster_shape_mn}"
                )

        _validate_cluster_shape(self.cluster_shape_mn)

        if self.fallback_cluster_shape_mn is None:
            object.__setattr__(self, "fallback_cluster_shape_mn", self.cluster_shape_mn)
        else:
            if any(
                pf % fb != 0
                for pf, fb in zip(self.cluster_shape_mn, self.fallback_cluster_shape_mn)
            ):
                raise ValueError(
                    f"`cluster_shape_mn` must be a multiple of `fallback_cluster_shape_mn`, "
                    f"got {self.cluster_shape_mn} and {self.fallback_cluster_shape_mn}"
                )
            _validate_cluster_shape(self.fallback_cluster_shape_mn)

        if self.work_strategy not in ("grid", "static", "clc"):
            raise ValueError(
                f"`work_strategy` must be 'grid', 'static', or 'clc', got "
                f"{self.work_strategy!r}"
            )
        if self.rasterization_strategy not in ("none", "affine"):
            raise ValueError(
                f"`rasterization_strategy` must be 'none' or 'affine', got "
                f"{self.rasterization_strategy!r}"
            )
        if self.reduction_strategy not in (
            "none",
            "gmem-splitk",
            "cluster-splitk",
        ):
            raise ValueError(
                f"`reduction_strategy` must be 'none', 'gmem-splitk', or "
                f"'cluster-splitk', got {self.reduction_strategy!r}"
            )

        if self.num_scheduler_stages < 1:
            raise ValueError(
                f"`num_scheduler_stages` must be >= 1, got {self.num_scheduler_stages}"
            )
        if self.split_k < 1:
            raise ValueError(f"`split_k` must be >= 1, got {self.split_k}")
        if any(d <= 0 for d in self.cta_tile_shape_mnk):
            raise ValueError(
                f"`cta_tile_shape_mnk` dims must be positive, got {self.cta_tile_shape_mnk}"
            )
        if (self.split_k > 1) != (self.reduction_strategy != "none"):
            raise ValueError(
                "`reduction_strategy` must be 'none' iff `split_k` == 1, got "
                f"split_k={self.split_k}, "
                f"reduction_strategy={self.reduction_strategy!r}"
            )
        if self.rasterization_strategy == "none" and self.work_strategy == "static":
            raise ValueError(
                "`rasterization_strategy` 'none' requires a 'grid' or 'clc' "
                "work strategy; the 'static' work strategy emits a CTA-linear "
                "index that must be decoded by the 'affine' rasterization strategy"
            )

    def check_precompute_support(self) -> None:
        """Reject schedules that cannot prepare or consume host scheduler state.

        :raises testing.CantImplementError: If the schedule is not
            static/affine/no-reduction.
        """
        if (
            self.work_strategy != "static"
            or self.rasterization_strategy != "affine"
            or self.reduction_strategy != "none"
        ):
            raise testing.CantImplementError(
                "scheduler parameter precomputation requires static/affine/none"
            )


@dataclass(eq=False)
class TileSchedulerPrecomputedParams:
    """Carry dynamic, grid-invariant values prepared by the host launcher.

    The DSL's dataclass adapter transports this record to the device. See
    ``TileSchedulerTemplate.prepare_sched_params`` for the launch contract.

    :ivar swizzled_problem_layout_ncluster_mnl: Preferred logical cluster layout,
        shared by preferred and fallback physical clusters.
    :ivar k_tile_cnt: Full K extent in MMA tiles, rounded up on the host.
    :ivar cluster_shape_major_fdd: Major-axis divisor.
    :ivar cluster_shape_minor_fdd: Minor-axis divisor for the unswizzled fast path.
    """

    swizzled_problem_layout_ncluster_mnl: cute.Layout
    k_tile_cnt: Int32
    cluster_shape_major_fdd: cute.FastDivmodDivisor
    cluster_shape_minor_fdd: cute.FastDivmodDivisor


@dataclass(eq=False)
class TileSchedulerRuntimeParams:
    """Transient JIT container for the scheduler's runtime values.

    Instantiated on host or device inside a JIT function.

    ``precomputed_sched_params`` optionally supplies a
    :class:`TileSchedulerPrecomputedParams` record prepared for this launch.
    """

    # Workspace
    smem_workspace_ptr: cute.Pointer
    gmem_workspace_ptr: cute.Pointer

    work_smem_workspace_ptr: cute.Pointer
    work_gmem_workspace_ptr: cute.Pointer

    reduction_smem_workspace_ptr: cute.Pointer
    reduction_gmem_workspace_ptr: cute.Pointer

    rasterization_smem_workspace_ptr: cute.Pointer
    rasterization_gmem_workspace_ptr: cute.Pointer

    k_tile_cnt: Int32

    swizzle_size: Int32
    raster_along_m: Boolean

    problem_shape_mnl: cute.Shape
    swizzled_problem_layout_ncluster_mnl: cute.Layout
    precomputed_sched_params: TileSchedulerPrecomputedParams | None

    def __init__(
        self,
        smem_workspace_ptr: cute.Pointer,
        gmem_workspace_ptr: cute.Pointer,
        problem_shape_mnl: cute.Shape,
        k_tile_cnt: Int32,
        swizzle_size: Int32,
        raster_along_m: Boolean,
        template_params: TileSchedulerTemplateParams,
        precomputed_sched_params: TileSchedulerPrecomputedParams | None = None,
    ):
        """Record workspace pointers, the problem shape, and the swizzle / raster settings (phase one).

        Auxiliary workspace pointers default to null. ``TileScheduler.create``
        supplies the layout, reusing ``precomputed_sched_params`` when present.

        ``swizzle_size`` (tiles per swizzle group; 1 disables swizzling) and
        ``raster_along_m`` (True rasterizes M-major, False N-major) are the
        runtime settings; they are stored as-supplied so the caller may pass either
        a compile-time constant or a dynamic value.

        """
        self.smem_workspace_ptr = smem_workspace_ptr
        self.gmem_workspace_ptr = gmem_workspace_ptr

        self.work_smem_workspace_ptr = cute.runtime.nullptr(Int8)
        self.work_gmem_workspace_ptr = cute.runtime.nullptr(Int8)

        self.reduction_smem_workspace_ptr = cute.runtime.nullptr(Int8)
        self.reduction_gmem_workspace_ptr = cute.runtime.nullptr(Int8)

        self.rasterization_smem_workspace_ptr = cute.runtime.nullptr(Int8)
        self.rasterization_gmem_workspace_ptr = cute.runtime.nullptr(Int8)

        if template_params.is_gmem_splitk:
            m, n, expanded_l = problem_shape_mnl
            problem_shape_mnl = (m, n, expanded_l // template_params.split_k)
        self.problem_shape_mnl = problem_shape_mnl
        self.k_tile_cnt = k_tile_cnt

        self.swizzle_size = swizzle_size
        self.raster_along_m = raster_along_m

        self.swizzled_problem_layout_ncluster_mnl = None
        self.precomputed_sched_params = precomputed_sched_params
