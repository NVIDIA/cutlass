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

import argparse
import os, sys

import torch
from typing import Optional, Type, Tuple, Literal, Callable

import cutlass
from cutlass import core
from cutlass import utils
import cutlass.cute as cute
from cutlass import (
    cute as cute,
    utils as utils,
)

from cutlass.cute.nvgpu import tcgen05
from cutlass.cute.nvgpu.tcgen05.mma import CollectorOp
from cutlass.cute.runtime import from_dlpack

import cutlass.torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.rubin_helpers as sm107_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils

from cutlass.cute import experimental as cute_ext
from cutlass.cute.experimental.pipeline import TMAStorePipeline
from cutlass.cute.experimental.utils import make_t2r_rmem_layout

# Used to fold MMA_M / MMA_N into the atom shape on the accumulator so the
# epilogue sees a flat ``(cta_tile_M, cta_tile_N)`` tile -- required for
# b-reuse where ``MMA_M == 2``.
from cutlass.utils.gemm.sm100 import transform_partitioned_tensor_layout

# Persistent tile scheduler lives in the local ``helpers`` package alongside
# the cute_ext examples (rooted at ``CuTeDSL/``); the cute_ext/<arch>/ files
# add ``CuTeDSL/`` to ``sys.path`` so the import resolves.
if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, ".."))
    sys.path.insert(0, os.path.join(current_dir, "../.."))

from helpers import cli_helper as cli
from helpers.static_persistent_tile_scheduler import (
    PersistentTileSchedulerParams,
    StaticPersistentTileScheduler,
)


"""Dense block-scaled GEMM for Rubin (sm_107), implemented using CuteDSL Extensions.

The kernel structure is duplicated from the Blackwell (sm_100) LIR
implementation in ``cute_ext/blackwell/dense_block_scaled_gemm.py`` -- pipelined
TMA load / MMA / epilogue stages, persistent CTAs, and a tile scheduler that
walks a fixed grid across the whole problem. Rubin-specific deviations are
isolated to a handful of spots, all in ``Sm107BlockScaledDenseGemmKernel``:

* Tiled-MMA construction goes through ``sm107_utils`` (Rubin atoms expose
  collector-op / atom-layout / permutation slots not present in sm_100).
* Epilogue tile selection goes through ``sm107_utils.compute_epilogue_tile_shape``
  (it has FP4-specific entries and falls back to the sm_100 table otherwise).
* ``arch="sm_107"`` selects Rubin's larger SMEM budget.
* The MMA tiler K is supplied separately from the MMA instruction K via
  ``--mma_tiler`` / ``--mma_inst_shape``. For Rubin FP4 the atom's K is 128
  (vs sm_100's 64), so the typical configuration is mma_tiler_k=256 and
  mma_inst_shape_k=128, keeping the per-stage K tile at 256.

The LIR-level operation types (``SM100_MMA_SCALED_*``, ``SM90_TMA_LOAD``,
``cute_ext.dot_block_scaled``, ...) are functionally a superset of what sm_107
needs and are reused as-is here. We expect to share more code with the
Blackwell LIR version once the dust settles -- duplication is intentional for
now.

Initial scope :

- A/B dtype: ``Float4E2M1FN`` only.
- B-reuse: opt-in via ``mma_tiler_m // mma_inst_shape_m == 2``. The MMA
  warp then issues a bkeep / breuse pair per K-block (FILL / LASTUSE
  collector ops on B), sharing one B+SFB load between the two M-halves.
  Setting ``mma_tiler_m == mma_inst_shape_m`` disables it and falls back
  to a single MMA per K-block.
- 1-CTA (``mma_inst_shape_mn[0] == 128``) and 2-CTA
  (``mma_inst_shape_mn[0] == 256``); under 2-CTA the peer pair is implicit
  in the MMA atom and the caller must include it in ``cluster_shape_mn``.
- ``cluster_shape_mn`` is the *raw* launch cluster (peer pair already
  folded in): each dim is a positive power of 2 in ``{1, 2, 4}``, and
  under 2-CTA M is additionally a multiple of ``num_mma_ctas`` (so M >= 2).
  TMA multicast activates whenever the cluster covers more than the
  implicit 2-CTA peer pair (``cluster_m // num_mma_ctas != 1`` or
  ``cluster_n != 1``).

The N in {64, 192} branches are duplicated from the Blackwell LIR rather than
stripped, so that future expansion just relaxes the ``can_implement``
predicate. Until then they sit behind ``cutlass.const_expr`` guards that the
JIT prunes.
"""


