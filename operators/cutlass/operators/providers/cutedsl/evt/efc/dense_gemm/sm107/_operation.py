#
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

"""Dense GEMM EFC operations for SM107 (Rubin).

``DenseGemmEFCSm107`` is the SM100 EFC operation with the Rubin fp8 fast
path: fp8 A/B builds the K=64 ``tcgen05`` MMA (2x fp8 rate vs SM100's
K=32), every other dtype falls through to the SM100 atom path, which is
unchanged on Rubin.  ``DenseGemmEFCBlockScaledSm107`` is the same delta
over the SM100 block-scaled operation.  The kernel body, epilogue
machinery, and EFC framework are fully inherited; tile-K follows the atom
automatically (``_setup_attributes`` derives it from ``shape_mnk[2]``).

A tiler with M == 2x the instruction M selects the **Bkeep-Breuse**
collector pattern: each B K-slab is consumed twice while latched in the
tensor core's collector buffer -- FILL on the keep half, LASTUSE on the
reuse half -- halving B's SMEM read traffic.  The two half-tile
accumulators live simultaneously in TMEM (2x columns per accumulator
stage); the epilogue drains them through the standard subtile walk
because the folded accumulator layout spans both halves.  The 2-CTA
variant additionally M-permutes the tiled MMA so each CTA's two halves
cover one contiguous 256-row output block (see ``_create_tiled_mma``).
The breuse geometry is shared by both operations through
``_Sm107K64Mixin``; only the MMA builders and the keep/reuse issue loops
differ.  The base's stage computation fits the doubled accumulator (2x TMEM
columns per stage) to Rubin's 576 columns: two stages at N=128, one at
N=192 and N=256, as in the Rubin reference kernel.
"""

import cutlass
import cutlass.cute as cute
import cutlass.utils as utils
from cutlass.cute.nvgpu import tcgen05

from cutlass.operators.providers.cutedsl.evt.efc import log

from ..sm100 import DenseGemmEFC, DenseGemmEFCBlockScaled

_FP8_DTYPES = (cutlass.Float8E4M3FN, cutlass.Float8E5M2)

# Rubin's fp8 K=64 instruction admits exactly one M extent per CTA mode.
_FP8_K64_INST_M = {False: 128, True: 256}  # keyed by use_2cta_instrs
_FP8_K64_INST_K = 64


