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

"""Operator-API wrapper for the SM107 (Rubin) fp8 persistent dense GEMM with
EFC epilogues.

``Sm107PersistentDenseGemmEFCOperator`` is the Rubin delta over the SM100
EFC operator: everything -- discovery, metadata validation, the
``EFCConverter`` bridge, compile/run plumbing -- is inherited; this module
only narrows operands to fp8 A/B and swaps in the Rubin design rules
(``_Sm107EFCDesignMixin``: the K=64 instruction's tile-M law, the
Bkeep-Breuse doubled tile, per-CTA tile shapes) and the Rubin shim kernel,
the verbatim example ``DenseGemmEFCSm107``.  The block-scaled Rubin operator
reuses the same mixin.

Non-fp8 dtypes are not offered here (the example class falls back to the
SM100 configuration for them, and the SM100 operator already covers those
designs on Rubin).

Configuration note: ``enable_breuse`` at N=256 runs a single accumulator
stage (no mainloop/epilogue overlap), so it wins for light epilogues while
2-CTA non-breuse 256x256 is the robust choice under heavier ones.  The
operator enumerates both; ranking is the heuristics layer's job.
"""

from __future__ import annotations

import itertools
from typing import TYPE_CHECKING

import cutlass

from cutlass.operators.arguments import GemmArguments
from cutlass.operators.metadata import (
    GemmOperandsMetadata,
    Sm107DesignMetadata,
)
from cutlass.operators.mma import RubinTcgen05Mma
from cutlass.operators.providers.cutedsl import CuTeDSLProvider
from cutlass.operators.providers.cutedsl.gemm.sm100_static_persistent_efc import (
    Sm100PersistentDenseGemmEFCOperator,
)

from .implementations.sm107_static_persistent_efc_impl import (
    Sm107PersistentDenseGemmEFCKernel,
)

if TYPE_CHECKING:
    from collections.abc import Generator

_FP8_DTYPES = (cutlass.Float8E4M3FN, cutlass.Float8E5M2)


class _Sm107EFCDesignMixin:
    """Rubin design rules shared by the dense and block-scaled EFC operators.

    Mixed in ahead of the SM100 operator class, so ``super()`` here reaches
    that operator's method.  Covers the design metadata type and MMA
    instruction, the K=64 instruction's tile-M law (one instruction M, or
    two stacked for the Bkeep-Breuse doubled tile, split across the MMA's
    CTAs), the per-CTA tile convention, and the design enumeration.  The
    operand rules and the shim kernel stay in the concrete operators.

    Relies on the base's ``_tile_shape_k``, ``_tile_n_menu``,
    ``_efc_cluster_shapes``, ``_design_suffix`` and ``_valid_operands``,
    reached through ``cls`` and ``super()``.
    """

    _design_metadata_type = Sm107DesignMetadata
    _mma_instruction_type = RubinTcgen05Mma

    @classmethod
    def _mma_tiler_mn(cls, design) -> tuple[int, int]:
        """The operation takes the full MMA tiler; sm107 designs carry the
        per-CTA tile.  A doubled tiler M (2x the instruction M) is what
        selects the Bkeep-Breuse configuration inside the operation."""
        mma_ctas = 2 if design.use_2cta_mma else 1
        return (design.tile_shape[0] * mma_ctas, design.tile_shape[1])

    @classmethod
    def _valid_tile_shape(cls, design) -> bool:
        """Rubin tile-M law: the per-CTA tile M is one instruction M (or
        two, stacked, for the Bkeep-Breuse doubled tile) split across the
        MMA's CTAs.  (sm107 designs carry the per-CTA tile, matching the
        plain ``Sm107DenseGemmUniversalOperator``, unlike sm100's full MMA tiler.)
        """
        mma_ctas = 2 if design.use_2cta_mma else 1
        inst_m = 256 if design.use_2cta_mma else 128
        instruction_tiles_m = 2 if design.enable_breuse else 1
        return design.tile_shape[0] == inst_m * instruction_tiles_m // mma_ctas

    @classmethod
    def _design_space(
        cls, operands: GemmOperandsMetadata
    ) -> Generator[Sm107DesignMetadata, None, None]:
        """Yield the Rubin design candidates: two K=64 instruction phases
        per mainloop tile, with and without the Bkeep-Breuse doubled tile,
        over the operand family's legal tile-N menu.
        """
        tile_k = cls._tile_shape_k(operands)
        inst_configs = ((False, 128), (True, 256))
        for (use_2cta_mma, inst_m), enable_breuse, cluster_shape in itertools.product(
            inst_configs, (False, True), cls._efc_cluster_shapes()
        ):
            mma_ctas = 2 if use_2cta_mma else 1
            # Skip designs _valid_design is guaranteed to reject before
            # paying for their metadata construction.
            if cluster_shape[0] % mma_ctas != 0:
                continue
            instruction_tiles_m = 2 if enable_breuse else 1
            tile_m = inst_m * instruction_tiles_m // mma_ctas
            for tile_n in cls._tile_n_menu():
                yield Sm107DesignMetadata(
                    mma_instruction_type=cls._mma_instruction_type,
                    use_2cta_mma=use_2cta_mma,
                    tile_shape=(tile_m, tile_n, tile_k),
                    cluster_shape=cluster_shape,
                    fallback_cluster_shape=None,
                    use_tma_store=True,
                    enable_breuse=enable_breuse,
                )

    @classmethod
    def _design_suffix(cls, design) -> str:
        """See :meth:`Sm100PersistentDenseGemmEFCOperator._design_suffix`."""
        breuse = "_breuse" if design.enable_breuse else ""
        return breuse + super()._design_suffix(design)


@CuTeDSLProvider.register
class Sm107PersistentDenseGemmEFCOperator(
    _Sm107EFCDesignMixin, Sm100PersistentDenseGemmEFCOperator
):
    """SM107 (Rubin) fp8 persistent dense GEMM with EFC epilogue fusion.

    Args:
        metadata (OperatorMetadata): One validated kernel configuration
            (operands, design, and optional epilogue) to instantiate.

    Note:
        A and B must both be fp8 (Float8E4M3FN / Float8E5M2) -- the K=64
        MMA exists only for fp8.  The accumulator/output menus and the
        fp8 A/B mixing rule are inherited from the SM100 wrapper.

    Note:
        Design constraints (see the shared ``_valid_design``): per-CTA
        tile M is 128, or 256 with ``enable_breuse``; tile N is 32-256 in
        steps of 32; tile K is twice the K=64 instruction; cluster M is a
        multiple of the MMA CTA count; cluster M/N are powers of 2 with
        product <= 16; no fallback cluster and no custom tile scheduler
        (the kernel is static-persistent).  Validity is legality only:
        ranking legal designs (e.g. breuse at 160<=N<=224 runs a single
        accumulator stage, losing mainloop/epilogue overlap) is the
        heuristics layer's job.
    """

    supported_args_type = GemmArguments
    designed_for_min_cc = 107
    _shim_kernel_type = Sm107PersistentDenseGemmEFCKernel

    @classmethod
    def _valid_operands(cls, operands: GemmOperandsMetadata) -> bool:
        """Rubin delta: the K=64 MMA exists only for fp8 A/B."""
        if not isinstance(operands, GemmOperandsMetadata):
            return False
        if operands.A.dtype not in _FP8_DTYPES or operands.B.dtype not in _FP8_DTYPES:
            return False
        return super()._valid_operands(operands)
