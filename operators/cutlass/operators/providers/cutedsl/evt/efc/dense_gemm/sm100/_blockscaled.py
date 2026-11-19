#
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

"""Block-scaled (MX) dense GEMM EFC operation for SM100 (Blackwell).

``DenseGemmEFCBlockScaled`` is ``DenseGemmEFC`` with the block-scaled
``tcgen05`` MMA: the fp8 A/B operands are dequantized inside the tensor
core by E8M0 scale factors, one per ``sf_vec_size`` (32) K elements.  The
scale factors are consumed only by the mainloop's MMAs, which apply them
while accumulating; they are staged GMEM->SMEM->TMEM alongside A/B by the
base class's ``has_scale_factors`` machinery, and the epilogue sees the
dequantized accumulator, so the EFC epilogue surface is identical to the
parent's.  Architecture subclasses swap the MMA builder (Rubin: the K=64
instruction plus Bkeep-Breuse); everything else is shared here.

Scope: fp8 x fp8 quantized operands (MXF8, f32 accumulator).  The scale
factors follow the fixed tcgen05 scale-factor atom
(``blockscaled_utils.BlockScaledBasicChunk``): 128 rows of M for SFA, or of
N for SFB, by 4 scale factors along K (one 128-element K tile).  Every legal
tiler M (the instruction M, or twice it under Rubin Bkeep-Breuse) is a
multiple of 128, so SFA always covers whole atoms.  Tile N is 64, 128, 192
or 256: at 128 and 256 the SFB tile is whole atoms too; at 64 and 192 two
neighbouring N tiles share one staged atom-aligned window (the base kernel's
TMA warp picks the window and its MMA warp offsets the SFB TMEM view by the
64-row remainder).  The base fits the accumulator stages to the
architecture's TMEM budget next to the scale-factor columns.
"""

import math

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
import cutlass.utils as utils
import cutlass.utils.blockscaled_layout as blockscaled_utils
from cutlass.cute.nvgpu import tcgen05

from cutlass.operators.providers.cutedsl.evt.efc import log

from ._operation import DenseGemmEFC

_FP8_DTYPES = (cutlass.Float8E4M3FN, cutlass.Float8E5M2)

# Block-scaled MMA instruction M per CTA mode: 128 single-CTA, 256 two-CTA.
_BLOCKSCALED_INST_M = {False: 128, True: 256}  # keyed by use_2cta_instrs
# Tile N menu: whole 128-row SFB atoms, or the shared-window halves of one
# (64) and of two (192); see the module docstring.
_VALID_TILE_N = (64, 128, 192, 256)
# The scale-factor atom: 128 rows of M (SFA) or N (SFB) by 4 scales along K.
_SF_ATOM_MN = 128
_SF_ATOM_K = 4