class _Sm107K64Mixin:
    """Rubin fp8 K=64 geometry shared by the dense and block-scaled
    operations: the TMEM budget, Bkeep-Breuse detection, and the doubled-M
    tiler with its 2-CTA permutation.

    Mixed in ahead of the SM100 operation class, so ``super()`` here
    reaches that operation's method.  The MMA builders and the
    keep/reuse issue loops stay in the concrete classes: their operands
    differ (``x`` vs ``[x, scale-factor]``).
    """

    # Host-class state this mixin reads.  The CTA mode and the tiler are set
    # by the operation's constructor; the dtypes only once the call records
    # the tensors, so ``enable_breuse`` reads them with a ``None`` default.
    use_2cta_instrs: bool
    mma_tiler_mn: tuple[int, int]
    mma_tiler: tuple[int, int, int]
    a_dtype: type[cutlass.Numeric]
    b_dtype: type[cutlass.Numeric]

    # The base sizes the TMEM budget (Rubin: 576 columns) from this class
    # attribute; SMEM capacity comes from the compilation target.
    arch = "sm_107"

    @property
    def enable_breuse(self):
        """Whether this configuration runs the Bkeep-Breuse doubled tile.

        A pure function of the dtypes and the tiler (the doubled-M fp8
        tiler), derived rather than stored so it can never be read stale.
        False until the dtypes are known (recorded from the tensors at the
        start of ``__call__``).
        """
        return (
            getattr(self, "a_dtype", None) in _FP8_DTYPES
            and getattr(self, "b_dtype", None) in _FP8_DTYPES
            and self.mma_tiler[0] == 2 * _FP8_K64_INST_M[self.use_2cta_instrs]
        )

    def check_valid_mma_tiler_and_cluster_shape(
        self, a_dtype, b_dtype, *, mma_tiler_mn=None
    ):
        """Accept the Bkeep-Breuse doubled-M tiler on top of the base menu.

        The base menu constrains the *instruction* M; a breuse tiler is 2x
        that, so validate the halved M against the base and keep the rest
        of the base validation (N, cluster) unchanged.  The doubled tiler
        exists only for the fp8 K=64 instruction, so its acceptance is
        gated on the dtypes: a non-fp8 doubled-M configuration falls
        through to the base menu, which rejects it cleanly.
        """
        if mma_tiler_mn is None:
            mma_tiler_mn = self.mma_tiler_mn
        inst_m = _FP8_K64_INST_M[self.use_2cta_instrs]
        if mma_tiler_mn[0] == 2 * inst_m and (
            a_dtype in _FP8_DTYPES and b_dtype in _FP8_DTYPES
        ):
            mma_tiler_mn = (inst_m, mma_tiler_mn[1])
        super().check_valid_mma_tiler_and_cluster_shape(
            a_dtype, b_dtype, mma_tiler_mn=mma_tiler_mn
        )

    def _k64_breuse_permutation(self):
        """Permutation MNK for the Bkeep-Breuse tiled MMA, or ``None``.

        Only the 2-CTA variant needs one (see ``_create_tiled_mma``); the
        1-CTA repetition is already sequence-contiguous.  Host-side only:
        the kernel's keep/reuse variants derive from the tiled-MMA kernel
        argument (``with_bkeep``/``with_breuse``), which carries the
        permutation along.
        """
        if not (self.enable_breuse and self.use_2cta_instrs):
            return None
        inst_m = _FP8_K64_INST_M[self.use_2cta_instrs]
        return (
            cute.make_layout((inst_m // 2, 2, 2), stride=(1, inst_m, inst_m // 2)),
            self.mma_tiler[1],
            _FP8_K64_INST_K,
        )


class DenseGemmEFCSm107(_Sm107K64Mixin, DenseGemmEFC):
    """SM107 (Rubin) dense GEMM with EFC epilogue fusion.

    Drop-in for ``DenseGemmEFC`` (same constructor); only the MMA atom
    selection, the Bkeep-Breuse issue pattern, and arch-derived
    capacities differ.
    """

    def _create_tiled_mma(self):
        """Build the tiled MMA atom.

        fp8 A/B uses the Rubin K=64 op (2x fp8 rate) when the tiler M is
        the instruction M (plain) or twice it (Bkeep-Breuse); every other
        dtype/shape falls through to the SM100 atom path, which Rubin
        also supports (e.g. fp8 K=32 at M=64, at half rate).

        2-CTA Bkeep-Breuse M-permutes the tiled MMA so CTA c, half h
        computes global rows [256c + 128h, 256c + 128h + 128): each CTA's
        two collector halves then cover one contiguous 256-row output
        block (halves at +0/+128), instead of the interleaved
        {128c, 128c + 256} bases of the plain repetition -- keeping the
        folded epilogue walk and its coordinate-linear TMA staging valid,
        exactly as in the 1-CTA case (which needs no permutation).
        """
        if self.a_dtype in _FP8_DTYPES and self.b_dtype in _FP8_DTYPES:
            inst_m = _FP8_K64_INST_M[self.use_2cta_instrs]
            if self.mma_tiler[0] in (inst_m, 2 * inst_m):
                inst_shape = (inst_m, self.mma_tiler[1], _FP8_K64_INST_K)
                permutation_mnk = self._k64_breuse_permutation()
                log(
                    f"sm107 fp8 K=64 atom, inst shape {inst_shape}, "
                    f"enable_breuse={self.enable_breuse}, "
                    f"permutation_mnk={permutation_mnk}"
                )
                return utils.sm107.make_trivial_tiled_mma(
                    self.a_dtype,
                    self.b_dtype,
                    self.a_major_mode,
                    self.b_major_mode,
                    self.acc_dtype,
                    self.cta_group,
                    inst_shape,
                    permutation_mnk=permutation_mnk,
                )
            log(
                f"mma_tiler M={self.mma_tiler[0]} != {inst_m}: no K=64 fp8 "
                f"instruction for this shape, falling back to the K=32 atom."
            )
        # The doubled-M (Bkeep-Breuse) tiler exists only for the fp8 K=64
        # instruction: fail here with a clear message rather than deep in
        # the SM100 atom construction.  (fp8 doubled-M returned above.)
        if self.mma_tiler[0] == 2 * _FP8_K64_INST_M[self.use_2cta_instrs]:
            raise ValueError(
                f"MMA tiler M={self.mma_tiler[0]} is the Bkeep-Breuse doubled "
                f"tile, which requires fp8 A/B; got {self.a_dtype}/{self.b_dtype}."
            )
        return super()._create_tiled_mma()

    def issue_k_tile_gemm(self, tiled_mma, tCtAcc, tCrA_blk, tCrB_blk, k_tile):
        """Issue the MMAs for one K tile: dual-accumulator under breuse.

        Each K phase issues the keep-half MMA with ``CollectorOp.FILL``
        (B latched into the collector while streaming from SMEM) followed
        by the reuse-half MMA with ``CollectorOp.LASTUSE`` (B read from
        the collector, no SMEM traffic).  The collector holds one B slab
        for exactly one keep/reuse pair, which is what forces the
        per-phase interleaving and the two simultaneously-live
        accumulators.
        """
        if not self.enable_breuse:
            return super().issue_k_tile_gemm(
                tiled_mma, tCtAcc, tCrA_blk, tCrB_blk, k_tile
            )
        # Derive the keep/reuse variants from the kernel-argument tiled MMA
        # (collector op swapped, every other field and the M-permutation
        # copied), so the mainloop can never diverge from the MMA that
        # defined the accumulator and epilogue partitions.
        mma_bkeep = tiled_mma.with_bkeep()
        mma_breuse = tiled_mma.with_breuse()
        # (MMA,) accumulator halves; both live across the whole K loop.
        tCtAcc_keep = tCtAcc[(None, 0, 0)]
        tCtAcc_reuse = tCtAcc[(None, 1, 0)]
        k_phases = self.mma_tiler[2] // _FP8_K64_INST_K
        for k_phase in range(k_phases):
            # Dynamic only for the first phase; later phases always add.
            accumulate = (k_tile != 0) if k_phase == 0 else True
            tCrB_slice = tCrB_blk[(None, 0, k_phase)]
            mma_bkeep.set(tcgen05.Field.ACCUMULATE, accumulate)
            cute.gemm(
                mma_bkeep,
                tCtAcc_keep,
                tCrA_blk[(None, 0, k_phase)],
                tCrB_slice,
                tCtAcc_keep,
            )
            mma_breuse.set(tcgen05.Field.ACCUMULATE, accumulate)
            cute.gemm(
                mma_breuse,
                tCtAcc_reuse,
                tCrA_blk[(None, 1, k_phase)],
                tCrB_slice,
                tCtAcc_reuse,
            )
        return tiled_mma


class DenseGemmEFCBlockScaledSm107(_Sm107K64Mixin, DenseGemmEFCBlockScaled):
    """SM107 (Rubin) block-scaled (MX) dense GEMM with EFC epilogue fusion.

    ``DenseGemmEFCBlockScaled`` with the block-scaled K=64 ``tcgen05`` MMA.
    Bkeep-Breuse (doubled tiler M) transfers unchanged from the dense
    Rubin operation: SFB is latched with B and shared by both halves, SFA
    is per half, and the 2-CTA M-permutation covers the SF views because
    they are indexed by the same (half, K block) coordinates as the
    permuted accumulator.
    """

    def _create_tiled_mma(self):
        """Build the block-scaled K=64 tiled MMA and record its instruction
        shape for the base class's SF layout setup.  The Bkeep-Breuse
        geometry inference and the 2-CTA M-permutation come from the
        mixin, as for the dense operation."""
        inst_m = _FP8_K64_INST_M[self.use_2cta_instrs]
        self._check_blockscaled_mma_inputs((inst_m, 2 * inst_m))
        inst_shape = (inst_m, self.mma_tiler[1], _FP8_K64_INST_K)
        self._sf_mma_inst_shape = inst_shape
        permutation_mnk = self._k64_breuse_permutation()
        log(
            f"sm107 MXF8 K=64 atom, inst shape {inst_shape}, "
            f"enable_breuse={self.enable_breuse}, "
            f"permutation_mnk={permutation_mnk}"
        )
        return utils.sm107.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            inst_shape,
            permutation_mnk=permutation_mnk,
        )

    def _create_tiled_mma_sfb(self):
        """CTA-group-ONE K=64 tiled MMA used to partition/load SFB (N
        padded to the 128-column SF datapath by the base class)."""
        return utils.sm107.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_sfb,
        )

    def issue_k_tile_gemm(
        self, tiled_mma, tCtAcc, tCrA_blk, tCrB_blk, k_tile, sf_views=None
    ):
        """Issue the block-scaled MMAs for one K tile: dual-accumulator
        under breuse, otherwise the SM100 block-scaled loop.

        Under Bkeep-Breuse the keep/reuse halves pair their per-half A/SFA
        slices while sharing one B/SFB slice per block, exactly like the
        dense Rubin pattern.
        """
        if not self.enable_breuse:
            return super().issue_k_tile_gemm(
                tiled_mma, tCtAcc, tCrA_blk, tCrB_blk, k_tile, sf_views=sf_views
            )
        assert sf_views is not None, "block-scaled MMA issue needs SF views"
        tCtSFA, tCtSFB = sf_views
        num_k_blocks = cute.size(tCrA_blk, mode=[2])
        # (MMA,) accumulator halves; both live across the whole K loop.
        tCtAcc_keep = tCtAcc[(None, 0, 0)]
        tCtAcc_reuse = tCtAcc[(None, 1, 0)]
        for k_block in range(num_k_blocks):
            # Dynamic only for the first block; later blocks always add.
            accumulate = (k_tile != 0) if k_block == 0 else True
            tCrB_slice = tCrB_blk[(None, 0, k_block)]
            tCtSFB_slice = tCtSFB[(None, 0, k_block)]
            cute.gemm(
                tiled_mma.with_bkeep(accumulate=accumulate),
                tCtAcc_keep,
                [tCrA_blk[(None, 0, k_block)], tCtSFA[(None, 0, k_block)]],
                [tCrB_slice, tCtSFB_slice],
                tCtAcc_keep,
            )
            cute.gemm(
                tiled_mma.with_breuse(accumulate=accumulate),
                tCtAcc_reuse,
                [tCrA_blk[(None, 1, k_block)], tCtSFA[(None, 1, k_block)]],
                [tCrB_slice, tCtSFB_slice],
                tCtAcc_reuse,
            )
        return tiled_mma
