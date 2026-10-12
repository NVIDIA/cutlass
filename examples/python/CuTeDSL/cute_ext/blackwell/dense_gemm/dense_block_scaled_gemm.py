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
import os
import sys
from typing import Optional, Tuple, Type
from dataclasses import dataclass

import torch

import cutlass
import cutlass.cute as cute
import cutlass.torch as cutlass_torch
from cutlass import (
    cute as cute,
    utils as utils,
)
from cutlass.cute import experimental as cute_ext
from cutlass import testing
from cutlass.cute.nvgpu import tcgen05
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils
from cutlass.cute.runtime import from_dlpack
from cutlass.utils.gemm.tensor_utils import (
    get_gemm_tensors,
    create_scale_factor_tensor,
    decode_float4e2m1fn,
)

# Import TileSched from the wheel (cutlass.utils), not the local
# ``examples/helpers`` copy: the local helper does not yet carry the
# ``fallback_cluster_shape_mnk`` plumbing required for mixed-cluster.
if __name__ == "__main__":
    _current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(_current_dir, "../../../"))

from cutlass.utils import PersistentTileSchedulerParams, StaticPersistentTileScheduler
from helpers import cli_helper as cli


"""Dense block-scaled GEMM for Blackwell (sm100), implemented in Cutlass IR, featuring:

- pipelined design: TMA loads&stores, MMA, and epilogue run concurrently on separate warps and communicate via queues.
- persistence: a small fixed grid of long-lived CTAs loops the entire problem instead of launching one CTA per tile.
- 2-CTA: two peer CTAs cooperatively run a single MMA instruction that covers M=256 instead of M=128, with TMEM shared across the pair.
- clustering: ``cluster_shape_mn`` is the physical launch cluster. A 2-CTA
  MMA therefore requires at least a 2x1 cluster; larger shapes enable TMA
  multicast outside the MMA peer pair.

* ``BlockScaledDenseGemmKernel.__init__`` -- stores the kernel
  configuration and computes the constants derivable from it alone
  (cluster shape, MMA peer count, K-direction tile factor, ...).
* ``BlockScaledDenseGemmKernel.__call__`` -- the JIT entry point.
  Binds the operand tensors, derives the workload-dependent state
  (tiled MMA, pipeline depths, ...), configures the persistent
  tile scheduler, and launches the device kernel.
* ``BlockScaledDenseGemmKernel.can_implement`` -- validates that the
  requested kernel configuration is supported by the Hardware.
* ``run`` -- Validates the kernel config via ``can_implement``,
  allocates reference and device tensors, JIT-compiles and launches
  the kernel, and checks the output against the PyTorch reference.
* ``__main__`` -- the CLI front-end. Parses argv, checks for an
  available GPU, seeds the RNG, calls ``run``, and reports
  outcomes via process exit codes.
"""