class Sm107BlockScaledDenseGemmKernel:
    def __init__(
        self,
        mma_inst_shape: Tuple[int, int, int],
        mma_tiler: Tuple[int, int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        cluster_shape_mn: Tuple[int, int] = (1, 1),
        max_active_clusters: Optional[int] = None,
        epilogue_op=lambda x: x,
        num_load_stages_override: Optional[int] = None,
        num_store_stages_override: Optional[int] = None,
        num_acc_stages_override: Optional[int] = None,
        arch: str = "sm_107",
    ):
        # Optional caps on the pipeline depths. Each, when provided, must be a
        # positive integer and only *lowers* the value ``_compute_stages``
        # derives from the SMEM/TMEM budget (``min(computed, override)``); an
        # override >= the computed depth has no effect.
        for _name, _val in (
            ("num_load_stages_override", num_load_stages_override),
            ("num_store_stages_override", num_store_stages_override),
            ("num_acc_stages_override", num_acc_stages_override),
        ):
            if _val is not None and _val <= 0:
                raise ValueError(f"{_name} must be a positive integer; got {_val}.")
        self.num_load_stages_override = num_load_stages_override
        self.num_store_stages_override = num_store_stages_override
        self.num_acc_stages_override = num_acc_stages_override

        self.a_dtype = a_dtype
        self.b_dtype = b_dtype
        self.acc_dtype = acc_dtype
        self.sf_dtype = sf_dtype
        self.sf_vec_size = sf_vec_size

        # Full ``(M, N, K)`` MMA instruction shape and MMA tiler shape, both
        # supplied by the caller (mirrors the Rubin CuTe DSL signature).
        self.mma_inst_shape = mma_inst_shape
        self.mma_tiler_mnk = mma_tiler
        # Back-compat alias used throughout the kernel body for the M, N
        # components of the MMA instruction shape.
        self.mma_inst_shape_mn = mma_inst_shape[:2]

        # Enable 2-CTA iff mmaAtomM==256
        self.use_2cta_instrs = mma_inst_shape[0] == 256
        self.cta_group = (
            tcgen05.CtaGroup.TWO if self.use_2cta_instrs else tcgen05.CtaGroup.ONE
        )
        self.num_mma_ctas = 2 if self.use_2cta_instrs else 1

        self.cluster_shape_mn = cluster_shape_mn

        self.use_tma_multicast = (
            cluster_shape_mn[0] // self.num_mma_ctas != 1 or cluster_shape_mn[1] != 1
        )

        # ``max_active_clusters`` sets the launch grid's cluster count. Set
        # to the device's capacity for actual persistence; ``None`` falls back
        # to one cluster per tile, collapsing the persistent loop.
        self.max_active_clusters = max_active_clusters

        self.epilogue_op = epilogue_op
        self.arch = utils.sm107.canonicalize_rubin_resource_arch(arch)
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes(self.arch)

        # B-reuse is controlled by ``mma_tiler_m // mma_inst_shape_m``:
        # 1 disables it (one MMA along M), 2 enables it (two MMAs along M
        # sharing the same B / SFB load via FILL / LASTUSE collector ops).
        self.enable_breuse = mma_tiler[0] // mma_inst_shape[0] == 2

        # Workload-dependent attributes filled in by ``_setup_attributes``.
        self.tiled_mma = None
        # B-reuse MMA pair: ``tiled_mma_bkeep`` is the first MMA along M
        # (FILL: keep B for the partner), ``tiled_mma_breuse`` is the second
        # (LASTUSE: consume the kept B). Both share the regular ``tiled_mma``'s
        # MMA inst shape; only the collector ops differ. Built only when
        # ``enable_breuse``; ``None`` otherwise.
        self.tiled_mma_bkeep = None
        self.tiled_mma_breuse = None
        self.cta_tile_shape_mnk = None
        self.epi_tile = None
        self.c_layout = None
        self.c_dtype = None

        # SFB scratch for the N in {64, 192} special cases; built
        # unconditionally but only consumed when
        # ``mma_inst_shape_mn[1] in (64, 192)``.
        self.mma_inst_shape_mn_sfb = None
        self.mma_tiler_sfb = None
        self.tiled_mma_sfb = None
        self.cluster_layout_sfb_vmnk = None

        # Pipeline depths picked by ``_compute_stages`` (clamped by the
        # ``*_override`` caps above). ``num_load_stages`` is the depth of the
        # TMA-load pipeline and sizes the A, B, SFA, and SFB SMEM buffers (one
        # stage carries all four for one K-block).
        self.num_load_stages = None
        self.num_store_stages = None
        self.num_acc_stages = None

    @staticmethod
    def can_implement(
        mnkl: Tuple[int, int, int, int],
        mma_inst_shape: Tuple[int, int, int],
        mma_tiler: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        c_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
    ) -> Optional[str]:
        """Validate a kernel configuration. ``None`` means supported."""
        if a_major not in ("k", "m"):
            return (
                f"A major axis {a_major!r} not supported; expected one of ('k', 'm')."
            )
        if b_major not in ("k", "n"):
            return (
                f"B major axis {b_major!r} not supported; expected one of ('k', 'n')."
            )
        if c_major not in ("n", "m"):
            return (
                f"D major axis {c_major!r} not supported; expected one of ('n', 'm')."
            )

        # ---- Rubin initial-scope restrictions -------------------------------
        if a_dtype is not cutlass.Float4E2M1FN:
            return (
                f"SM107 LIR initial scope: only a_dtype=Float4E2M1FN is "
                f"supported; got {a_dtype}."
            )
        if b_dtype is not cutlass.Float4E2M1FN:
            return (
                f"SM107 LIR initial scope: only b_dtype=Float4E2M1FN is "
                f"supported; got {b_dtype}."
            )
        if mma_inst_shape[0] not in (128, 256):
            return (
                f"SM107 LIR: mma_inst_m must be 128 (1-CTA) or 256 (2-CTA); "
                f"got mma_inst_m={mma_inst_shape[0]}."
            )
        # B-reuse is gated by ``mma_tiler_m // mma_inst_shape_m``: 1 disables
        # it (one MMA along M), 2 enables it (two MMAs along M sharing B/SFB).
        # Mma_tiler_n must match the MMA instruction N (no N-tiling).
        if mma_tiler[0] not in (mma_inst_shape[0], 2 * mma_inst_shape[0]):
            return (
                f"SM107 LIR: mma_tiler_m must equal mma_inst_shape_m (no b-reuse) "
                f"or 2*mma_inst_shape_m (b-reuse enabled); got "
                f"mma_tiler_m={mma_tiler[0]}, mma_inst_shape_m={mma_inst_shape[0]}."
            )
        if mma_tiler[1] != mma_inst_shape[1]:
            return (
                f"SM107 LIR: mma_tiler_n must equal mma_inst_shape_n; got "
                f"mma_tiler_n={mma_tiler[1]}, mma_inst_shape_n={mma_inst_shape[1]}."
            )
        # ``cluster_shape_mn`` is the launch cluster shape (already folds in
        # the 2-CTA peer pair). Each dim must be a positive power of 2 in
        # ``{1, 2, 4}`` (the SF-multicast cap), and under 2-CTA M must be a
        # multiple of ``num_mma_ctas`` (so M >= 2).
        num_mma_ctas = 2 if mma_inst_shape[0] == 256 else 1
        if cluster_shape_mn[0] not in (1, 2, 4) or cluster_shape_mn[1] not in (1, 2, 4):
            return (
                f"Cluster shape {cluster_shape_mn[0]}x{cluster_shape_mn[1]} "
                f"not supported; each dim must be a power of 2 in {{1, 2, 4}} "
                f"(SF multicast caps both dims at 4)."
            )
        if cluster_shape_mn[0] % num_mma_ctas != 0:
            return (
                f"2-CTA (mma_inst_m == 256) requires cluster_shape_mn[0] to be "
                f"a multiple of {num_mma_ctas} (>= 2); got "
                f"cluster_shape_mn[0]={cluster_shape_mn[0]}."
            )
        # ---------------------------------------------------------------------

        # FP4 atom's K is fixed at 128.
        if mma_inst_shape[2] != 128:
            return f"FP4 MMA instruction K must be 128; got {mma_inst_shape[2]}."
        # MMA tiler K must be a positive multiple of the MMA instruction K.
        if mma_tiler[2] <= 0 or mma_tiler[2] % mma_inst_shape[2] != 0:
            return (
                f"mma_tiler_k={mma_tiler[2]} must be a positive multiple of "
                f"mma_inst_shape_k={mma_inst_shape[2]}."
            )

        if mma_inst_shape[1] not in (64, 128, 192, 256):
            return (
                f"MMA instruction N {mma_inst_shape[1]} not supported; "
                f"expected one of (64, 128, 192, 256)."
            )
        # FP4 SF dtype / vec size combos supported by SM107MmaMXF4NVF4Op.
        # TODO: add E5M3 support
        if (sf_dtype, sf_vec_size) not in (
            (cutlass.Float8E4M3FN, 16),
            (cutlass.Float8E4M3FN, 32),
            (cutlass.Float8E8M0FNU, 16),
            (cutlass.Float8E8M0FNU, 32),
        ):
            return (
                f"Unsupported (sf_dtype, sf_vec_size) combination: "
                f"({sf_dtype}, {sf_vec_size}) for FP4; supported combos: "
                f"(Float8E4M3FN/Float8E8M0FNU, 16/32)."
            )
        # FP4 atoms require K-major A/B and N-major D.
        if not (a_major == b_major == "k" and c_major == "n"):
            return (
                f"FP4 block-scaled requires a_major='k', b_major='k', c_major='n'; "
                f"got a_major={a_major!r}, b_major={b_major!r}, c_major={c_major!r}."
            )
        if c_dtype not in (
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float32,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ):
            return (
                f"Output dtype {c_dtype} not supported; "
                f"expected one of (Float16, BFloat16, Float32, "
                f"Float8E4M3FN, Float8E5M2)."
            )
        if acc_dtype != cutlass.Float32:
            return (
                f"Accumulator dtype {acc_dtype} not supported; "
                f"only Float32 is currently implemented."
            )
        return None

    def _get_mma_permutation_mnk(self):
        if cutlass.const_expr(self.use_2cta_instrs and self.enable_breuse):
            m_layout = cute.make_layout(
                shape=(self.mma_inst_shape[0] // 2, 2, 2),
                stride=(1, self.mma_inst_shape[0], self.mma_inst_shape[0] // 2),
            )
            return (m_layout, self.mma_inst_shape[1], self.mma_inst_shape[2])

        else:
            return (1, 1, 1)

    def _setup_attributes(self, mA: cute.Tensor, mB: cute.Tensor, mC: cute.Tensor):
        """Derive workload-dependent state from the bound operand tensors."""
        a_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode()
        b_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(mB).mma_major_mode()

        self.c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(mC)
        self.c_dtype = mC.element_type

        # SM107 MMA atoms take a full ``(M, N, K)`` instruction shape (vs
        # sm_100's ``(M, N)`` signature).
        atom_layout_mnk = (1, 1, 1)
        permutation_mnk = self._get_mma_permutation_mnk()
        self.tiled_mma = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            a_major_mode,
            b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
            atom_layout_mnk=atom_layout_mnk,
            permutation_mnk=permutation_mnk,
        )

        # B-reuse uses a pair of MMAs along M that share the same B / SFB
        # load: the first writes B into the operand collector (FILL), the
        # second reads from that collector (LASTUSE). All other parameters
        # match ``tiled_mma`` so the produced layouts (A/SFA/Acc fragments)
        # line up. Only built when ``enable_breuse``.
        if cutlass.const_expr(self.enable_breuse):
            self.tiled_mma_bkeep = sm107_utils.make_blockscaled_trivial_tiled_mma(
                self.a_dtype,
                self.b_dtype,
                a_major_mode,
                b_major_mode,
                self.sf_dtype,
                self.sf_vec_size,
                self.cta_group,
                self.mma_inst_shape,
                a_collector_op=CollectorOp.DISCARD,
                b_collector_op=CollectorOp.FILL,
                atom_layout_mnk=atom_layout_mnk,
                permutation_mnk=permutation_mnk,
            )
            self.tiled_mma_breuse = sm107_utils.make_blockscaled_trivial_tiled_mma(
                self.a_dtype,
                self.b_dtype,
                a_major_mode,
                b_major_mode,
                self.sf_dtype,
                self.sf_vec_size,
                self.cta_group,
                self.mma_inst_shape,
                a_collector_op=CollectorOp.DISCARD,
                b_collector_op=CollectorOp.LASTUSE,
                atom_layout_mnk=atom_layout_mnk,
                permutation_mnk=permutation_mnk,
            )

        num_mma_ctas = cute.size(self.tiled_mma.thr_id.shape)
        self.cta_tile_shape_mnk = (
            self.mma_tiler_mnk[0] // num_mma_ctas,
            self.mma_tiler_mnk[1],
            self.mma_tiler_mnk[2],
        )

        # SFB needs its own MMA tiler and cluster layout: the SF load granularity
        # is 128 columns of N, so for ``mma_inst_shape_mn[1] in (64, 192)`` the
        # SFB-side N is rounded up to (128, 256); SFB is also replicated across
        # 2-CTA peers rather than split along M. Built unconditionally but only
        # consumed by the special N codepaths.
        self.mma_inst_shape_mn_sfb = (
            self.mma_inst_shape_mn[0] // self.num_mma_ctas,
            cute.round_up(self.mma_inst_shape_mn[1], 128),
        )
        self.mma_tiler_sfb = (
            self.mma_inst_shape_mn_sfb[0],
            self.mma_inst_shape_mn_sfb[1],
            self.mma_tiler_mnk[2],
        )
        sfb_inst_shape_mnk = (
            self.mma_inst_shape_mn_sfb[0],
            self.mma_inst_shape_mn_sfb[1],
            self.mma_inst_shape[2],
        )
        self.tiled_mma_sfb = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            a_major_mode,
            b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            sfb_inst_shape_mnk,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
        )

        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (self.tiled_mma.thr_id.shape,),
        )
        self.cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (self.tiled_mma_sfb.thr_id.shape,),
        )

        # Host-region copy of the epilogue tile, used only for SMEM sizing in
        # ``_compute_stages``. The epilogue (kernel region) rematerializes its
        # own via ``_make_epi_tile`` -- see that method for why it can't be
        # shared.
        self.epi_tile = self._make_epi_tile(self.tiled_mma.op, self.c_layout)

        self._compute_stages()

    def _make_epi_tile(self, tiled_mma_op, c_layout):
        """Select the epilogue tile (Rubin/FP4-aware table, sm_100 fallback).

        Returns a ``cute.Tile`` whose modes are layout SSA values. Because a
        ``@cute.experimental.kernel`` region is isolated-from-above, the tile
        built here in the host (``__call__``) region cannot be passed into the
        kernel -- doing so triggers ``'cute.get_shape' op using value defined
        outside the region``. Instead, both the host (for SMEM sizing) and the
        kernel epilogue call this with region-local inputs (``tiled_mma_op``
        from the kernel arg, ``c_layout`` from the output tensor), so each
        region gets its own materialization of the *same* selection logic.
        """
        return sm107_utils.compute_epilogue_tile_shape(
            tiled_mma_op,
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            c_layout,
            self.c_dtype,
        )

    def _compute_stages(self):
        """Pick TMA-load, TMA-store, and accumulator pipeline depths.

        TMA-load (= A + B + SFA + SFB) and TMA-store (= C) share the SMEM
        budget. Heuristic:

        1. Up to 2 stages of each (double-buffering floor) if budget allows.
        2. Remaining budget flows into TMA-load (carries A+B+SFA+SFB, benefits
           from extra depth more than TMA-store, which carries one C epi
           subtile and is capped at 4).

        Raises ``CantImplementError`` if any pipeline gets zero stages.
        ``num_acc_stages`` lives in TMEM (separate budget): 2 normally,
        dropping to 1 when the per-tile accumulator footprint already fills
        TMEM. That happens at ``mma_inst_shape_mn[1] == 256`` without b-reuse
        and at ``mma_inst_shape_mn[1] in (192, 256)`` with b-reuse (b-reuse
        doubles the accumulator M-extent per tile).
        """
        a_smem_layout_one = sm100_utils.make_smem_layout_a(
            self.tiled_mma, self.mma_tiler_mnk, self.a_dtype, 1
        )
        b_smem_layout_one = sm100_utils.make_smem_layout_b(
            self.tiled_mma, self.mma_tiler_mnk, self.b_dtype, 1
        )
        sfa_smem_layout_one = blockscaled_utils.make_smem_layout_sfa(
            self.tiled_mma, self.mma_tiler_mnk, self.sf_vec_size, 1
        )
        sfb_smem_layout_one = blockscaled_utils.make_smem_layout_sfb(
            self.tiled_mma, self.mma_tiler_mnk, self.sf_vec_size, 1
        )
        c_smem_layout_one = sm100_utils.make_smem_layout_epi(
            self.c_dtype, self.c_layout, self.epi_tile, 1
        )

        costs = {
            "tma": cute.size_in_bytes(self.a_dtype, a_smem_layout_one)
            + cute.size_in_bytes(self.b_dtype, b_smem_layout_one)
            + cute.size_in_bytes(self.sf_dtype, sfa_smem_layout_one)
            + cute.size_in_bytes(self.sf_dtype, sfb_smem_layout_one),
            "c": cute.size_in_bytes(self.c_dtype, c_smem_layout_one),
        }

        reserved_bytes = 1024
        budget = self.smem_capacity - reserved_bytes

        # Phase 1: 1:1 floor (up to 2 of each).
        n = min(2, budget // sum(costs.values()))
        counts = {p: n for p in costs}
        budget -= n * sum(costs.values())

        # Phase 2: as many main stages as possible.
        n = budget // costs["tma"]
        counts["tma"] += n
        budget -= n * costs["tma"]

        # Phase 3: remaining budget flows into D (capped at 4 total).
        n = min(4 - counts["c"], budget // costs["c"])
        counts["c"] += n
        budget -= n * costs["c"]

        if min(counts.values()) < 1:
            raise cutlass.testing.CantImplementError(
                f"Insufficient SMEM: at least one pipeline has zero stages. "
                f"budget={self.smem_capacity - reserved_bytes} B, "
                f"per-stage={costs}."
            )

        tmem_full = self.mma_inst_shape_mn[1] == 256 or (
            self.enable_breuse and self.mma_inst_shape_mn[1] == 192
        )

        # Budget-derived depths, before any user override.
        computed_load = counts["tma"]
        computed_store = counts["c"]
        computed_acc = 1 if tmem_full else 2

        # Apply the optional ``*_override`` caps: an override only *lowers* the
        # depth (``min``); an override >= the computed value has no effect.
        def _apply_override(computed, override):
            return min(computed, override) if override is not None else computed

        self.num_load_stages = _apply_override(
            computed_load, self.num_load_stages_override
        )
        self.num_store_stages = _apply_override(
            computed_store, self.num_store_stages_override
        )
        self.num_acc_stages = _apply_override(
            computed_acc, self.num_acc_stages_override
        )

        def _depth_str(final, computed):
            return (
                f"{final} (computed {computed}, capped by override)"
                if final != computed
                else f"{final}"
            )

        print(
            f"[LIR DSL LOG] "
            f"Number of a/b/sfa/sfb load stages: "
            f"{_depth_str(self.num_load_stages, computed_load)}, "
            f"Number of store stages in epilogue: "
            f"{_depth_str(self.num_store_stages, computed_store)}, "
            f"Number of Acc stages in TMEM: "
            f"{_depth_str(self.num_acc_stages, computed_acc)}"
        )

    def _mainloop_s2t_copies(
        self,
        stage_idx: int,
        tiled_copy_s2t_sfa: cute.TiledCopy,
        filtered_smem_sfa: cute.Tensor,
        tmem_sfa_compact: cute.Tensor,
        tiled_copy_s2t_sfb: cute.TiledCopy,
        filtered_smem_sfb: cute.Tensor,
        tmem_sfb_compact: cute.Tensor,
    ):
        """
        Stage SFA / SFB from smem into tmem for one load-pipeline stage.

        ``partition_and_copy`` partitions both operands with the tiled copy's TV
        layouts and emits the copy. The x4 broadcast mode the smem operand needs to
        partition consistently with tmem is added there, and the smem descriptor the
        copy needs is materialized when lowering, so neither is built here.

        The copies are issued by a single agent (thread 0 of the tiled copy); the
        caller is responsible for restricting them to the MMA warp.

        :param stage_idx: Load-pipeline stage index to read the scale factors from
        :type stage_idx: int
        :param tiled_copy_s2t_sfa: The smem to tmem tiled copy for SFA
        :type tiled_copy_s2t_sfa: cute.TiledCopy
        :param filtered_smem_sfa: Zero-filtered, staged SFA tensor in smem
        :type filtered_smem_sfa: cute.Tensor
        :param tmem_sfa_compact: Zero-filtered SFA tensor in tmem, the copy destination
        :type tmem_sfa_compact: cute.Tensor
        :param tiled_copy_s2t_sfb: The smem to tmem tiled copy for SFB
        :type tiled_copy_s2t_sfb: cute.TiledCopy
        :param filtered_smem_sfb: Zero-filtered, staged SFB tensor in smem
        :type filtered_smem_sfb: cute.Tensor
        :param tmem_sfb_compact: Zero-filtered SFB tensor in tmem, the copy destination
        :type tmem_sfb_compact: cute.Tensor
        """
        # (MMA, MMA_MN, MMA_K, STAGE) sliced down to (MMA, MMA_MN, MMA_K)
        s2t_stage_coord = (
            None,
            None,
            None,
            stage_idx,
        )

        cute_ext.partition_and_copy(
            tiled_copy_s2t_sfa.get_slice(cute.Int32(0)),
            filtered_smem_sfa[s2t_stage_coord],
            tmem_sfa_compact,
        )
        cute_ext.partition_and_copy(
            tiled_copy_s2t_sfb.get_slice(cute.Int32(0)),
            filtered_smem_sfb[s2t_stage_coord],
            tmem_sfb_compact,
        )

    @cute.experimental.jit
    def epilogue_tma_store(
        self,
        epi_tile: cute.Tile,
        cta_tile_shape_mnk: cute.Shape,
        use_2cta_instrs: bool,
        tmem_acc_buffer_staged: cute.Tensor,
        gmem_c: cute.Tensor,
        cta_c_tile_coord: cute.Coord,
        tma_store_pipeline: TMAStorePipeline,
        tma_store_warp_id: int,
        epilogue_op: Callable[[cute.Tensor], cute.Tensor],
        c_major_mode: Optional[cutlass.tensor_utils.LayoutEnum] = None,
        tid_x_in_group: Optional[int] = None,
    ) -> TMAStorePipeline:
        """
        Epilogue phase: copy accumulator from TMEM to GMEM via RMEM and TMA store.

        This function implements the epilogue for GEMM on Blackwell (SM100): it consumes
        the accumulator produced by the MMA warp and writes the output tile to global
        memory. The data flow is:

            TMEM --copy--> RMEM --epilogue op--> RMEM --copy--> SMEM --TMA--> GMEM

        The TMA store pipeline coordinates multiple warps writing to SMEM before a single
        warp (tma_store_warp_id) issues the TMA store. Pipeline protocol per sub-tile:
        acquire_sync() -> RMEM->SMEM copy -> commit_sync() -> TMA store (TMA warp only)
        -> release_advance(). tail() is called at the end to wait for in-flight TMA stores.

        Args:
            epi_tile: Epilogue tile provided to be used.
            cta_tile_shape_mnk: Effective (M, N, K) tile shape per CTA for epilogue tiling
            use_2cta_instrs: True if using 2-CTA MMA instructions (affects epilogue tile shape)
            tmem_acc_buffer_staged: One stage slice from the full accumulator pipeline for
                this CTA's tile, should have shape
                (cta_tile_shape_mnk[0], cta_tile_shape_mnk[1], 1, 1)
            gmem_c: Global output tensor C
            cta_c_tile_coord: Coordinate of this CTA's output tile, e.g. (cta_m, cta_n, cta_l)
            tma_store_pipeline: TMAStorePipeline instance
            tma_store_warp_id: Warp index that issues TMA stores
            epilogue_op: Callable applied in registers to accumulator values before store
            c_major_mode: LayoutEnum for d_tensor, the function will automatically detect
                the c_major_mode from gmem_c if not provided
            tid_x_in_group: Thread index in the group of warps that issue TMA stores. For
                example, if warps 4-7 are in the same group and calling this function,
                tid_x_in_group should be 0-127 instead of 128-255. If not provided, the
                function will use cute.arch.thread_idx().

        Returns:
            tma_store_pipeline: The updated TMAStorePipeline instance
        """
        from cutlass.cute.experimental.algorithm import partition_and_copy
        from cutlass.cute.experimental.memory import allocate, tma_store
        import cutlass.utils.blackwell_helpers as blackwell_helpers
        from cutlass import utils as utils

        if cutlass.const_expr(tid_x_in_group is None):
            tid_x_in_group, _, _ = cute.arch.thread_idx()
            tid_x_in_group = tid_x_in_group % 128
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        acc_dtype = tmem_acc_buffer_staged.element_type
        c_dtype = gmem_c.element_type
        if cutlass.const_expr(c_major_mode is None):
            c_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(gmem_c)

        copy_atom_t2r = blackwell_helpers.get_tmem_load_op(
            cta_tile_shape_mnk,
            c_major_mode,
            c_dtype,
            acc_dtype,
            epi_tile,
            use_2cta_instrs,
        )

        # acc_epi_div_tiled: (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N)
        acc_epi_div_tiled = cute.flat_divide(tmem_acc_buffer_staged, epi_tile)

        # acc_epi_div_tiled_grouped: (EPI_TILE_M, EPI_TILE_N, (EPI_M, EPI_N))
        acc_epi_div_tiled_grouped = cute.group_modes(acc_epi_div_tiled, 2, 4)

        acc_epi_div_slice = acc_epi_div_tiled_grouped[None, None, 0]

        tiled_copy_t2r = cute.nvgpu.tcgen05.make_tmem_copy(
            copy_atom_t2r, acc_epi_div_slice
        )
        tiled_copy_r2s = cute.make_tiled_copy_D(
            cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), c_dtype),
            tiled_copy_t2r,
        )

        assert isinstance(cta_tile_shape_mnk, tuple)
        # tiler_mn: (CTA_ATOM_M, CTA_ATOM_N)
        tiler_mn = (cta_tile_shape_mnk[0], cta_tile_shape_mnk[1])
        # gmem_c_mn_tiled: (((CTA_ATOM_M, CTA_ATOM_N)), (REST_M, REST_N, REST_L))
        gmem_c_mn_tiled = cute.zipped_divide(gmem_c, tiler_mn)

        # gmem_c_tile: (CTA_ATOM_M, CTA_ATOM_N)
        gmem_c_tile = gmem_c_mn_tiled[(None, None), cta_c_tile_coord]

        # gmem_c_epi_tma: (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N)
        gmem_c_epi_tma = cute.flat_divide(gmem_c_tile, epi_tile)  # type: ignore[arg-type]

        # gmem_c_epi_tma_grouped: (EPI_TILE_M, EPI_TILE_N, (EPI_M, EPI_N))
        gmem_c_epi_tma_grouped = cute.group_modes(gmem_c_epi_tma, 2, 4)

        # epi_subtile_cnt = EPI_M x EPI_N
        epi_subtile_cnt = cute.product_each(gmem_c_epi_tma_grouped.shape)[2]

        acc_c_rmem_layout = make_t2r_rmem_layout(
            tiled_copy_t2r,
            gmem_c_epi_tma,
            tid_x_in_group,  # type: ignore[arg-type]
        )
        rmem_acc_buffer = allocate(
            acc_dtype,
            cutlass.AddressSpace.rmem,
            acc_c_rmem_layout,
            alignment=32,
        )
        rmem_c_buffer = allocate(
            c_dtype,
            cutlass.AddressSpace.rmem,
            acc_c_rmem_layout,
            alignment=32,
        )

        c_smem_layout_staged = blackwell_helpers.make_smem_layout_epi(
            c_dtype,
            c_major_mode,
            epi_tile,
            tma_store_pipeline.get_num_stages(),
        )
        smem_c_buffer = allocate(
            c_dtype,
            cutlass.AddressSpace.smem,
            c_smem_layout_staged,
            alignment=1024,
        )

        for epi_subtile_idx in range(epi_subtile_cnt):  # type: ignore[arg-type]
            # TMEM -> RMEM
            partition_and_copy(
                tiled_copy_t2r.get_slice(tid_x_in_group),
                acc_epi_div_tiled_grouped[None, None, epi_subtile_idx],
                rmem_acc_buffer,
            )

            # RMEM -> RMEM and epilogue Op
            acc_vec = rmem_acc_buffer.load()

            epilogue_out = epilogue_op(acc_vec.to(c_dtype))
            rmem_c_buffer.store(epilogue_out)

            # RMEM -> SMEM
            # The TMA store pipeline coordinates multiple warps writing to SMEM
            # before a single warp issues the TMA store.
            # acquire_sync():
            # - TMA warp waits for any in-flight TMA ops to complete
            # - All warps synchronize via a named barrier
            tma_store_pipeline.acquire_sync()
            store_idx = tma_store_pipeline.get_index()
            partition_and_copy(
                tiled_copy_r2s.get_slice(tid_x_in_group),
                rmem_c_buffer,
                smem_c_buffer[None, None, store_idx],
            )

            # commit_sync():
            # - Fences SMEM writes to ensure visibility for TMA
            # - All warps synchronize before TMA store
            # This is CRITICAL: TMA must see committed SMEM writes
            tma_store_pipeline.commit_sync()

            # SMEM -> GMEM
            if warp_idx == tma_store_warp_id:
                tma_store(
                    smem_c_buffer[None, None, store_idx],
                    gmem_c_epi_tma_grouped[None, None, epi_subtile_idx],
                )

            # release_advance():
            # - TMA warp commits TMA ops to bulk group
            # - All warps advance to the next pipeline stage
            tma_store_pipeline.release_advance()

        tma_store_pipeline.tail()
        return tma_store_pipeline

    @cute.experimental.jit
    def __call__(
        self,
        mA: cute.Tensor,
        mSFA: cute.Tensor,
        mB: cute.Tensor,
        mSFB: cute.Tensor,
        mC: cute.Tensor,
    ):
        self._setup_attributes(mA, mB, mC)

        # Reinterpret the flat SFA / SFB tensors with block-scaled layouts that
        # tile the same way as A / B.
        # SFA: ((Atom_M, Rest_M), (Atom_K, Rest_K), RestL)
        sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(mA.shape, self.sf_vec_size)
        sfa_tensor = cute.make_tensor(mSFA.iterator, sfa_layout)

        # SFB: ((Atom_N, Rest_N), (Atom_K, Rest_K), RestL)
        sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(mB.shape, self.sf_vec_size)
        sfb_tensor = cute.make_tensor(mSFB.iterator, sfb_layout)

        # Persistent tile scheduler. Computes the launch grid and the scheduler
        # params that ``kernel`` uses to walk per-CTA tile coords, so each CTA
        # can process multiple tiles in sequence.
        cluster_shape = (*self.cluster_shape_mn, 1)
        num_ctas_mnl = (
            cute.ceil_div(mC.layout.shape[0], self.cta_tile_shape_mnk[0]),
            cute.ceil_div(mC.layout.shape[1], self.cta_tile_shape_mnk[1]),
            mC.layout.shape[2],
        )
        tile_sched_params = PersistentTileSchedulerParams(num_ctas_mnl, cluster_shape)

        # Cluster count of the launch grid: device-queried capacity (actual
        # persistence) when set, otherwise enough clusters to cover the whole
        # problem (collapses to non-persistent).
        if cutlass.const_expr(self.max_active_clusters is not None):
            max_active_clusters = self.max_active_clusters
        else:
            max_active_clusters = (
                cute.ceil_div(num_ctas_mnl[0], self.cluster_shape_mn[0])
                * cute.ceil_div(num_ctas_mnl[1], self.cluster_shape_mn[1])
                * num_ctas_mnl[2]
            )
        grid = StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )

        self.kernel(
            self.tiled_mma,
            self.tiled_mma_bkeep,
            self.tiled_mma_breuse,
            mA,
            sfa_tensor,
            mB,
            sfb_tensor,
            mC,
            self.tiled_mma_sfb,
            self.cluster_layout_vmnk,
            self.cluster_layout_sfb_vmnk,
            tile_sched_params,
        ).launch(
            grid=grid,
            # 6 warps total (= 192 threads):
            #   * 1x tma_load (issues A/B/SFA/SFB, commits tma_pipe)
            #   * 1x mma
            #   * 4x epilogue (one of which doubles as the tma_store warp)
            block=(192, 1, 1),
            cluster=cluster_shape,
            smem=self.smem_capacity,
        )

    @cute.experimental.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        # B-reuse pair (FILL / LASTUSE collector ops). ``None`` when
        # ``enable_breuse`` is False; consumed only by the b-reuse codepath
        # in the MMA mainloop below.
        tiled_mma_bkeep: Optional[cute.TiledMma],
        tiled_mma_breuse: Optional[cute.TiledMma],
        mA: cute.Tensor,
        mSFA: cute.Tensor,
        mB: cute.Tensor,
        mSFB: cute.Tensor,
        mC: cute.Tensor,
        tiled_mma_sfb: cute.TiledMma,
        cluster_layout_vmnk: cute.Layout,
        cluster_layout_sfb_vmnk: cute.Layout,
        # Persistent tile scheduler params; necessary because the launch grid no
        # longer maps 1:1 to problem tiles.
        tile_sched_params: PersistentTileSchedulerParams,
    ):
        # Prologue: shared per-CTA setup before the per-warp loops.
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        # Cluster layout for 2-CTA coordination. Degenerates to a trivial layout
        # (v-mode size 1) for 1-CTA, which makes the 2-CTA-specific code below
        # correctly turn into no-ops.

        cluster_layout_v_size = cute.size(cluster_layout_vmnk.shape[0])
        # ``mma_tile_coord_v`` (and ``is_leader_cta``) is CTA-invariant: depends
        # only on the CTA's index within its cluster, not on which tile it is
        # currently processing. Compute once here.
        bidx, _, _ = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cluster_layout_v_size
        is_leader_cta = mma_tile_coord_v == 0

        a_tiler_mk = (self.mma_tiler_mnk[0], self.mma_tiler_mnk[2])
        b_tiler_nk = (self.mma_tiler_mnk[1], self.mma_tiler_mnk[2])
        sfb_tiler_nk = (self.mma_tiler_sfb[1], self.mma_tiler_sfb[2])

        gA = cute.zipped_divide(mA, a_tiler_mk)
        gB = cute.zipped_divide(mB, b_tiler_nk)
        gSFA = cute.zipped_divide(mSFA, a_tiler_mk)
        gSFB = cute.zipped_divide(mSFB, sfb_tiler_nk)

        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        thr_mma_sfb = tiled_mma_sfb.get_slice(mma_tile_coord_v)

        # Shared memory layouts for A/B/SFA/SFB/D. A, B, SFA, and SFB share
        # the TMA-load pipeline's depth (``num_stages``).
        a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma, self.mma_tiler_mnk, self.a_dtype, self.num_load_stages
        )
        b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma, self.mma_tiler_mnk, self.b_dtype, self.num_load_stages
        )
        sfa_smem_layout_staged = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma, self.mma_tiler_mnk, self.sf_vec_size, self.num_load_stages
        )
        sfb_smem_layout_staged = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma, self.mma_tiler_mnk, self.sf_vec_size, self.num_load_stages
        )

        # UMMA ACC TMEM Layout
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler_mnk[:2])
        tmem_accs_layout = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stages)
        ).layout

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

        buffer_smem_a = cute_ext.allocate(
            self.a_dtype,
            cutlass.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )
        buffer_smem_b = cute_ext.allocate(
            self.b_dtype,
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

        # ``is2cta`` tells the allocator to reserve "wide" TMEM addressable
        # across both peers. For 1-CTA it is a no-op.
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

        # Make S2T CopyAtom and tiledCopy for the scale factors. The copy is
        # co-tiled against the zero-filtered tmem layout, which is also what the
        # copy writes into, so keep the compact views around for the mainloop.
        # (MMA, MMA_MN, MMA_K)
        buffer_tmem_sfa_compact = cute.filter_zeros(buffer_tmem_sfa)
        buffer_tmem_sfb_compact = cute.filter_zeros(buffer_tmem_sfb)

        copy_atom_s2t = cute.make_copy_atom(
            tcgen05.Cp4x32x128bOp(self.cta_group),
            self.sf_dtype,
        )
        tiled_copy_s2t_sfa = tcgen05.make_s2t_copy(
            copy_atom_s2t, buffer_tmem_sfa_compact
        )
        tiled_copy_s2t_sfb = tcgen05.make_s2t_copy(
            copy_atom_s2t, buffer_tmem_sfb_compact
        )

        # Pick MMA / TMA op types from CtaGroup and whether we need multicast.
        # SM107 reuses the SM100 LIR op types since the underlying tcgen05
        # instructions are a functional superset.
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

        if cutlass.const_expr(self.use_2cta_instrs):
            sfb_tma_operation_type = (
                cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST
            )
        elif cutlass.const_expr(cute.size(cluster_layout_sfb_vmnk.shape[1]) > 1):
            sfb_tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD_MULTICAST
        else:
            sfb_tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD

        tma_mcast_proj_a = 2
        tma_mcast_proj_b = 1

        # TMA -> UMMA pipeline. The producer warp issues A, B, SFA, and SFB
        # against the same mbar per K-tile so the mbar's expect_tx accumulates
        # each load's bytes; the consumer acquires once per K-tile and sees all
        # four buffers ready together.
        tma_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=self.num_load_stages,
            mma_operation_type=mma_operation_type,
            tma_operation_type=tma_operation_type,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # UMMA -> tcgen05.ld. For 2-CTA both peers' epilogue warpgroups call
        # ``consumer_release``, so the arrive count doubles.
        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=self.num_acc_stages,
            mma_operation_type=mma_operation_type,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=256 if self.use_2cta_instrs else 128,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # warp assignment: [0]-tma_store, [0-3]-epi, [4]-mma, [5]-tma_load.
        tma_store_warp_id = 0
        mma_warp_id = 4
        tma_load_warp_id = 5
        is_tma_load_warp = warp_idx == tma_load_warp_id
        is_mma_warp = warp_idx == mma_warp_id
        is_epi_warp = warp_idx < 4

        # st.shared -> TMA store
        tma_store_pipe = cute_ext.TMAStorePipeline(
            stages=self.num_store_stages,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=tma_store_warp_id,
        )

        k_tile_size = cute.size(gA, mode=[1, 1])

        if is_tma_load_warp:
            tile_sched = StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            while work_tile.is_valid_tile:
                cta_m, cta_n, cta_l = work_tile.tile_idx

                mma_tile_coord_m = cta_m // cluster_layout_v_size
                gA_tile = gA[(None, None), (mma_tile_coord_m, None, cta_l)]
                gB_tile = gB[(None, None), (cta_n, None, cta_l)]
                gSFA_tile = gSFA[(None, None), (mma_tile_coord_m, None, cta_l)]

                tAgA_tile = thr_mma.partition_A(gA_tile)
                tBgB_tile = thr_mma.partition_B(gB_tile)
                tAgSFA_tile = thr_mma.partition_A(gSFA_tile)
                sfb_n_coord = cta_n
                if cutlass.const_expr(self.mma_inst_shape_mn[1] == 64):
                    # cta_n = 0 and 1 uses N 0-63 and 64-127, respectively.
                    # SFB N tile size is rounded up to 128, both ctas use the same tile.
                    sfb_n_coord = cta_n // 2
                if cutlass.const_expr(self.mma_inst_shape_mn[1] == 192):
                    # cta_n = 0 uses N 0-191 and it's rounded up to 0-255.
                    # cta_n = 1 uses N 192-383 and it's rounded up to 128-383.
                    # The cta_n-to-sfb_n_coord mapping is:
                    #    cta_n: 0, 1,   2,   3, ...
                    #    sfb_n: 0, 128, 384, 512, ...
                    sfb_block_coord = 3 * (cta_n // 2) + cta_n % 2
                    mSFB_offset = core.domain_offset(
                        mSFB,
                        (
                            cute.assume(sfb_block_coord * 128, divby=128),
                            0,
                            0,
                        ),
                    )
                    gSFB_offset = cute.zipped_divide(mSFB_offset, sfb_tiler_nk)
                    gSFB_tile = gSFB_offset[(None, None), (0, None, cta_l)]
                else:
                    gSFB_tile = gSFB[(None, None), (sfb_n_coord, None, cta_l)]
                tBgSFB_tile = thr_mma_sfb.partition_B(gSFB_tile)

                for k_tile_idx in cutlass.range(0, k_tile_size, 1, unroll=1):
                    gA_k = tAgA_tile[(None, None, None, k_tile_idx)]
                    gB_k = tBgB_tile[(None, None, None, k_tile_idx)]
                    gSFA_k = tAgSFA_tile[(None, None, None, k_tile_idx)]
                    gSFB_k = tBgSFB_tile[(None, None, None, k_tile_idx)]

                    tma_producer_token, stage_idx = (
                        tma_pipe.producer_acquire_and_get_stage()
                    )
                    tma_mbar = cute_ext.get_mbarrier(tma_producer_token)
                    buffer_smem_a_stage = buffer_smem_a[None, None, None, stage_idx]
                    buffer_smem_b_stage = buffer_smem_b[None, None, None, stage_idx]
                    buffer_smem_sfa_stage = buffer_smem_sfa[None, None, None, stage_idx]
                    buffer_smem_sfb_stage = buffer_smem_sfb[None, None, None, stage_idx]

                    cute_ext.tma_load(
                        gA_k,
                        buffer_smem_a_stage,
                        tma_mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_a,
                    )
                    cute_ext.tma_load(
                        gB_k,
                        buffer_smem_b_stage,
                        tma_mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_b,
                    )
                    cute_ext.tma_load(
                        gSFA_k,
                        buffer_smem_sfa_stage,
                        tma_mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_a,
                        internal_type=cutlass.Int16,
                    )
                    cute_ext.tma_load(
                        gSFB_k,
                        buffer_smem_sfb_stage,
                        tma_mbar,
                        vmnk_layout=cluster_layout_sfb_vmnk,
                        tma_operation_type=sfb_tma_operation_type,
                        multicast_mode=tma_mcast_proj_b,
                        internal_type=cutlass.Int16,
                    )

                    tma_pipe.producer_commit_and_advance()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            # Drain pending ``tma_pipe`` stages on shutdown.
            tma_pipe.producer_tail()

        if is_mma_warp and is_leader_cta:
            # MMA consumer warp. Consumes tma_pipe (A, B, SFA, SFB), produces
            # acc_pipe (accumulators) for the epilogue. Only the leader CTA in
            # 2-CTA mode issues the MMA -- peer's TMEM is addressed via the
            # leader's mbar.
            #
            # B-reuse: instead of one MMA per K-block, issue a pair (bkeep
            # then breuse) that shares one B / SFB load via the operand
            # collector. ``tiled_mma_bkeep`` uses ``b_collector_op=FILL`` to
            # stash B; ``tiled_mma_breuse`` uses ``LASTUSE`` to consume it.
            # Non-breuse path keeps the single-MMA structure.
            if cutlass.const_expr(self.enable_breuse):
                mma_atom_bkeep = cute.make_mma_atom(tiled_mma_bkeep.op)
                mma_atom_breuse = cute.make_mma_atom(tiled_mma_breuse.op)
            else:
                mma_atom = cute.make_mma_atom(tiled_mma.op)

            # Copy sources must be compact; the zero-filtered views are
            # stage-invariant, so build them once outside the persistent loop.
            # (MMA, MMA_MN, MMA_K, STAGE)
            filtered_buffer_smem_sfa = cute.filter_zeros(buffer_smem_sfa)
            filtered_buffer_smem_sfb = cute.filter_zeros(buffer_smem_sfb)

            tile_sched = StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            while work_tile.is_valid_tile:
                _, cta_n, _ = work_tile.tile_idx

                # Acquire one acc_pipe stage per tile; the buffer rotates
                # through ``num_acc_stages`` slots so the epi warps can drain
                # stage N-1 while we produce stage N.
                _, acc_stage_idx = acc_pipe.producer_acquire_and_get_stage()

                # buffer_tmem_accs: ((MMA_ATOM_M, MMA_ATOM_N), MMA_M, MMA_N, STAGE)
                accumulators_sliced = buffer_tmem_accs[None, None, None, acc_stage_idx]
                # accumulators_sliced: ((MMA_ATOM_M, MMA_ATOM_N), MMA_M, MMA_N)

                # First MMA of each tile overwrites the accumulator rather than
                # adding to it; flipped to True after the first inner-loop
                # iteration below.
                if cutlass.const_expr(self.enable_breuse):
                    mma_atom_bkeep.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)
                    mma_atom_breuse.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)
                else:
                    mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)

                # N=64 / N=192 consumer-side demux. SFB SMEM/TMEM are 128-wide
                # for N=64 and 256-wide for N=192; each MMA only consumes
                # ``mma_inst_shape_mn[1]`` of those. Two consecutive N tiles
                # share one SF load, so odd N tiles read SFB starting two
                # TMEM columns later. Offset is in 32-bit cells and depends on
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

                for _ in cutlass.range(0, k_tile_size, 1, unroll=1):
                    _, idx = tma_pipe.consumer_wait_and_get_stage()

                    buffer_smem_a_sliced_stage = buffer_smem_a[(None, None, None, idx)]
                    buffer_smem_b_sliced_stage = buffer_smem_b[(None, None, None, idx)]

                    self._mainloop_s2t_copies(
                        idx,
                        tiled_copy_s2t_sfa,
                        filtered_buffer_smem_sfa,
                        buffer_tmem_sfa_compact,
                        tiled_copy_s2t_sfb,
                        filtered_buffer_smem_sfb,
                        buffer_tmem_sfb_compact,
                    )

                    # Issue ``mma_tiler_k // mma_inst_shape_k`` MMAs over the
                    # K-blocks packed into this SMEM stage. With b-reuse the
                    # ``mma_tiler_m == 2 * mma_inst_shape_m``, so SMEM/TMEM
                    # layouts carry an extra MMA_M=2 dimension; we slice it
                    # to feed the bkeep / breuse pair (both share B and SFB).
                    for k_block_idx in cutlass.range(
                        self.mma_tiler_mnk[2] // self.mma_inst_shape[2],
                        unroll_full=True,
                    ):
                        if cutlass.const_expr(self.enable_breuse):
                            a_kblk_crd_keep = (None, 0, k_block_idx)
                            a_kblk_crd_reuse = (None, 1, k_block_idx)
                            b_kblk_crd = (None, 0, k_block_idx)

                            # MMA_M select. A / Acc carry MMA_M as an *outer*
                            # mode (mode 1 of the post-stage-slice view), so
                            # slice it directly with 0 / 1. SFA hides the
                            # MMA_M dimension inside mode 0's hierarchical
                            # structure, so we pick the M-half via the inner
                            # index instead -- mode 1 must stay ``None``,
                            # otherwise the slice drops to rank 1 and the
                            # downstream ``group_modes(0, 2)`` fails with a
                            # ``cute.slice`` rank mismatch.
                            # bkeep: MMA_M=0 (writes B to operand collector).
                            cute_ext.dot_block_scaled(
                                mma_atom_bkeep,
                                buffer_smem_a_sliced_stage[a_kblk_crd_keep],
                                buffer_tmem_sfa[a_kblk_crd_keep],
                                buffer_smem_b_sliced_stage[b_kblk_crd],
                                buffer_tmem_sfb_for_mma[b_kblk_crd],
                                cute.append_ones(
                                    accumulators_sliced[None, 0, 0], up_to_rank=3
                                ),
                            )
                            mma_atom_bkeep.set(
                                cute.nvgpu.tcgen05.Field.ACCUMULATE, True
                            )

                            # breuse: MMA_M=1 (reads B from operand collector).
                            cute_ext.dot_block_scaled(
                                mma_atom_breuse,
                                buffer_smem_a_sliced_stage[a_kblk_crd_reuse],
                                buffer_tmem_sfa[a_kblk_crd_reuse],
                                buffer_smem_b_sliced_stage[b_kblk_crd],
                                buffer_tmem_sfb_for_mma[b_kblk_crd],
                                cute.append_ones(
                                    accumulators_sliced[None, 1, 0], up_to_rank=3
                                ),
                            )
                            mma_atom_breuse.set(
                                cute.nvgpu.tcgen05.Field.ACCUMULATE, True
                            )
                        else:
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
                                    buffer_tmem_sfa[
                                        (None, (None, 0)), None, k_block_idx
                                    ],
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
                                cute.append_ones(
                                    accumulators_sliced[None, 0, 0], up_to_rank=3
                                ),
                                # accumulators_sliced,
                            )
                            mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)

                    tma_pipe.consumer_release_and_advance()

                acc_pipe.producer_commit_and_advance()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            # Drain pending ``acc_pipe`` stages on shutdown.
            acc_pipe.producer_tail()

        if is_epi_warp:
            # Epilogue warps (4 of them). Pure consumer of ``acc_pipe``, pure
            # producer of ``tma_store_pipe``; ``epilogue_tma_store``
            # below drains the store pipe via its own ``tail()``.
            tile_sched = StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            # Reorganize the accumulator's TMEM layout from
            # ``((MMA_ATOM_M, MMA_ATOM_N), MMA_M, MMA_N, STAGE)`` to
            # ``((MMA_ATOM_M, MMA_M), (MMA_ATOM_N, MMA_N), STAGE)``: the inner
            # tile-along-M / tile-along-N modes are folded into the atom
            # shape, so a per-stage slice is a flat ``(cta_tile_M,
            # cta_tile_N)`` tensor regardless of MMA_M / MMA_N. Without this,
            # b-reuse (``MMA_M == 2``) would silently drop the second M-half
            # because slicing ``MMA_M=0`` only keeps the bkeep result.
            buffer_tmem_accs_view = transform_partitioned_tensor_layout(
                buffer_tmem_accs
            )

            # Rematerialize the epilogue tile inside the kernel region (it
            # cannot be shared from ``self.epi_tile``; see ``_make_epi_tile``).
            # ``tiled_mma`` is a kernel arg and ``mC`` is the output tensor, so
            # both inputs are region-local.
            epi_tile = self._make_epi_tile(
                tiled_mma.op, cutlass.tensor_utils.LayoutEnum.from_tensor(mC)
            )

            while work_tile.is_valid_tile:
                cta_m, cta_n, cta_l = work_tile.tile_idx

                _, acc_stage_idx = acc_pipe.consumer_wait_and_get_stage()
                # ((MMA_ATOM_M, MMA_M), (MMA_ATOM_N, MMA_N)) == (cta_tile_M,
                # cta_tile_N) after the layout reorg above.
                tmem_acc_stage = buffer_tmem_accs_view[None, None, acc_stage_idx]
                cta_c_tile_coord = (cta_m, cta_n, cta_l)

                # Quantize the accumulator, apply ``epilogue_op``, and
                # TMA-store the result to D.
                tma_store_pipe = self.epilogue_tma_store(
                    epi_tile,
                    self.cta_tile_shape_mnk,
                    self.use_2cta_instrs,
                    tmem_acc_stage,
                    mC,
                    cta_c_tile_coord,
                    tma_store_pipe,
                    tma_store_warp_id,
                    self.epilogue_op,
                )

                acc_pipe.consumer_release_and_advance()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

        # Cluster sync before exit. No-op for pure 1-CTA (1,1) launches.
        if cutlass.const_expr(cute.size(self.cluster_shape_mn) > 1):
            cute.arch.cluster_arrive()
            cute.arch.cluster_wait()