class DenseGemmEFCBlockScaled(DenseGemmEFC):
    """SM100 block-scaled (MX) dense GEMM with EFC epilogue fusion.

    Same constructor as ``DenseGemmEFC``; ``__call__``/``compile`` take the
    SFA/SFB tensors after A/B.  The MMA instruction K is the arch's
    block-scaled fp8 K (32 on SM100), and tile K follows it automatically.
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.has_scale_factors = True
        # MXF8: one E8M0 scale per 32 K elements.
        self.sf_vec_size = 32

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        sfa: cute.Tensor,
        sfb: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        *supplemental_parameters,
    ):
        """Execute the block-scaled GEMM (see ``DenseGemmEFC.__call__``).

        :param sfa: A's scale factors -- one E8M0 per 32 K elements of A --
            in the atom-reordered buffer order produced by
            ``create_scale_factor_tensor``.  The (M, K, L)-indexable
            canonical view (``blockscaled_utils.tile_atom_to_shape_SF``)
            is constructed here from ``a``'s shape, as its nested layout
            cannot cross the dlpack boundary.
        :type sfa: cute.Tensor
        :param sfb: B's scale factors, same contract keyed by ``b``.
        :type sfb: cute.Tensor
        """
        sfa_view = cute.make_tensor(
            sfa.iterator,
            blockscaled_utils.tile_atom_to_shape_SF(a.shape, self.sf_vec_size),
        )
        sfb_view = cute.make_tensor(
            sfb.iterator,
            blockscaled_utils.tile_atom_to_shape_SF(b.shape, self.sf_vec_size),
        )
        self._call_impl(
            a,
            b,
            sfa_view,
            sfb_view,
            max_active_clusters,
            stream,
            supplemental_parameters,
        )

    def compile(
        self,
        a_tensor,
        b_tensor,
        sfa_tensor,
        sfb_tensor,
        max_active_clusters,
        current_stream,
        *supplemental_arguments,
        **compiler_options,
    ):
        """See ``DenseGemmEFC.compile``; the SFA/SFB tensors follow A/B.

        The compiled callable takes
        ``(a, b, sfa, sfb, stream, *supplemental_arguments)``.
        """
        self.check_valid_scale_factor_sizes(a_tensor, b_tensor, sfa_tensor, sfb_tensor)
        self.efc.compile(*supplemental_arguments)
        return cutlass.cute.compile(
            self,
            a_tensor,
            b_tensor,
            sfa_tensor,
            sfb_tensor,
            max_active_clusters,
            current_stream,
            *supplemental_arguments,
            **compiler_options,
        )

    def check_valid_dtypes(
        self,
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
    ):
        """Narrow the menu to MXF8: both quantized operands fp8."""
        if a_dtype not in _FP8_DTYPES or b_dtype not in _FP8_DTYPES:
            raise TypeError(
                f"Block-scaled EFC supports fp8 A/B only (MXF8); "
                f"got {a_dtype} / {b_dtype}"
            )
        super().check_valid_dtypes(a_dtype, b_dtype)

    @staticmethod
    def _canonical_sf_numel(mn: int, k: int, batch: int, sf_vec_size: int) -> int:
        """Element count of the canonical scale-factor buffer of an
        ``(MN, K, L)`` operand: whole 128-row by 4-scale atoms, the extent
        ``tile_atom_to_shape_SF`` spans and the kernel's TMA reads."""
        # One scale per sf_vec_size K elements, padded to whole atoms along
        # both MN (128 rows) and K (4 scales).
        num_sf_k = cute.ceil_div(k, sf_vec_size)
        return (
            batch * cute.round_up(mn, _SF_ATOM_MN) * cute.round_up(num_sf_k, _SF_ATOM_K)
        )

    def check_valid_scale_factor_sizes(self, a, b, sfa, sfb):
        """Check that each scale-factor buffer holds the canonical,
        atom-padded element count of its operand (``(M, K, L)`` for SFA,
        ``(N, K, L)`` for SFB).  The kernel reads that whole extent through
        TMA, so a short buffer would be read out of bounds silently.

        :raises ValueError: If a buffer's element count differs from the
            canonical one.
        """
        for name, operand, sf in (("SFA", a, sfa), ("SFB", b, sfb)):
            mn, k, batch = operand.shape
            expected = self._canonical_sf_numel(mn, k, batch, self.sf_vec_size)
            actual = math.prod(sf.shape)
            if actual != expected:
                raise ValueError(
                    f"Scale factor {name} must hold {expected} elements for a "
                    f"({mn}, {k}, {batch}) operand with {self.sf_vec_size}-element "
                    f"scale vectors (whole {_SF_ATOM_MN}x{_SF_ATOM_K} scale-factor "
                    f"atoms); got {actual} (shape {tuple(sf.shape)})."
                )

    def check_implementable(self, a, b, d, sfa=None, sfb=None):
        """See ``DenseGemmEFC.check_implementable``; with ``sfa`` and ``sfb``
        (both or neither) the scale-factor buffer sizes are checked too."""
        super().check_implementable(a, b, d)
        if (sfa is None) != (sfb is None):
            raise cutlass.testing.CantImplementError(
                "Configuration error: pass both scale-factor tensors or neither"
            )
        if sfa is not None:
            try:
                self.check_valid_scale_factor_sizes(a, b, sfa, sfb)
            except ValueError as e:
                raise cutlass.testing.CantImplementError(
                    f"Configuration error: {e}"
                ) from e

    def check_valid_mma_tiler_and_cluster_shape(
        self, a_dtype, b_dtype, *, mma_tiler_mn=None
    ):
        """MX tiler menu: M is the block-scaled instruction M, and tile N is
        one of ``_VALID_TILE_N``."""
        if mma_tiler_mn is None:
            mma_tiler_mn = self.mma_tiler_mn
        inst_m = _BLOCKSCALED_INST_M[self.use_2cta_instrs]
        if mma_tiler_mn[0] != inst_m:
            raise ValueError(
                f"Invalid MMA tile M dimension for block-scaled EFC: "
                f"{mma_tiler_mn[0]}. Expected {inst_m} "
                f"(use_2cta_instrs={self.use_2cta_instrs})"
            )
        if mma_tiler_mn[1] not in _VALID_TILE_N:
            raise ValueError(
                f"Invalid MMA tiler N={mma_tiler_mn[1]} for block-scaled EFC: "
                f"expected one of {list(_VALID_TILE_N)}."
            )
        super().check_valid_mma_tiler_and_cluster_shape(
            a_dtype, b_dtype, mma_tiler_mn=mma_tiler_mn
        )

    def _check_blockscaled_mma_inputs(self, valid_tiler_m):
        """Trace-time gates for the block-scaled MMA, shared with arch
        subclasses: MXF8 operands, E8M0 vec-32 scales, f32 accumulation,
        and the tiler M/N menu.  Applied at trace time as well as in
        ``check_implementable`` so a direct ``compile`` sees the same menu.
        Tile N is restricted to ``_VALID_TILE_N``: the kernel stages SFB in
        whole 128-row atoms and only knows the two shared-window cases.
        """
        if self.a_dtype not in _FP8_DTYPES or self.b_dtype not in _FP8_DTYPES:
            raise TypeError(
                f"Block-scaled EFC supports fp8 A/B only (MXF8); "
                f"got {self.a_dtype} / {self.b_dtype}"
            )
        if self.sf_dtype is not cutlass.Float8E8M0FNU or self.sf_vec_size != 32:
            raise TypeError(
                f"MXF8 requires Float8E8M0FNU scale factors with vector "
                f"size 32; got {self.sf_dtype} / {self.sf_vec_size}"
            )
        if self.acc_dtype is not cutlass.Float32:
            raise TypeError(
                f"The block-scaled MMA accumulates in Float32; got {self.acc_dtype}"
            )
        if self.mma_tiler[0] not in valid_tiler_m:
            raise ValueError(
                f"Invalid MMA tiler M={self.mma_tiler[0]} for block-scaled "
                f"EFC: expected one of {list(valid_tiler_m)}."
            )
        if self.mma_tiler[1] not in _VALID_TILE_N:
            raise ValueError(
                f"Invalid MMA tiler N={self.mma_tiler[1]} for block-scaled "
                f"EFC: expected one of {list(_VALID_TILE_N)}."
            )

    def _create_tiled_mma(self):
        """Build the block-scaled tiled MMA and record its instruction shape
        for the base class's SF layout setup.  The SM100 builder fixes the
        instruction K from the operand formats (32 for fp8)."""
        inst_m = _BLOCKSCALED_INST_M[self.use_2cta_instrs]
        self._check_blockscaled_mma_inputs((inst_m,))
        tiled_mma = utils.sm100.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_tiler[:2],
        )
        inst_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        self._sf_mma_inst_shape = (inst_m, self.mma_tiler[1], inst_k)
        log(f"sm100 MXF8 atom, inst shape {self._sf_mma_inst_shape}")
        return tiled_mma

    def _create_tiled_mma_sfb(self):
        """CTA-group-ONE tiled MMA used to partition/load SFB, with N
        padded to the 128-column SF datapath (``mma_inst_shape_sfb``,
        computed by the base class's ``_setup_sf_tmem_attributes``)."""
        return utils.sm100.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_sfb[:2],
        )

    def issue_k_tile_gemm(
        self, tiled_mma, tCtAcc, tCrA_blk, tCrB_blk, k_tile, sf_views=None
    ):
        """Issue the block-scaled MMAs for one K tile.

        Each operand is the ``[data, scale-factor]`` pair the block-scaled
        MMA consumes; the SF TMEM views are sliced by the same K-block
        coordinate as the register operands.
        """
        assert sf_views is not None, "block-scaled MMA issue needs SF views"
        tCtSFA, tCtSFB = sf_views
        num_k_blocks = cute.size(tCrA_blk, mode=[2])
        for k_block in range(num_k_blocks):
            # Dynamic only for the first block; later blocks always add.
            accumulate = (k_tile != 0) if k_block == 0 else True
            tiled_mma.set(tcgen05.Field.ACCUMULATE, accumulate)
            cute.gemm(
                tiled_mma,
                tCtAcc,
                [tCrA_blk[(None, None, k_block)], tCtSFA[(None, None, k_block)]],
                [tCrB_blk[(None, None, k_block)], tCtSFB[(None, None, k_block)]],
                tCtAcc,
            )
        return tiled_mma