class BlockScaledDenseGemmKernel:
    def __init__(
        self,
        mma_inst_mn: tuple[int, int],
        ab_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        cluster_shape_mn: Tuple[int, int] = (1, 1),
        max_active_clusters: Optional[int] = None,
        fallback_cluster_shape_mn: Optional[Tuple[int, int]] = None,
        max_active_fallback_clusters: Optional[int] = None,
        epilogue_op=lambda x: x,
        allow_accumulator_overlap: bool = True,
    ):
        self.ab_dtype = ab_dtype
        self.acc_dtype = acc_dtype
        self.sf_dtype = sf_dtype
        self.sf_vec_size = sf_vec_size
        # MMA atom shape
        self.mma_inst_shape_mn = mma_inst_mn

        # Enable 2-CTA iff mmaAtomM==256
        self.use_2cta_instrs = mma_inst_mn[0] == 256
        self.cta_group = (
            tcgen05.CtaGroup.TWO if self.use_2cta_instrs else tcgen05.CtaGroup.ONE
        )
        self.num_mma_ctas = 2 if self.use_2cta_instrs else 1

        # ``cluster_shape_mn`` is the physical launch cluster, including
        # the peer pair required by a 2-CTA MMA atom.
        self.cluster_shape_mn = cluster_shape_mn
        cluster_shape_mn_selfcast = (2, 1) if self.use_2cta_instrs else (1, 1)
        self.use_tma_multicast = cluster_shape_mn != cluster_shape_mn_selfcast

        # ``max_active_clusters`` sets the launch grid's cluster count.
        # Set to the device's capacity for actual persistence.
        # ``None`` falls back to one cluster per tile, collapsing the
        # persistent loop to a single iteration.
        self.max_active_clusters = max_active_clusters

        if fallback_cluster_shape_mn is None:
            self.fallback_cluster_shape_mn = self.cluster_shape_mn
            self.max_active_fallback_clusters = max_active_clusters
        else:
            # The N in (64, 192) codepath uses a raw-CuTe TMA atom for
            # SFB whose multicast factor is baked in at host time (see
            # the ``cluster_shape_to_tma_atom_SFB`` call in ``__call__``).
            # Mixed-cluster would need the multicast factor to vary at
            # runtime across the preferred/fallback branches, which the
            # static atom can't express. Reject the combination here so
            # the kernel constructor fails fast.
            if fallback_cluster_shape_mn != cluster_shape_mn and mma_inst_mn[1] in (
                64,
                192,
            ):
                raise testing.CantImplementError(
                    f"Mixed-cluster (fallback_cluster_shape_mn="
                    f"{fallback_cluster_shape_mn} != cluster_shape_mn="
                    f"{cluster_shape_mn}) is not supported with "
                    f"mma_inst_mn[1]={mma_inst_mn[1]}; the N in (64, 192) "
                    f"codepaths bake the SFB TMA multicast factor into "
                    f"a host-built atom. Use mma_inst_mn[1] in (128, 256), "
                    f"or run with a single cluster shape."
                )
            # Apply the same physical cluster-shape rules as the primary
            # shape (see can_implement).
            if fallback_cluster_shape_mn[0] not in (
                1,
                2,
                4,
            ) or fallback_cluster_shape_mn[1] not in (1, 2, 4):
                raise testing.CantImplementError(
                    f"fallback_cluster_shape_mn={fallback_cluster_shape_mn}: "
                    f"each dim must be in (1, 2, 4)."
                )
            if fallback_cluster_shape_mn[0] % self.num_mma_ctas != 0:
                raise testing.CantImplementError(
                    f"fallback_cluster_shape_mn={fallback_cluster_shape_mn}: "
                    f"cluster-M must be divisible by the MMA peer count "
                    f"{self.num_mma_ctas}."
                )
            fallback_cluster_size = (
                fallback_cluster_shape_mn[0] * fallback_cluster_shape_mn[1]
            )
            if fallback_cluster_size > 16:
                raise testing.CantImplementError(
                    f"fallback_cluster_shape_mn={fallback_cluster_shape_mn} "
                    f"contains {fallback_cluster_size} CTAs, exceeding the SM100 "
                    f"maximum of 16."
                )
            self.fallback_cluster_shape_mn = fallback_cluster_shape_mn
            self.max_active_fallback_clusters = (
                max_active_fallback_clusters
                if max_active_fallback_clusters is not None
                else max_active_clusters
            )

        self.epilogue_op = epilogue_op
        self.allow_accumulator_overlap = allow_accumulator_overlap
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes("sm_100")

        # Number of MMA instructions (along K) per SMEM stage.
        self.mma_inst_tile_k = 4

        # Workload-dependent attributes filled in by ``_setup_attributes``.
        self.tiled_mma = None
        self.mma_tiler_mnk = None
        self.cta_tile_shape_mnk = None
        self.epi_tile = None
        self.d_layout = None
        self.d_dtype = None

        # SFB scratch for the N in {64, 192} special cases; built
        # unconditionally but only consumed when
        # ``mma_inst_shape_mn[1] in (64, 192)``.
        self.mma_inst_shape_mn_sfb = None
        self.mma_tiler_sfb = None
        self.tiled_mma_sfb = None
        self.cluster_layout_sfb_vmnk = None

        # SMEM pipeline depths picked by ``_compute_stages``.
        # ``num_stages`` is the depth of the TMA-load pipeline and
        # sizes the A, B, SFA, and SFB SMEM buffers (one stage
        # carries all four for one K-block).
        self.num_stages = None
        self.tma_store_stages = None

    @staticmethod
    def can_implement(
        mnkl: Tuple[int, int, int, int],
        mma_inst_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        ab_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        d_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        d_major: str,
        compute_amax: bool,
    ) -> Optional[str]:
        """Validate a kernel configuration.

        Acts as a single source of truth for CLI and tests alike.
        Mixed-cluster restrictions (when ``fallback_cluster_shape_mn`` is
        provided) are checked separately by the kernel constructor so
        that this predicate's signature matches every test case's
        parametrized fields, including the ones that pre-date mixed-cluster.

        :return: ``None`` if supported, otherwise a human-readable
                reason string.
        """
        if a_major not in ("k", "m"):
            return (
                f"A major axis {a_major!r} not supported; expected one of ('k', 'm')."
            )
        if b_major not in ("k", "n"):
            return (
                f"B major axis {b_major!r} not supported; expected one of ('k', 'n')."
            )
        if d_major not in ("n", "m"):
            return (
                f"D major axis {d_major!r} not supported; expected one of ('n', 'm')."
            )
        if d_dtype not in (
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float32,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ):
            return (
                f"Output dtype {d_dtype} not supported; "
                f"expected one of (Float16, BFloat16, Float32, "
                f"Float8E4M3FN, Float8E5M2)."
            )

        m, n, k, _ = mnkl
        try:
            sm100_utils.check_gemm_tma_alignment(
                m,
                n,
                k,
                ab_dtype,
                ab_dtype,
                d_dtype,
                a_major,
                b_major,
                d_major,
                output_tensor_name="D",
            )
        except testing.CantImplementError as e:
            return str(e)

        if mma_inst_mn[0] not in (128, 256) or mma_inst_mn[1] not in (
            64,
            128,
            192,
            256,
        ):
            return (
                f"MMA instruction shape {mma_inst_mn} not supported; supported combos: "
                f"(128, 64), (128, 128), (128, 192), (128, 256), "
                f"(256, 64), (256, 128), (256, 192), (256, 256)."
            )
        if cluster_shape_mn[0] not in (1, 2, 4) or cluster_shape_mn[1] not in (
            1,
            2,
            4,
        ):
            return (
                f"Cluster shape {cluster_shape_mn[0]}x"
                f"{cluster_shape_mn[1]} not supported; must be one of "
                f"({1, 2, 4}^2)."
            )
        num_mma_ctas = 2 if mma_inst_mn[0] == 256 else 1
        if cluster_shape_mn[0] % num_mma_ctas != 0:
            return (
                f"Cluster shape {cluster_shape_mn[0]}x{cluster_shape_mn[1]} "
                f"is incompatible with mma_inst_m={mma_inst_mn[0]}; cluster-M "
                f"must be divisible by the MMA peer count {num_mma_ctas}."
            )
        cluster_size = cluster_shape_mn[0] * cluster_shape_mn[1]
        if cluster_size > 16:
            return (
                f"Cluster {cluster_shape_mn[0]}x{cluster_shape_mn[1]} contains "
                f"{cluster_size} CTAs, exceeding the SM100 maximum of 16."
            )
        if (ab_dtype, sf_dtype, sf_vec_size) not in (
            (cutlass.Float4E2M1FN, cutlass.Float8E4M3FN, 16),
            (cutlass.Float4E2M1FN, cutlass.Float8E8M0FNU, 16),
            (cutlass.Float4E2M1FN, cutlass.Float8E8M0FNU, 32),
            (cutlass.Float8E4M3FN, cutlass.Float8E8M0FNU, 32),
            (cutlass.Float8E5M2, cutlass.Float8E8M0FNU, 32),
        ):
            return (
                f"Unsupported (ab_dtype, sf_dtype, sf_vec_size) combination: "
                f"({ab_dtype}, {sf_dtype}, {sf_vec_size}); supported combos: "
                f"(Float4E2M1FN, Float8E4M3FN, 16), "
                f"(Float4E2M1FN, Float8E8M0FNU, 16), "
                f"(Float4E2M1FN, Float8E8M0FNU, 32), "
                f"(Float8E4M3FN, Float8E8M0FNU, 32), "
                f"(Float8E5M2, Float8E8M0FNU, 32)."
            )
        if ab_dtype is cutlass.Float4E2M1FN and not (
            a_major == b_major == "k" and d_major == "n"
        ):
            return (
                f"MMA (FP4 block-scaled, ab_dtype=Float4E2M1FN) requires "
                f"a_major='k', b_major='k', d_major='n'; got "
                f"a_major={a_major!r}, b_major={b_major!r}, d_major={d_major!r}."
            )
        if acc_dtype != cutlass.Float32:
            return (
                f"Accumulator dtype {acc_dtype} not supported; "
                f"only Float32 is currently implemented."
            )

        # TODO [dkb 7 May '26] currently not supported.
        # Not sure if HW limit or SW bug.
        if (
            mma_inst_mn == (256, 64)
            and cluster_shape_mn[0] == 4
            and ab_dtype in (cutlass.Float8E4M3FN, cutlass.Float8E5M2)
        ):
            return (
                f"Unsupported configuration: mma_inst_mn=(256, 64) with "
                f"cluster_shape_mn[0]=4 and 8-bit ab_dtype ({ab_dtype}) "
                f"hits a misaligned SFB TMA descriptor. "
                f"Workarounds: use mma_inst_mn=(128, 64), reduce "
                f"cluster_shape_mn[0] to <= 2, or use ab_dtype="
                f"Float4E2M1FN."
            )

        return None

    def _setup_attributes(self, mA: cute.Tensor, mB: cute.Tensor, mD: cute.Tensor):
        """Derive workload-dependent state from the bound operand tensors.

        Sets the tiled MMA, MMA/CTA tilers, epilogue tile, and pipeline
        depths (the latter via ``_compute_stages``).
        """
        a_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode()
        b_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(mB).mma_major_mode()

        self.d_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(mD)
        self.d_dtype = mD.element_type

        self.tiled_mma = sm100_utils.make_blockscaled_trivial_tiled_mma(
            self.ab_dtype,
            self.ab_dtype,
            a_major_mode,
            b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape_mn,
        )

        mma_inst_shape_k = cute.size(self.tiled_mma.shape_mnk, mode=[2])
        self.mma_tiler_mnk = (
            self.mma_inst_shape_mn[0],
            self.mma_inst_shape_mn[1],
            mma_inst_shape_k * self.mma_inst_tile_k,
        )

        num_mma_ctas = cute.size(self.tiled_mma.thr_id.shape)
        self.cta_tile_shape_mnk = (
            self.mma_tiler_mnk[0] // num_mma_ctas,
            self.mma_tiler_mnk[1],
            self.mma_tiler_mnk[2],
        )

        # SFB needs its own MMA tiler and cluster layout for two
        # reasons. (1) The SFB load granularity is 128 columns of N,
        # so for ``mma_inst_shape_mn[1] in (64, 192)`` the SFB-side N
        # is rounded up to (128, 256) respectively; (2) SFB is
        # replicated across 2-CTA peers rather than split along M, so
        # its partitioning is per-CTA even when the main atom is
        # 2-CTA. For N in {128, 256} the round-up is a no-op; built
        # unconditionally, but not consumed.
        self.mma_inst_shape_mn_sfb = (
            self.mma_inst_shape_mn[0] // self.num_mma_ctas,
            cute.round_up(self.mma_inst_shape_mn[1], 128),
        )
        self.mma_tiler_sfb = (
            self.mma_inst_shape_mn_sfb[0],
            self.mma_inst_shape_mn_sfb[1],
            mma_inst_shape_k * self.mma_inst_tile_k,
        )
        self.tiled_mma_sfb = sm100_utils.make_blockscaled_trivial_tiled_mma(
            self.ab_dtype,
            self.ab_dtype,
            a_major_mode,
            b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_mn_sfb,
        )
        self.cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (self.tiled_mma_sfb.thr_id.shape,),
        )

        self.epi_tile = sm100_utils.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.d_layout,
            self.d_dtype,
        )

        self._compute_stages()

    def _compute_stages(self):
        """Pick TMA-load, TMA-store, and accumulator pipeline depths.

        TMA-load (= A + B + SFA + SFB) and TMA-store (= D) share the
        SMEM budget and run on independent pipelines. The heuristic
        has two phases:

        1. 1:1 floor -- at least 2 of each (double-buffering minimum)
           if the budget allows.
        2. Weighted fill at the 2:1 (TMA-load : TMA-store) ratio: a
           TMA-load stage carries A+B+SFA+SFB and benefits from
           extra depth more than a TMA-store stage, which carries
           one D epi subtile. TMA-store is capped at 4 because one
           CTA tile streams out in 4 epi subtiles; surplus flows
           into TMA-load.

        Raises ``CantImplementError`` if any pipeline gets zero stages.

        Accumulator buffering lives in the separate TMEM budget and is chosen
        later by ``plan_accumulator_buffering`` after all owning TMEM layouts
        are available.
        """
        a_smem_layout_one = sm100_utils.make_smem_layout_a(
            self.tiled_mma,
            self.mma_tiler_mnk,
            self.ab_dtype,
            1,
        )
        b_smem_layout_one = sm100_utils.make_smem_layout_b(
            self.tiled_mma,
            self.mma_tiler_mnk,
            self.ab_dtype,
            1,
        )
        sfa_smem_layout_one = blockscaled_utils.make_smem_layout_sfa(
            self.tiled_mma,
            self.mma_tiler_mnk,
            self.sf_vec_size,
            1,
        )
        sfb_smem_layout_one = blockscaled_utils.make_smem_layout_sfb(
            self.tiled_mma,
            self.mma_tiler_mnk,
            self.sf_vec_size,
            1,
        )
        d_smem_layout_one = sm100_utils.make_smem_layout_epi(
            self.d_dtype,
            self.d_layout,
            self.epi_tile,
            1,
        )

        costs = {
            "tma": cute.size_in_bytes(self.ab_dtype, a_smem_layout_one)
            + cute.size_in_bytes(self.ab_dtype, b_smem_layout_one)
            + cute.size_in_bytes(self.sf_dtype, sfa_smem_layout_one)
            + cute.size_in_bytes(self.sf_dtype, sfb_smem_layout_one),
            "d": cute.size_in_bytes(self.d_dtype, d_smem_layout_one),
        }

        reserved_bytes = 1024
        budget = self.smem_capacity - reserved_bytes

        # Phase 1: 1:1 floor (up to 2 of each (double-buffering) - if it fits).
        n = min(2, budget // sum(costs.values()))
        counts = {p: n for p in costs}
        budget -= n * sum(costs.values())

        # Phase 2: As many main stages as possible
        n = budget // costs["tma"]
        counts["tma"] += n
        budget -= n * costs["tma"]

        # Phase 3: remaining budget flows into D (up to 4)
        n = min(4 - counts["d"], budget // costs["d"])
        counts["d"] += n
        budget -= n * costs["d"]

        if min(counts.values()) < 1:
            raise testing.CantImplementError(
                f"Insufficient SMEM: at least one pipeline has zero "
                f"stages. "
                f"budget={self.smem_capacity - reserved_bytes} B, "
                f"per-stage={costs}."
            )

        self.num_stages = counts["tma"]
        self.tma_store_stages = counts["d"]

    @cute.experimental.jit
    def __call__(
        self,
        mA: cute.Tensor,
        mSFA: cute.Tensor,
        mB: cute.Tensor,
        mSFB: cute.Tensor,
        mD: cute.Tensor,
        mAmax: Optional[cute.Tensor] = None,
    ):
        self._setup_attributes(mA, mB, mD)

        # Reinterpret the flat SFA / SFB tensors with block-scaled
        # layouts that tile the same way as A / B.
        # SFA: ((Atom_M, Rest_M), (Atom_K, Rest_K), RestL)
        sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(mA.shape, self.sf_vec_size)
        sfa_tensor = cute.make_tensor(mSFA.iterator, sfa_layout)

        # SFB: ((Atom_N, Rest_N), (Atom_K, Rest_K), RestL)
        sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(mB.shape, self.sf_vec_size)
        sfb_tensor = cute.make_tensor(mSFB.iterator, sfb_layout)

        # Persistent tile scheduler. Computes the launch grid and the
        # scheduler params that ``kernel`` uses to walk per-CTA tile
        # coords, so each CTA can process multiple tiles in sequence.
        cluster_shape = (*self.cluster_shape_mn, 1)
        fallback_cluster_shape = (*self.fallback_cluster_shape_mn, 1)
        num_ctas_mnl = (
            cute.ceil_div(mD.layout.shape[0], self.cta_tile_shape_mnk[0]),
            cute.ceil_div(mD.layout.shape[1], self.cta_tile_shape_mnk[1]),
            mD.layout.shape[2],
        )
        tile_sched_params = PersistentTileSchedulerParams(
            num_ctas_mnl,
            cluster_shape,
            fallback_cluster_shape_mnk=fallback_cluster_shape,
        )

        # Cluster count of the launch grid: the device-queried capacity
        # (actual persistence) when set, otherwise enough clusters to
        # cover the whole problem (collapses to non-persistent).
        if cutlass.const_expr(self.max_active_clusters is not None):
            max_active_clusters = self.max_active_clusters
        else:
            # ``ceil_div`` rounds partial clusters up to full clusters
            # so peer CTAs always come in complete groups (required for
            # 2-CTA selfcast).
            max_active_clusters = (
                cute.ceil_div(num_ctas_mnl[0], self.cluster_shape_mn[0])
                * cute.ceil_div(num_ctas_mnl[1], self.cluster_shape_mn[1])
                * num_ctas_mnl[2]
            )
        grid = StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )

        # Build the raw-CuTe SFB TMA atom + (possibly rewritten) gmem
        # tensor up-front so the kernel can use them in the special
        # ``mma_inst_mn[1] in (64, 192)`` codepaths. For other N
        # values these are well-defined but unused.
        sfb_op = sm100_utils.cluster_shape_to_tma_atom_SFB(
            self.cluster_shape_mn, self.tiled_mma.thr_id
        )
        sfb_smem_layout_one = blockscaled_utils.make_smem_layout_sfb(
            self.tiled_mma,
            self.mma_tiler_mnk,
            self.sf_vec_size,
            1,
        )
        tma_atom_sfb, tma_tensor_sfb = cute.nvgpu.make_tiled_tma_atom_B(
            sfb_op,
            sfb_tensor,
            sfb_smem_layout_one,
            self.mma_tiler_sfb,
            self.tiled_mma_sfb,
            self.cluster_layout_sfb_vmnk.shape,
            internal_type=cutlass.Int16,
        )

        # The ``mma_inst_mn[1] == 192`` case creates a misalignment
        # between MMA atoms and SF tiles: SF tiles are indivisible
        # 128-wide blocks, but MMA wants to consume 192 elements
        # (along N) at a time, as illustrated below:
        #
        # +-----------------+
        # | SF0 | SF1 | SF2 |
        # +-----------------+
        # |  MMA0  |  MMA1  |
        # +-----------------+
        #
        # - MMA0 wants to read the lower 192 elements from tiles SF0 and SF1
        # - MMA1 wants to read the upper 192 elements from tiles SF1 and SF2
        # - after that, the pattern repeats
        #
        # Since each MMA reads two consecutive SF tiles, with consecutive
        # MMAs starting at different tile boundaries, we rewrite SFB's
        # layout such that we can index it with 1-tile granularity but
        # transfer 2 tiles at once via a single TMA load instruction.
        #
        # Shifting the MMA read window to the lower/upper 192 elements
        # is handled later by a TMEM-pointer shift in ``kernel``.
        #
        # Implemented in the lower-level CuTe dialect because
        # cute_ext.tma_load() doesn't support overlapping tiles yet.
        #
        # The ``mma_inst_mn[1] == 64`` case has the *opposite*
        # misalignment: each 128-wide SF tile feeds two consecutive
        # 64-wide MMA tiles, as illustrated below:
        #
        # +-------------+
        # |     SF0     |
        # +-------------+
        # | MMA0 | MMA1 |
        # +-------------+
        #
        # - MMA0 reads the lower 64 elements of SF0
        # - MMA1 reads the upper 64 elements of SF0
        # - and so on
        #
        # so SFB tiles can be loaded as-is (no layout rewrite needed)
        # and the kernel slices ``cta_n // 2`` to map each MMA tile
        # to its sharing SF tile. The same TMEM-pointer shift handles
        # the lower/upper 64-element selection.
        if cutlass.const_expr(self.mma_inst_shape_mn[1] == 192):
            x = tma_tensor_sfb.stride[0][1]
            y = cute.ceil_div(tma_tensor_sfb.shape[0][1], 4)
            new_shape = (
                (tma_tensor_sfb.shape[0][0], ((2, 2), y)),
                tma_tensor_sfb.shape[1],
                tma_tensor_sfb.shape[2],
            )
            x_times_3 = 3 * x
            new_stride = (
                (tma_tensor_sfb.stride[0][0], ((x, x), x_times_3)),
                tma_tensor_sfb.stride[1],
                tma_tensor_sfb.stride[2],
            )
            tma_tensor_sfb = cute.make_tensor(
                tma_tensor_sfb.iterator,
                cute.make_layout(new_shape, stride=new_stride),
            )

        self.kernel(
            self.tiled_mma,
            mA,
            sfa_tensor,
            mB,
            sfb_tensor,
            mD,
            mAmax,
            self.tiled_mma_sfb,
            self.cluster_layout_sfb_vmnk,
            tma_atom_sfb,
            tma_tensor_sfb,
            tile_sched_params,
        ).launch(
            grid=grid,
            # Using a total of 6 (==192 threads) warps:
            #   * 1x tma_load (issues A/B/SFA/SFB, commits tma_pipe)
            #   * 1x mma
            #   * 4x epilogue (one of which doubles as the tma_store warp)
            block=(192, 1, 1),
            cluster=cluster_shape,
            fallback_cluster=fallback_cluster_shape,
            smem=self.smem_capacity,
        )

    @cute.experimental.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        mA: cute.Tensor,
        mSFA: cute.Tensor,
        mB: cute.Tensor,
        mSFB: cute.Tensor,
        mD: cute.Tensor,
        # Optional FP32 single-element GMEM output tensor = max(|Acc|)
        mAmax: Optional[cute.Tensor],
        # SFB-related arguments consumed only by the N=192 codepath;
        # built by ``__call__`` and ignored for N in {128, 256}.
        tiled_mma_sfb: cute.TiledMma,
        cluster_layout_sfb_vmnk: cute.Layout,
        tma_atom_sfb: cute.CopyAtom,
        tma_tensor_sfb: cute.Tensor,
        # Persistent tile scheduler params; necessary because the
        # launch grid no longer maps 1:1 to problem tiles.
        tile_sched_params: PersistentTileSchedulerParams,
    ):
        # Prologue: shared per-CTA setup before the per-warp loops.
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        # Cluster layout for 2-CTA coordination. Degenerates to a
        # trivial layout (v-mode size 1) for 1-CTA, which makes the
        # 2-CTA-specific code below correctly turn into no-ops.
        #
        # Reading the cluster shape via ``cute.arch.block_in_cluster_dim()``
        # lets the same source compile for both the preferred and the
        # fallback launch shapes under mixed-cluster: the compiler
        # specializes the kernel to a statically-known cluster shape per
        # launched cluster.
        cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(cute.arch.block_in_cluster_dim()),
            (tiled_mma.thr_id.shape,),
        )
        cluster_layout_v_size = cute.size(cluster_layout_vmnk.shape[0])
        # ``mma_tile_coord_v`` (and ``is_leader_cta``) is CTA-invariant:
        # it depends only on the CTA's index within its cluster, not on
        # which tile the CTA is currently processing. Compute it once
        # here so the per-warp loops below don't recompute it.
        bidx, _, _ = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cluster_layout_v_size
        is_leader_cta = mma_tile_coord_v == 0

        gA_mkl = cute.local_tile(
            mA,
            cute.slice_(self.mma_tiler_mnk, (None, 0, None)),
            (None, None, None),
        )
        gB_nkl = cute.local_tile(
            mB,
            cute.slice_(self.mma_tiler_mnk, (0, None, None)),
            (None, None, None),
        )
        gSFA_mkl = cute.local_tile(
            mSFA,
            cute.slice_(self.mma_tiler_mnk, (None, 0, None)),
            (None, None, None),
        )

        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        tCgA = thr_mma.partition_A(gA_mkl)
        tCgB = thr_mma.partition_B(gB_nkl)
        tCgSFA = thr_mma.partition_A(gSFA_mkl)

        # Standard SFB gmem partition for the IR codepath. The N=64
        # and N=192 codepaths skip this and partition from
        # ``tma_tensor_sfb`` directly inside ``is_tma_load_warp``
        # below; see the SFB-tile-vs-MMA-tile alignment comment in
        # ``__call__`` for why.
        if cutlass.const_expr(self.mma_inst_shape_mn[1] not in (64, 192)):
            gSFB_nkl = cute.local_tile(
                mSFB,
                cute.slice_(self.mma_tiler_sfb, (0, None, None)),
                (None, None, None),
            )
            # SFB is replicated, not N-split: use the 1-CTA tiled_mma_sfb.
            thr_mma_sfb = tiled_mma_sfb.get_slice(mma_tile_coord_v)
            tCgSFB = thr_mma_sfb.partition_B(gSFB_nkl)

        # Shared memory layouts for A/B/SFA/SFB/D. A, B, SFA, and SFB
        # share the TMA-load pipeline's depth (``num_stages``).
        # (MMA, MMA_M, MMA_K, PIPE)
        a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            self.mma_tiler_mnk,
            self.ab_dtype,
            self.num_stages,
        )

        # (MMA, MMA_N, MMA_K, PIPE)
        b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma,
            self.mma_tiler_mnk,
            self.ab_dtype,
            self.num_stages,
        )

        # (MMA, MMA_M, MMA_K, PIPE)
        sfa_smem_layout_staged = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma,
            self.mma_tiler_mnk,
            self.sf_vec_size,
            self.num_stages,
        )

        # (MMA, MMA_N, MMA_K, PIPE)
        sfb_smem_layout_staged = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma,
            self.mma_tiler_mnk,
            self.sf_vec_size,
            self.num_stages,
        )

        # One-view UMMA accumulator layout. The buffering planner appends the
        # storage mode after all other owning TMEM footprints are known.
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler_mnk[:2])
        tmem_acc_one_stage_layout = tiled_mma.make_fragment_C(acc_shape).layout

        sfa_tmem_layout = blockscaled_utils.make_tmem_layout_sfa(
            tiled_mma,
            self.mma_tiler_mnk,
            self.sf_vec_size,
            cute.slice_(sfa_smem_layout_staged, (None, None, None, 0)),
        )

        sfb_tmem_layout = blockscaled_utils.make_tmem_layout_sfb(
            tiled_mma,
            self.mma_tiler_mnk,
            self.sf_vec_size,
            cute.slice_(sfb_smem_layout_staged, (None, None, None, 0)),
        )

        # Rebuild the epilogue tile in the kernel region. ``self.epi_tile`` is
        # created by the host-side setup and cannot feed layout operations in
        # this isolated device region.
        accumulator_epilogue_tile = sm100_utils.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.d_layout,
            self.d_dtype,
        )
        accumulator_plan = cute_ext.plan_accumulator_buffering(
            one_stage_layout=tmem_acc_one_stage_layout,
            accumulator_dtype=self.acc_dtype,
            # Use the actual epilogue tiler so the planner converts its element
            # width to 32-bit TMEM columns for the accumulator dtype.
            epilogue_tile=accumulator_epilogue_tile,
            auxiliary_tmem_allocations=(
                cute_ext.TmemAllocationRequest.from_layout(
                    "sfa",
                    sfa_tmem_layout,
                    self.sf_dtype,
                    alignment_bytes=16,
                ),
                cute_ext.TmemAllocationRequest.from_layout(
                    "sfb",
                    sfb_tmem_layout,
                    self.sf_dtype,
                    alignment_bytes=16,
                ),
            ),
            allow_overlap=self.allow_accumulator_overlap,
        )
        tmem_accs_layout = accumulator_plan.storage_layout

        # Allocate UMMA Buffers
        buffer_smem_a = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )

        buffer_smem_b = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )

        buffer_smem_sfa = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.smem,
            sfa_smem_layout_staged,
            alignment=1024,
        )

        buffer_smem_sfb = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.smem,
            sfb_smem_layout_staged,
            alignment=1024,
        )

        # ``is2cta`` tells the allocator to reserve "wide" TMEM that
        # the 2-CTA MMA can address across both peers. For 1-CTA it is
        # a no-op.
        buffer_tmem_accs = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.tmem,
            tmem_accs_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )

        buffer_tmem_sfa = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.tmem,
            sfa_tmem_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )

        buffer_tmem_sfb = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.tmem,
            sfb_tmem_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )

        buffer_tmem_sfa_compact = cute.filter_zeros(buffer_tmem_sfa)
        buffer_tmem_sfb_compact = cute.filter_zeros(buffer_tmem_sfb)

        # Make S2T CopyAtom and tiledCopy
        copy_atom_s2t = cute.make_copy_atom(
            tcgen05.Cp4x32x128bOp(self.cta_group),
            self.sf_dtype,
        )

        tiled_copy_s2t_sfa = cute.nvgpu.tcgen05.make_s2t_copy(
            copy_atom_s2t, buffer_tmem_sfa_compact
        )
        tiled_copy_s2t_sfb = cute.nvgpu.tcgen05.make_s2t_copy(
            copy_atom_s2t, buffer_tmem_sfb_compact
        )

        # Pick MMA / TMA op types from the CtaGroup and whether we need
        # TMA multicast. The four combinations are:
        #   1-CTA selfcast  -> SM90_TMA_LOAD
        #   1-CTA multicast -> SM90_TMA_LOAD_MULTICAST
        #   2-CTA selfcast  -> SM100_TMA_LOAD_2SM           (peer-aware, single cluster)
        #   2-CTA multicast -> SM100_TMA_LOAD_2SM_MULTICAST (peer-aware + cluster-wide broadcast)
        if cutlass.const_expr(self.use_2cta_instrs):
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_2SM_SS
            if cutlass.const_expr(self.use_tma_multicast):
                tma_operation_type = (
                    cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST
                )
            else:
                tma_operation_type = cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM
        else:
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS
            if cutlass.const_expr(self.use_tma_multicast):
                tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD_MULTICAST
            else:
                tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD

        # TMA multicast projection modes (cluster-axis indices in vmnk).
        # A and SFA broadcast along cluster-N (proj_A=2) because A doesn't
        # vary along N; B broadcasts along cluster-M (proj_B=1) because B
        # doesn't vary along M. A size-1 cluster axis (e.g. 2-CTA selfcast
        # along M) degenerates to a standard load.
        tma_mcast_proj_A = 2
        tma_mcast_proj_B = 1

        # TMA -> UMMA. The producer warp issues A, B, SFA, and SFB
        # against the same mbar per K-tile so the mbar's expect_tx
        # accumulates each load's bytes; the consumer acquires once
        # per K-tile and sees all four buffers ready together.
        tma_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=self.num_stages,
            mma_operation_type=mma_operation_type,
            tma_operation_type=tma_operation_type,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # UMMA -> Load to tensor memory. For 2-CTA both peers' epilogue
        # warpgroups call ``consumer_release``, so the arrive count doubles.
        # This branch's pipeline takes the count directly; the
        # consumer_release_threads_per_cta spelling landed after the 4.8 cut.
        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=accumulator_plan.synchronization_depth,
            mma_operation_type=mma_operation_type,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=256 if self.use_2cta_instrs else 128,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # warp assignment: [0]-tma_store, [0-3]-epi, [4]-mma,
        #                  [5]-tma_load (A/B/SFA/SFB)
        tma_store_warp_id = 0
        mma_warp_id = 4
        tma_load_warp_id = 5
        is_tma_load_warp = warp_idx == tma_load_warp_id
        is_mma_warp = warp_idx == mma_warp_id
        is_epi_warp = warp_idx < 4

        # Shared memory store -> TMA store to global memory
        tma_store_pipe = cute_ext.TMAStorePipeline(
            stages=self.tma_store_stages,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=tma_store_warp_id,
        )

        k_tile_size = cute.size(gA_mkl, mode=[3])

        if is_tma_load_warp:
            # Dedicated TMA producer warp. Issues A, B, SFA, and SFB
            # against one mbar per K-tile and feeds the MMA consumer.
            # The N=64 and N=192 cases (see ``__call__``) dispatch to
            # a raw-CuTe codepath for SFB via ``cutlass.const_expr``
            # switches because the SFB load granularity (128) does
            # not match the MMA-N (64 or 192).
            if cutlass.const_expr(self.mma_inst_shape_mn[1] in (64, 192)):
                # Raw-CuTe codepath for N in {64, 192}. ``cute_ext.tma_load*``
                # updates the tma_pipe mbar's expect_tx implicitly, but
                # ``cute.copy`` does not -- we have to register SFB's
                # contribution ourselves at the call site below or
                # the consumer wakes before SFB has arrived. Multiply
                # by ``atom_thr_size`` so each 2-CTA peer accounts
                # for its broadcast copy.
                atom_thr_size = cute.size(tiled_mma.thr_id.shape)
                sfb_copy_size = (
                    cute.size_in_bytes(
                        self.sf_dtype,
                        cute.slice_(sfb_smem_layout_staged, (None, None, None, 0)),
                    )
                    * atom_thr_size
                )
                cta_rank_in_cluster = cute.arch.make_warp_uniform(
                    cute.arch.block_idx_in_cluster()
                )
                block_in_cluster_coord_sfb_vmnk = (
                    cluster_layout_sfb_vmnk.get_flat_coord(cta_rank_in_cluster)
                )

                # Manual gmem + TMA partition off ``tma_tensor_sfb``.
                # For N=192 the layout was rewritten in ``__call__``
                # to pack two consecutive 128-wide SF tiles into one
                # overlapping 256-wide load; for N=64 the layout is
                # unchanged so each load brings in one 128-wide SF
                # tile that two consecutive MMA tiles share.
                gSFB_nkl_raw = cute.local_tile(
                    tma_tensor_sfb,
                    cute.slice_(self.mma_tiler_sfb, (0, None, None)),
                    (None, None, None),
                )
                thr_mma_sfb_raw = tiled_mma_sfb.get_slice(mma_tile_coord_v)
                tCgSFB_64or192 = thr_mma_sfb_raw.partition_B(gSFB_nkl_raw)

                sfb_cta_layout = cute.make_layout(
                    cute.slice_(cluster_layout_sfb_vmnk, (0, None, 0, 0)).shape
                )
                tBsSFB, tBgSFB = cute.nvgpu.cpasync.tma_partition(
                    tma_atom_sfb,
                    block_in_cluster_coord_sfb_vmnk[1],
                    sfb_cta_layout,
                    cute.group_modes(buffer_smem_sfb, 0, 3),
                    cute.group_modes(tCgSFB_64or192, 0, 3),
                )
                tBsSFB = cute.filter_zeros(tBsSFB)
                tBgSFB = cute.filter_zeros(tBgSFB)

                # SFB multicasts along cluster-M (``mcast_mode=1``):
                # cluster-N broadcasts B but not SFB, and 2-CTA
                # replicates SFB across peers along M.
                if cutlass.const_expr(self.use_tma_multicast or self.use_2cta_instrs):
                    sfb_full_mcast_mask = cute.nvgpu.cpasync.create_tma_multicast_mask(
                        cluster_layout_sfb_vmnk,
                        block_in_cluster_coord_sfb_vmnk,
                        mcast_mode=1,
                    )
                else:
                    sfb_full_mcast_mask = None

            tile_sched = StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            # Persistent loop: one outer iteration per CTA tile, one
            # inner iteration per K-block (= one ``tma_pipe`` stage).
            while work_tile.is_valid_tile:
                cta_m, cta_n, cta_l = work_tile.tile_idx

                mma_tile_coord_m = cta_m // cluster_layout_v_size
                tAgA_tile = tCgA[(None, None, None, mma_tile_coord_m, None, cta_l)]
                tBgB_tile = tCgB[(None, None, None, cta_n, None, cta_l)]
                tAgSFA_tile = tCgSFA[(None, None, None, mma_tile_coord_m, None, cta_l)]
                if cutlass.const_expr(self.mma_inst_shape_mn[1] not in (64, 192)):
                    tBgSFB_tile = tCgSFB[(None, None, None, cta_n, None, cta_l)]
                else:
                    # For N=192 the rewritten ``tma_tensor_sfb`` makes
                    # tile index = ``cta_n`` (each MMA tile owns one
                    # overlapping 256-wide load). For N=64 the layout
                    # is plain 128-wide and two consecutive MMA tiles
                    # share one SF tile, so the SF tile index is
                    # ``cta_n // 2``.
                    if cutlass.const_expr(self.mma_inst_shape_mn[1] == 192):
                        sfb_n_coord = cta_n
                    else:
                        sfb_n_coord = cta_n // 2
                    tBgSFB_slice = tBgSFB[(None, sfb_n_coord, None, cta_l)]

                # Per K-block: acquire one tma_pipe stage, issue A,
                # B, SFA, and SFB loads against the same mbar so they
                # commit together, then advance.
                for k_tile_idx in cutlass.range(0, k_tile_size, 1, unroll=1):
                    gA_k = tAgA_tile[(None, None, None, k_tile_idx)]
                    gB_k = tBgB_tile[(None, None, None, k_tile_idx)]
                    gSFA_k = tAgSFA_tile[(None, None, None, k_tile_idx)]

                    (
                        tma_producer_token,
                        stage_idx,
                    ) = tma_pipe.producer_acquire_and_get_stage()
                    tma_mbar = cute_ext.get_mbarrier(tma_producer_token)
                    buffer_smem_a_sliced = buffer_smem_a[None, None, None, stage_idx]
                    buffer_smem_b_sliced = buffer_smem_b[None, None, None, stage_idx]
                    buffer_smem_sfa_sliced = buffer_smem_sfa[
                        None, None, None, stage_idx
                    ]

                    cute_ext.tma_load(
                        gA_k,
                        buffer_smem_a_sliced,
                        tma_mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_A,
                    )
                    cute_ext.tma_load(
                        gB_k,
                        buffer_smem_b_sliced,
                        tma_mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_B,
                    )
                    cute_ext.tma_load(
                        gSFA_k,
                        buffer_smem_sfa_sliced,
                        tma_mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_A,
                    )
                    if cutlass.const_expr(self.mma_inst_shape_mn[1] not in (64, 192)):
                        gSFB_k = tBgSFB_tile[(None, None, None, k_tile_idx)]
                        buffer_smem_sfb_sliced = buffer_smem_sfb[
                            None, None, None, stage_idx
                        ]
                        cute_ext.tma_load(
                            gSFB_k,
                            buffer_smem_sfb_sliced,
                            tma_mbar,
                            vmnk_layout=cluster_layout_vmnk,
                            tma_operation_type=tma_operation_type,
                            multicast_mode=tma_mcast_proj_B,
                        )
                    else:
                        tma_mbar_ptr = tma_mbar.result
                        leader_cta_rank = cta_rank_in_cluster & ~(self.num_mma_ctas - 1)
                        sfb_mbar_ptr = cute.arch.map_dsmem_ptr(
                            tma_mbar_ptr, leader_cta_rank
                        )
                        # Register SFB's expect_tx contribution (see
                        # raw-CuTe branch comment above);
                        # ``mbarrier_expect_tx`` is per-thread, so
                        # gate with ``elect_one``.
                        with cute.arch.elect_one():
                            if is_leader_cta:
                                cute.arch.mbarrier_expect_tx(
                                    tma_mbar_ptr, sfb_copy_size
                                )
                        cute.copy(
                            tma_atom_sfb,
                            tBgSFB_slice[(None, k_tile_idx)],
                            tBsSFB[(None, stage_idx)],
                            tma_bar_ptr=sfb_mbar_ptr,
                            mcast_mask=sfb_full_mcast_mask,
                        )
                    tma_pipe.producer_commit_and_advance()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            # Drain pending ``tma_pipe`` stages on shutdown. Without
            # this the producer can wrap around faster than the
            # consumer drains, leaving stale acquire tokens that hang
            # the kernel.
            tma_pipe.producer_tail()

        if is_mma_warp and is_leader_cta:
            # MMA consumer warp. Consumes tma_pipe (A, B, SFA, SFB),
            # produces acc_pipe (accumulators) for the epilogue.
            # Only the leader CTA in 2-CTA mode issues the MMA --
            # the peer's TMEM is addressed via the leader's mbar, so
            # peer CTAs are excluded from this whole block. (For
            # 1-CTA ``is_leader_cta`` is always True.)
            mma_atom = cute.make_mma_atom(tiled_mma.op)
            filtered_buffer_smem_sfa = cute.filter_zeros(buffer_smem_sfa)
            filtered_buffer_smem_sfb = cute.filter_zeros(buffer_smem_sfb)
            tile_sched = StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            # Persistent loop: one outer iteration per CTA tile, one
            # inner iteration per K-block consumed from tma_pipe.
            while work_tile.is_valid_tile:
                _, cta_n, _ = work_tile.tile_idx

                # Acquire one acc_pipe stage per tile; the buffer
                # rotates through the planner's logical views so the epi
                # warps can drain tile N-1 while we produce tile N.
                accumulators_sliced = accumulator_plan.producer_acquire_and_get_view(
                    acc_pipe,
                    buffer_tmem_accs,
                )

                # First MMA of each tile overwrites the accumulator
                # rather than adding to it; flipped to True after the
                # first inner-loop iteration below.
                mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)

                # N=64 / N=192 consumer-side demux. The SFB SMEM /
                # TMEM are 128-wide for N=64 and 256-wide for N=192
                # (always rounded up to the nearest multiple of 128),
                # while each MMA only consumes ``mma_inst_shape_mn[1]``
                # of those. Two consecutive N tiles share one SF load,
                # so odd N tiles read SFB starting two TMEM columns
                # later. Offset is in 32-bit cells and depends on
                # cta_n, so the shift lives inside the tile loop.
                if cutlass.const_expr(self.mma_inst_shape_mn[1] in (64, 192)):
                    offset = cutlass.Int32((cta_n % 2) * 2)
                    buffer_tmem_sfb_for_mma = cute.make_tensor(
                        cute.recast_ptr(
                            cute.recast_ptr(
                                buffer_tmem_sfb.iterator, dtype=cutlass.Int32
                            )
                            + offset,
                            dtype=self.sf_dtype,
                        ),
                        buffer_tmem_sfb.layout,
                    )
                else:
                    buffer_tmem_sfb_for_mma = buffer_tmem_sfb

                for k_tile_idx in cutlass.range(0, k_tile_size, 1, unroll=1):
                    # Wait one stage from the producer pipe; A, B,
                    # SFA, and SFB share the same stage index.
                    _, idx = tma_pipe.consumer_wait_and_get_stage()
                    buffer_smem_a_sliced_stage = buffer_smem_a[(None, None, None, idx)]
                    buffer_smem_b_sliced_stage = buffer_smem_b[(None, None, None, idx)]
                    filtered_buffer_smem_sfa_sliced_stage = filtered_buffer_smem_sfa[
                        (None, None, None, idx)
                    ]
                    filtered_buffer_smem_sfb_sliced_stage = filtered_buffer_smem_sfb[
                        (None, None, None, idx)
                    ]

                    # Stage SF into TMEM via UTCCP (SMEM->TMEM);
                    # tcgen05 requires SF operands resident in TMEM at
                    # MMA issue time, so this fires once per K-tile.
                    thr_s2t_sfa = tiled_copy_s2t_sfa.get_slice(cute.Int32(0))
                    thr_s2t_sfb = tiled_copy_s2t_sfb.get_slice(cute.Int32(0))

                    cute_ext.partition_and_copy(
                        thr_s2t_sfa,
                        filtered_buffer_smem_sfa_sliced_stage,
                        buffer_tmem_sfa_compact,
                    )
                    cute_ext.partition_and_copy(
                        thr_s2t_sfb,
                        filtered_buffer_smem_sfb_sliced_stage,
                        buffer_tmem_sfb_compact,
                    )

                    # Issue ``mma_inst_tile_k`` MMAs over the K-blocks
                    # packed into this SMEM stage.
                    for k_block_idx in cutlass.range(
                        self.mma_inst_tile_k, unroll_full=True
                    ):
                        buffer_smem_a_sliced = buffer_smem_a_sliced_stage[
                            None, None, k_block_idx
                        ]
                        buffer_smem_b_sliced = buffer_smem_b_sliced_stage[
                            None, None, k_block_idx
                        ]

                        cute_ext.dot_block_scaled(
                            mma_atom,
                            buffer_smem_a_sliced,
                            cute.group_modes(
                                buffer_tmem_sfa[(None, (None, 0)), None, k_block_idx],
                                0,
                                2,
                            ),
                            buffer_smem_b_sliced,
                            cute.group_modes(
                                buffer_tmem_sfb_for_mma[
                                    (None, (None, 0)), None, k_block_idx
                                ],
                                0,
                                2,
                            ),
                            accumulators_sliced,
                        )
                        mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)

                    tma_pipe.consumer_release_and_advance()

                acc_pipe.producer_commit_and_advance()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            # Drain pending ``acc_pipe`` stages on shutdown; same
            # reasoning as the AB warp's tail above.
            acc_pipe.producer_tail()

        if is_epi_warp:
            # Epilogue warps (4 of them). Pure consumer of
            # ``acc_pipe``, pure producer of ``tma_store_pipe``;
            # ``cute_ext.epilogue_tma_store`` below drains the store
            # pipe via its own ``tail()``, so no manual
            # ``producer_tail()`` is needed here.
            tile_sched = StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            # Persistent loop: one iteration per CTA tile (= one
            # ``acc_pipe`` stage drained, one D tile stored).
            while work_tile.is_valid_tile:
                cta_m, cta_n, cta_l = work_tile.tile_idx

                accumulator_drain = None
                if cutlass.const_expr(accumulator_plan.uses_overlap):
                    (
                        tmem_acc_buffer,
                        accumulator_drain,
                    ) = accumulator_plan.consumer_wait_and_get_view(
                        acc_pipe,
                        buffer_tmem_accs,
                    )
                    tmem_acc_stage = tmem_acc_buffer[(None, None), 0, 0]
                else:
                    _, acc_stage_idx = acc_pipe.consumer_wait_and_get_stage()
                    tmem_acc_stage = buffer_tmem_accs[
                        (None, None), 0, 0, acc_stage_idx
                    ]  # (MMA_M, MMA_N)
                cta_d_tile_coord = (cta_m, cta_n, cta_l)

                # Quantize the accumulator, apply ``epilogue_op``, and
                # TMA-store the result to D. Keep one call so the ordinary and
                # overlap paths cannot drift in their epilogue arguments; the
                # optional drain is specialized at JIT time and solely adds the
                # overlap traversal/release protocol.
                epilogue_result = cute_ext.epilogue_tma_store(
                    self.cta_tile_shape_mnk,
                    self.use_2cta_instrs,
                    tmem_acc_stage,
                    mD,
                    cta_d_tile_coord,
                    tma_store_pipe,
                    tma_store_warp_id,
                    self.epilogue_op,
                    amax_out=mAmax,
                    accumulator_drain=accumulator_drain,
                )

                # The helper preserves its established single-pipeline return
                # when no drain is present. The constexpr branch resolves that
                # specialized return shape without imposing API churn on its
                # existing callers.
                if cutlass.const_expr(accumulator_plan.uses_overlap):
                    tma_store_pipe, acc_pipe = epilogue_result
                else:
                    tma_store_pipe = epilogue_result
                    acc_pipe.consumer_release_and_advance()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()