# Helper function for ceil division
def ceil_div(a, b):
    return (a + b - 1) // b


## these are copied from Cute DSL example, will need to be revisited again
@cute.experimental.jit
def cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
    sf_ref_tensor: cute.Tensor,
    sf_mma_tensor: cute.Tensor,
):
    """Convert scale factor tensor from MKL layout to mma specification M(32x4xrest_m)xK(4xrest_k)xL layout"""
    # sf_mma_tensor has flatten shape (32, 4, rest_m, 4, rest_k, l)
    # group to ((32, 4, rest_m), (4, rest_k), l)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 0, 3)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 1, 3)
    for i in cutlass.range(cute.size(sf_ref_tensor)):
        mkl_coord = sf_ref_tensor.layout.get_hier_coord(i)
        sf_mma_tensor[mkl_coord] = sf_ref_tensor[mkl_coord]


# Creates f32 tensors (a/b/c/sfa/sfb), regardless of their actual data type
# Later these tensors will be properly converted to the intended data types
def create_and_init_tensors_emulated(
    mnkl: Tuple[int, int, int, int],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
):
    m, n, k, l = mnkl
    sf_k = ceil_div(k, sf_vec_size)

    # Create tensor SFA/SFB with values in [0, 3)
    sfa = torch.randint(0, 3, (l, m, sf_k), dtype=torch.float32).permute(1, 2, 0)
    sfb = torch.randint(0, 3, (l, n, sf_k), dtype=torch.float32).permute(1, 2, 0)

    # Create tensor A/B
    if a_major == "k":
        a = torch.empty((l, m, k), dtype=torch.float32, device="cuda").permute(1, 2, 0)
    else:
        a = torch.empty((l, k, m), dtype=torch.float32, device="cuda").permute(2, 1, 0)
    if b_major == "k":
        b = torch.empty((l, n, k), dtype=torch.float32, device="cuda").permute(1, 2, 0)
    else:
        b = torch.empty((l, k, n), dtype=torch.float32, device="cuda").permute(2, 1, 0)

    # Initialize A/B tensors with either normal distribution or random integers
    for tensor in [a, b]:
        if init_normal:
            tensor.normal_(mean=normal_mean, std=normal_std)
        else:
            tensor.copy_(
                torch.randint(-2, 2, tensor.shape, dtype=torch.float32, device="cuda")
            )

    if c_major == "n":
        c = torch.empty(
            (l, m, n), dtype=cutlass_torch.dtype(c_dtype), device="cuda"
        ).permute(1, 2, 0)
    else:
        c = torch.empty(
            (l, n, m), dtype=cutlass_torch.dtype(c_dtype), device="cuda"
        ).permute(2, 1, 0)
    return a, b, c, sfa, sfb