# TODO: add residual support (C)
@dataclass
class BlockScaledGemmTestbed:
    """Test harness for ``BlockScaledDenseGemmKernel``.

    Builds matched CPU reference (f32) and device CUTE tensors for
    each operand (A, B, SFA, SFB, D), so the kernel can be invoked
    with the device tensors and the result validated against PyTorch
    reference computed from the f32 copies.

    The kernel computes ``D = (A * SFA) @ (B * SFB)`` where SFA / SFB
    are block scale factors with vector size ``sf_vec_size``. See
    ``run`` below for end-to-end usage.

    Optionally also tracks ``amax = max |Acc_ij|`` -- when ``compute_amax=True``.

    Attributes (beyond the self-documenting tensor pairs):
        d_gpu: PyTorch mirror of ``d_tensor`` used by
            ``reference_check`` to copy the kernel's output back to
            the host.
        d_major: Major-ness ('m' or 'n') of D. Retained so
            ``reference_check`` can interpret the round-tripped
            ``d_gpu`` correctly.
        amax_tensor: ``cute.Tensor | None``. CuTe wrapper around a
            1-element FP32 device tensor; passed as the ``mAmax``
            argument when the kernel is compiled with AMax support.
        amax_gpu: ``torch.Tensor | None``. PyTorch view of the same
            underlying device buffer as ``amax_tensor``; read by
            ``reference_check`` to verify against the CPU reference.
    """

    # Reference tensors (all are in f32 format for simplicity of
    # reference checks)
    a_ref: torch.Tensor
    b_ref: torch.Tensor
    sfa_ref: torch.Tensor
    sfb_ref: torch.Tensor
    amax_gpu: Optional[torch.Tensor]

    # CUTE tensors (to be passed to the device kernel)
    a_tensor: cute.Tensor
    b_tensor: cute.Tensor
    sfa_tensor: cute.Tensor
    sfb_tensor: cute.Tensor
    d_tensor: cute.Tensor
    amax_tensor: Optional[cute.Tensor]

    def __init__(
        self,
        MNKL: Tuple[int, int, int, int],
        ab_dtype: Type[cutlass.Numeric],
        d_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        a_major: str,
        b_major: str,
        d_major: str,
        compute_amax: bool = False,
    ):
        self.d_major = d_major

        # Problem size
        (M, N, K, L) = MNKL

        (
            self.a_ref,
            self.b_ref,
            self.d_gpu,
            self.a_tensor,
            self.b_tensor,
            self.d_tensor,
        ) = get_gemm_tensors(
            M,
            N,
            K,
            L,
            (
                cute.nvgpu.OperandMajorMode.K
                if a_major == "k"
                else cute.nvgpu.OperandMajorMode.MN,
                cute.nvgpu.OperandMajorMode.K
                if b_major == "k"
                else cute.nvgpu.OperandMajorMode.MN,
                cute.nvgpu.OperandMajorMode.K
                if d_major == "n"
                else cute.nvgpu.OperandMajorMode.MN,
            ),
            (
                cutlass_torch.dtype(ab_dtype),
                cutlass_torch.dtype(ab_dtype),
                cutlass_torch.dtype(d_dtype),
            ),
        )

        self.sfa_ref, self.sfa_tensor, self.sfa_gpu = create_scale_factor_tensor(
            M, K, L, sf_vec_size, sf_dtype
        )
        self.sfb_ref, self.sfb_tensor, self.sfb_gpu = create_scale_factor_tensor(
            N, K, L, sf_vec_size, sf_dtype
        )

        self.amax_gpu = None
        self.amax_tensor = None
        if compute_amax:
            self.amax_gpu = torch.zeros(1, dtype=torch.float32, device="cuda")
            self.amax_tensor = from_dlpack(
                self.amax_gpu, assumed_align=4
            ).mark_layout_dynamic()

    # Transfers results back to CPU and uses PyTorch's methods to do
    # reference checks
    def reference_check(self):
        decode_ab = (
            decode_float4e2m1fn
            if self.a_tensor.element_type == cute.Float4E2M1FN
            else lambda x: x.to(torch.float32)
        )

        ref_d_f32 = torch.einsum(
            "mkl, nkl->mnl",
            decode_ab(self.a_ref.cpu()) * self.sfa_ref,
            decode_ab(self.b_ref.cpu()) * self.sfb_ref,
        )
        ref_d = ref_d_f32.to(cutlass_torch.dtype(self.d_tensor.element_type))

        gpu_d = self.d_gpu.cpu()
        torch.testing.assert_close(
            gpu_d,
            ref_d,
            atol=0.0,
            rtol=0.0,
        )

        if self.amax_gpu is not None:
            gpu_amax = self.amax_gpu.cpu().squeeze()
            ref_amax = ref_d_f32.abs().max()
            torch.testing.assert_close(
                gpu_amax,
                ref_amax,
                atol=0.0,
                rtol=0.0,
            )


def run(
    mnkl: Tuple[int, int, int, int],
    mma_inst_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    ab_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    d_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    d_major: str,
    compute_amax: bool = False,
    fallback_cluster_shape_mn: Optional[Tuple[int, int]] = None,
    allow_accumulator_overlap: bool = True,
    max_active_clusters_override: Optional[int] = None,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
) -> float:
    """End-to-end execution of ``BlockScaledDenseGemmKernel`` for one configuration.

    Lifecycle:

    1. Validate via ``can_implement`` (raises ``CantImplementError``).
    2. Build reference + device tensors (``BlockScaledGemmTestbed``).
    3. Construct and JIT-compile the kernel.
    4. Launch.
    5. Verify against PyTorch reference (unless ``skip_ref_check``).
    6. Benchmark the compiled kernel over ``iterations`` launches.

    This is the headless entry point: no CLI, printing,
    GPU-availability checks, or RNG seeding (see ``__main__`` for
    those concerns).

    ``cluster_shape_mn`` is the physical launch cluster. In 2-CTA mode,
    cluster-M must include the MMA peer pair and therefore be divisible
    by two.

    When ``compute_amax=True``, the optional ``mAmax`` argument is
    bound to a real single-element FP32 GMEM tensor. This enables
    the AMax codepath at JIT-time.

    :param warmup_iterations: Number of warmup launches before timing,
        defaults to 0.
    :type warmup_iterations: int
    :param iterations: Number of timed benchmark launches, defaults to 1.
    :type iterations: int
    :param skip_ref_check: Skip the PyTorch reference validation,
        defaults to False.
    :type skip_ref_check: bool
    :param use_cold_l2: Rotate through a circular buffer of workspace
        tensors so every launch reads from a cold L2 cache, defaults to
        False.
    :type use_cold_l2: bool
    :param allow_accumulator_overlap: Allow the TMEM planner to overlap
        accumulator views when two disjoint views do not fit, defaults to
        True.
    :type allow_accumulator_overlap: bool
    :raises cutlass.testing.CantImplementError: if the configuration
        is unsupported (see ``can_implement`` for the predicate).
    :return: Average kernel execution time in microseconds per iteration.
    :rtype: float
    """
    if reason := BlockScaledDenseGemmKernel.can_implement(
        mnkl,
        mma_inst_mn,
        cluster_shape_mn,
        ab_dtype,
        sf_dtype,
        sf_vec_size,
        d_dtype,
        acc_dtype,
        a_major,
        b_major,
        d_major,
        compute_amax,
    ):
        raise testing.CantImplementError(reason)

    # Create tensors
    tb = BlockScaledGemmTestbed(
        MNKL=mnkl,
        ab_dtype=ab_dtype,
        d_dtype=d_dtype,
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
        a_major=a_major,
        b_major=b_major,
        d_major=d_major,
        compute_amax=compute_amax,
    )

    # Query the device's persistent-cluster capacity using the physical
    # cluster shape passed to the launch.
    cluster_size = cluster_shape_mn[0] * cluster_shape_mn[1]
    if max_active_clusters_override is None:
        max_active_clusters = utils.HardwareInfo().get_max_active_clusters(cluster_size)
    else:
        max_active_clusters = max_active_clusters_override
    if fallback_cluster_shape_mn is not None:
        fallback_cluster_size = (
            fallback_cluster_shape_mn[0] * fallback_cluster_shape_mn[1]
        )
        max_active_fallback_clusters = utils.HardwareInfo().get_max_active_clusters(
            fallback_cluster_size
        )
    else:
        max_active_fallback_clusters = None

    # JIT-Compile the device kernel
    block_scaled_gemm = BlockScaledDenseGemmKernel(
        mma_inst_mn=mma_inst_mn,
        ab_dtype=ab_dtype,
        acc_dtype=acc_dtype,
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
        cluster_shape_mn=cluster_shape_mn,
        max_active_clusters=max_active_clusters,
        fallback_cluster_shape_mn=fallback_cluster_shape_mn,
        max_active_fallback_clusters=max_active_fallback_clusters,
        allow_accumulator_overlap=allow_accumulator_overlap,
    )

    compiled_kernel = cute.experimental.compile(
        block_scaled_gemm,
        tb.a_tensor,
        tb.sfa_tensor,
        tb.b_tensor,
        tb.sfb_tensor,
        tb.d_tensor,
        tb.amax_tensor,  # None by default
    )

    # Launch the device kernel
    compiled_kernel(
        tb.a_tensor,
        tb.sfa_tensor,
        tb.b_tensor,
        tb.sfb_tensor,
        tb.d_tensor,
        tb.amax_tensor,  # None by default
    )

    if not skip_ref_check:
        tb.reference_check()

    # Fresh operands per workspace so ``use_cold_l2`` benchmarking reads
    # from a cold L2. The argument order must match the compiled kernel
    # signature: (A, SFA, B, SFB, D, AMax).
    def generate_tensors():
        workspace_tb = BlockScaledGemmTestbed(
            MNKL=mnkl,
            ab_dtype=ab_dtype,
            d_dtype=d_dtype,
            sf_dtype=sf_dtype,
            sf_vec_size=sf_vec_size,
            a_major=a_major,
            b_major=b_major,
            d_major=d_major,
            compute_amax=compute_amax,
        )
        jit_args = testing.JitArguments(
            workspace_tb.a_tensor,
            workspace_tb.sfa_tensor,
            workspace_tb.b_tensor,
            workspace_tb.sfb_tensor,
            workspace_tb.d_tensor,
            workspace_tb.amax_tensor,
        )
        # Keep the backing Torch tensors alive for the workspace's lifetime.
        jit_args.add_to_scope([workspace_tb])
        return jit_args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            tb.a_ref.numel() * tb.a_ref.element_size()
            + tb.b_ref.numel() * tb.b_ref.element_size()
            + tb.sfa_gpu.numel() * tb.sfa_gpu.element_size()
            + tb.sfb_gpu.numel() * tb.sfb_gpu.element_size()
            + tb.d_gpu.numel() * tb.d_gpu.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_kernel,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Example of Sm100 Dense BlockScaled GEMM."
    )

    cli.add_mnkl_arg(parser, default=(256, 256, 256, 1), strict_length=True)
    cli.add_mma_tiler_arg(
        parser,
        strict_length=True,
        choices=[
            (128, 64),
            (128, 128),
            (128, 192),
            (128, 256),
            (256, 64),
            (256, 128),
            (256, 192),
            (256, 256),
        ],
        help="Mma instruction shape (comma-separated)",
    )
    cli.add_cluster_shape_arg(
        parser,
        strict_length=True,
        help="Physical launch cluster shape (comma-separated), with each "
        "dimension in {1,2,4}. In 2-CTA mode cluster-M must be divisible by 2; "
        "(2,1) is pure selfcast and larger shapes engage TMA multicast.",
    )
    parser.add_argument(
        "--fallback_cluster_shape_mn",
        type=cli.comma_separated_ints_of(2),
        default=None,
        help="Optional physical fallback cluster shape (comma-separated). "
        "When provided and different from --cluster_shape_mn, the kernel is "
        "compiled in mixed-cluster mode. Not supported for mma_inst_mn[1] in "
        "(64, 192) because those codepaths bake the SFB TMA multicast "
        "factor into a host-built atom.",
    )
    cli.add_dtype_args(
        parser,
        ab=cutlass.Float8E4M3FN,
        ab_choices=[cutlass.Float4E2M1FN, cutlass.Float8E4M3FN, cutlass.Float8E5M2],
        acc_choices=[cutlass.Float32],
    )
    parser.add_argument(
        "--sf_dtype",
        type=cutlass.dtype,
        default=cutlass.Float8E8M0FNU,
        choices=[cutlass.Float8E4M3FN, cutlass.Float8E8M0FNU],
    )
    parser.add_argument(
        "--sf_vec_size",
        type=int,
        default=32,
        choices=[16, 32],
    )
    parser.add_argument(
        "--d_dtype",
        type=cutlass.dtype,
        default=cutlass.Float16,
        choices=[
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float32,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ],
    )
    # The output is D rather than C for this kernel.
    cli.add_major_args(parser, c=None)
    parser.add_argument("--d_major", choices=["n", "m"], type=str, default="n")
    parser.add_argument(
        "--compute_amax",
        action="store_true",
        help="Enable optional kernel output param amax:f32=max(|Acc|)>",
    )
    parser.add_argument(
        "--allow_accumulator_overlap",
        action=argparse.BooleanOptionalAction,
        default=True,
        help=(
            "Allow the TMEM planner to use overlapping accumulator ping-pong "
            "(default: enabled)"
        ),
    )
    # The reference check here is exact, so there is no --tolerance to take.
    cli.add_benchmark_args(parser, tolerance=None)

    args = parser.parse_args()

    cli.print_problem_config(
        "Blackwell Dense Block Scaled GEMM",
        args.mnkl,
        lines=[
            f"A: {args.ab_dtype}, B: {args.ab_dtype}, D: {args.d_dtype}, "
            f"Acc dtype: {args.acc_dtype}",
            f"Block scaled MMA with SF: {args.sf_dtype}, "
            f"vector size: {args.sf_vec_size}",
            f"Matrix majors - A: {args.a_major}-major, B: {args.b_major}-major, "
            f"D: {args.d_major}-major",
            f"Mma Tiler (M, N): {args.mma_tiler_mn}, "
            f"Cluster Shape: {args.cluster_shape_mn[0]}x"
            f"{args.cluster_shape_mn[1]}x1",
        ],
    )
    if args.fallback_cluster_shape_mn is not None:
        print(
            f"Fallback Cluster Shape: "
            f"{args.fallback_cluster_shape_mn[0]}x"
            f"{args.fallback_cluster_shape_mn[1]}x1"
        )
    cli.print_benchmark_config(
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
        skip_ref_check=args.skip_ref_check,
        use_cold_l2=args.use_cold_l2,
    )

    if not torch.cuda.is_available():
        parser.exit(3, "error: a GPU is required to run this example\n")

    torch.manual_seed(111)

    try:
        exec_time = run(
            args.mnkl,
            args.mma_tiler_mn,
            args.cluster_shape_mn,
            args.ab_dtype,
            args.sf_dtype,
            args.sf_vec_size,
            args.d_dtype,
            args.acc_dtype,
            args.a_major,
            args.b_major,
            args.d_major,
            compute_amax=args.compute_amax,
            fallback_cluster_shape_mn=args.fallback_cluster_shape_mn,
            allow_accumulator_overlap=args.allow_accumulator_overlap,
            warmup_iterations=args.warmup_iterations,
            iterations=args.iterations,
            skip_ref_check=args.skip_ref_check,
            use_cold_l2=args.use_cold_l2,
        )
    except testing.CantImplementError as e:
        parser.exit(4, f"error: unsupported kernel configuration: {e}\n")
    except AssertionError as e:
        parser.exit(5, f"error: reference check failed: {e}\n")
    except Exception as e:
        parser.exit(6, f"error: {e}\n")

    if args.skip_ref_check:
        print("success: kernel execution finished (reference check skipped).")
    else:
        print("success: kernel execution finished (reference check passed).")
    print(f"Execution time: {exec_time} microseconds per iteration")