# Create scale factor tensor SFA/SFB
def create_scale_factor_tensor(l, mn, k, sf_vec_size, dtype, torch_tensor_f32):
    sf_k = ceil_div(k, sf_vec_size)

    atom_m = (32, 4)
    atom_k = 4
    mma_shape = (
        l,
        ceil_div(mn, atom_m[0] * atom_m[1]),
        ceil_div(sf_k, atom_k),
        atom_m[0],
        atom_m[1],
        atom_k,
    )

    mma_permute_order = (3, 4, 1, 5, 2, 0)

    # Create f32 cute torch tensor (cpu)
    cute_f32_torch_tensor_cpu = torch.empty(mma_shape, dtype=torch.float32).permute(
        mma_permute_order
    )

    # Convert (reorder) ref f32 tensor to cute f32 tensor
    cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
        from_dlpack(torch_tensor_f32),
        from_dlpack(cute_f32_torch_tensor_cpu),
    )
    cute_f32_torch_tensor = cute_f32_torch_tensor_cpu.cuda()

    # reshape makes memory contiguous
    ref_f32_torch_tensor_cpu = (
        torch_tensor_f32.permute(2, 0, 1)
        .unsqueeze(-1)
        .expand(l, mn, sf_k, sf_vec_size)
        .reshape(l, mn, sf_k * sf_vec_size)
        .permute(1, 2, 0)
    )
    # prune to mkl for reference check.
    ref_f32_torch_tensor_cpu = ref_f32_torch_tensor_cpu[:, :k, :]

    # Create dtype cute torch tensor (cpu)
    cute_tensor, _ = cutlass_torch.cute_tensor_like(
        cute_f32_torch_tensor_cpu,
        dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )

    # Convert f32 cute tensor to dtype cute tensor
    cute_tensor = cutlass_torch.convert_cute_tensor(
        cute_f32_torch_tensor,
        cute_tensor,
        dtype,
        is_dynamic_layout=True,
    )
    return ref_f32_torch_tensor_cpu, cute_tensor


# Construct CuTe Tensors for the persistent dense blockscaled GEMM operation
def construct_ab_cute_tensors(
    a: torch.Tensor,
    b: torch.Tensor,
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
):
    a_cute, _ = cutlass_torch.cute_tensor_like(
        a.cpu(),
        a_dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )
    a_cute = cutlass_torch.convert_cute_tensor(
        a,
        a_cute,
        a_dtype,
        is_dynamic_layout=True,
    )
    b_cute, _ = cutlass_torch.cute_tensor_like(
        b.cpu(),
        b_dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )
    b_cute = cutlass_torch.convert_cute_tensor(
        b,
        b_cute,
        b_dtype,
        is_dynamic_layout=True,
    )

    return a_cute, b_cute


def run(
    mnkl: Tuple[int, int, int, int],
    mma_inst_shape: Tuple[int, int, int],
    mma_tiler: Tuple[int, int, int],
    cluster_shape_mn: Tuple[int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    num_load_stages_override: Optional[int] = None,
    num_store_stages_override: Optional[int] = None,
    num_acc_stages_override: Optional[int] = None,
    arch: str = "sm_107",
):
    """Execute a batched block scaled dense GEMM operation on Blackwell architecture.

    This function prepares input tensors, configures and launches the GEMM kernel,
    and performs reference validation.

    :param mnkl: Problem size (M, N, K, L)
    :type mnkl: Tuple[int, int, int, int]
    :param mma_inst_shape: MMA instruction shape (M, N, K).
    :type mma_inst_shape: Tuple[int, int, int]
    :param mma_tiler: MMA tiler shape (M, N, K).
    :type mma_tiler: Tuple[int, int, int]
    :param cluster_shape_mn: Cluster shape (M, N) with the 2-CTA
        peer pair already folded in.
    :type cluster_shape_mn: Tuple[int, int]
    :param a_dtype: Data type for input tensor A
    :type a_dtype: Type[Numeric]
    :param b_dtype: Data type for input tensor B
    :type b_dtype: Type[Numeric]
    :param sf_dtype: Data type for scale factors (SFA/SFB)
    :type sf_dtype: Type[Numeric]
    :param sf_vec_size: Vector size for the scale factor
    :type sf_vec_size: int
    :param c_dtype: Data type for output tensor C
    :type c_dtype: Type[Numeric]
    :param acc_dtype: Accumulator data type (precision)
    :type acc_dtype: Type[Numeric]
    :param a_major: Major-ness of A tensor (m or k)
    :type a_major: str
    :param b_major: Major-ness of B tensor (n or k)
    :type b_major: str
    :param c_major: Major-ness of C tensor (m or n)
    :type c_major: str
    :param num_load_stages_override: Optional cap on the TMA-load pipeline
        depth; only lowers the value picked by ``_compute_stages``.
    :type num_load_stages_override: Optional[int]
    :param num_store_stages_override: Optional cap on the TMA-store pipeline
        depth; only lowers the value picked by ``_compute_stages``.
    :type num_store_stages_override: Optional[int]
    :param num_acc_stages_override: Optional cap on the accumulator (TMEM)
        pipeline depth; only lowers the value picked by ``_compute_stages``.
    :type num_acc_stages_override: Optional[int]
    """
    cli.print_problem_config(
        f"LIR Rubin ({arch.upper()}) Dense Block Scaled GEMM",
        mnkl,
        lines=[
            f"A: {a_dtype}, B: {b_dtype}, C: {c_dtype}, Acc dtype: {acc_dtype}",
            f"Block scaled MMA with SF: {sf_dtype}, vector size: {sf_vec_size}",
        ],
        majors={
            "A": f"{a_major}-major",
            "B": f"{b_major}-major",
            "C": f"{c_major}-major",
        },
    )
    print(
        f"MMA instruction shape: {mma_inst_shape}, MMA tiler: {mma_tiler}, "
        f"Cluster Shape: {cluster_shape_mn[0]}x{cluster_shape_mn[1]}x1"
    )
    m, n, k, l = mnkl

    # TODO: revisit alignment checks; they currently come from the sm_100
    # helpers but the rules carry over to sm_107 unchanged.
    sm100_utils.check_gemm_tma_alignment(
        m,
        n,
        k,
        a_dtype,
        b_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        output_tensor_name="C",
    )

    # Initial-scope gate -- delegate to the kernel's predicate so this stays in
    # sync with what the kernel actually accepts.
    reason = Sm107BlockScaledDenseGemmKernel.can_implement(
        mnkl,
        mma_inst_shape,
        mma_tiler,
        cluster_shape_mn,
        a_dtype,
        b_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        acc_dtype,
        a_major,
        b_major,
        c_major,
    )
    if reason:
        raise RuntimeError(reason)

    if not torch.cuda.is_available():
        raise RuntimeError("A GPU is required to run this example!")

    # Manual seed
    torch.manual_seed(111)

    # Create tensors
    def generate_inputs():
        # Create Torch Tensors for A, scale factor A, B, scale factor B, C
        a_f32_ref, b_f32_ref, c, sfa_f32, sfb_f32 = create_and_init_tensors_emulated(
            mnkl,
            sf_vec_size,
            c_dtype,
            a_major,
            b_major,
            c_major,
        )

        # Creation of torch and cute tensors for SFA/SFB
        sfa_f32_ref, sfa_tensor = create_scale_factor_tensor(
            l, m, k, sf_vec_size, sf_dtype, sfa_f32
        )
        sfb_f32_ref, sfb_tensor = create_scale_factor_tensor(
            l, n, k, sf_vec_size, sf_dtype, sfb_f32
        )

        # Construct cute.Tensors for a/b based on the torch tensors
        a_tensor, b_tensor = construct_ab_cute_tensors(
            a_f32_ref,
            b_f32_ref,
            a_dtype,
            b_dtype,
        )

        c_tensor = from_dlpack(c, assumed_align=16).mark_layout_dynamic(
            leading_dim=1 if c_major == "n" else 0
        )

        return (
            (a_f32_ref, a_tensor),
            (b_f32_ref, b_tensor),
            (sfa_f32_ref, sfa_tensor),
            (sfb_f32_ref, sfb_tensor),
            (c, c_tensor),
        )

    (
        (a_f32_ref, a_tensor),
        (b_f32_ref, b_tensor),
        (sfa_f32_ref, sfa_tensor),
        (sfb_f32_ref, sfb_tensor),
        (c, c_tensor),
    ) = generate_inputs()

    # JIT-Compile the device kernel. Query the device's persistent-cluster
    # capacity so the kernel can rasterize the problem across a fixed-size CTA
    # grid. ``cluster_shape_mn`` is the launch cluster (peer pair already
    # folded in), so the cluster size is just its product.
    cluster_size = cluster_shape_mn[0] * cluster_shape_mn[1]
    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(cluster_size)
    block_scaled_gemm = Sm107BlockScaledDenseGemmKernel(
        mma_inst_shape=mma_inst_shape,
        mma_tiler=mma_tiler,
        a_dtype=a_dtype,
        b_dtype=b_dtype,
        acc_dtype=acc_dtype,
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
        cluster_shape_mn=cluster_shape_mn,
        max_active_clusters=max_active_clusters,
        num_load_stages_override=num_load_stages_override,
        num_store_stages_override=num_store_stages_override,
        num_acc_stages_override=num_acc_stages_override,
        arch=arch,
    )

    compiled_kernel = cute.experimental.compile(
        block_scaled_gemm,
        a_tensor,
        sfa_tensor,
        b_tensor,
        sfb_tensor,
        c_tensor,
    )

    # Launch the device kernel
    compiled_kernel(
        a_tensor,
        sfa_tensor,
        b_tensor,
        sfb_tensor,
        c_tensor,
    )

    res_a = torch.einsum("mkl,mkl->mkl", a_f32_ref, sfa_f32_ref.cuda())
    res_b = torch.einsum("nkl,nkl->nkl", b_f32_ref, sfb_f32_ref.cuda())
    ref = torch.einsum("mkl,nkl->mnl", res_a, res_b)
    c_ref = ref.to(dtype=cutlass_torch.dtype(c_dtype))

    tolerance = 1e-01  # TODO: make this an input argument
    torch.testing.assert_close(c, c_ref, atol=tolerance, rtol=tolerance)
    print("PASS")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Example of SM107 (Rubin) Dense BlockScaled GEMM (cute_ext / LIR)."
    )

    cli.add_mnkl_arg(parser, default=(256, 256, 256, 1), strict_length=True)
    parser.add_argument(
        "--mma_inst_shape",
        type=cli.comma_separated_ints_of(3),
        default=(128, 128, 128),
        help="MMA instruction shape (M,N,K) comma-separated. mma_inst_m must "
        "be 128 (1-CTA) or 256 (2-CTA); FP4 fixes mma_inst_k == 128.",
    )
    parser.add_argument(
        "--mma_tiler",
        type=cli.comma_separated_ints_of(3),
        default=(128, 128, 256),
        help="MMA tiler shape (M,N,K) comma-separated. mma_tiler_m equals "
        "mma_inst_shape_m (no b-reuse) or 2*mma_inst_shape_m (b-reuse on); "
        "mma_tiler_n must equal mma_inst_shape_n; mma_tiler_k must be a "
        "positive multiple of mma_inst_shape_k.",
    )
    cli.add_cluster_shape_arg(
        parser,
        strict_length=True,
        help="Raw launch cluster shape (M, N) comma-separated; each dim a "
        "power of 2 in {1, 2, 4}. Under 2-CTA (mma_inst_m == 256), M must "
        "be a multiple of 2 (>= 2).",
    )
    parser.add_argument("--a_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--b_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--sf_dtype", type=cutlass.dtype, default=cutlass.Float8E8M0FNU)
    parser.add_argument("--sf_vec_size", type=int, default=32)
    cli.add_dtype_args(parser, c=cutlass.Float16)
    # FP4 (initial scope) requires K-major A/B and N-major C; enforced by
    # ``can_implement``.
    cli.add_major_args(parser, a=["k"], b=["k"], c=["n"])
    # Optional pipeline-depth caps; each only lowers the value picked by
    # ``_compute_stages`` (an override >= the computed depth has no effect).
    parser.add_argument("--num_load_stages_override", type=int, default=None)
    parser.add_argument("--num_store_stages_override", type=int, default=None)
    parser.add_argument("--num_acc_stages_override", type=int, default=None)
    parser.add_argument("--arch", type=str, default="sm_107")

    args = parser.parse_args()

    run(
        args.mnkl,
        args.mma_inst_shape,
        args.mma_tiler,
        args.cluster_shape_mn,
        args.a_dtype,
        args.b_dtype,
        args.sf_dtype,
        args.sf_vec_size,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.num_load_stages_override,
        args.num_store_stages_override,
        args.num_acc_stages_override,
        args.arch,
    )
