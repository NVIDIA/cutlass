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

"""Operator-API wrapper for the SM107 (Rubin) block-scaled (MXFP8) persistent
dense GEMM with EFC epilogues.

``Sm107PersistentBlockScaledGemmEFCOperator`` is the Rubin delta over
the SM100 block-scaled EFC operator, cut the same way as the dense pair: the
MXFP8 operand rules, discovery and compile/run plumbing are inherited; the
shared ``_Sm107EFCDesignMixin`` supplies the K=64 instruction's design rules
(per-CTA tiles, the Bkeep-Breuse doubled tile); and the shim kernel wraps the
verbatim example ``DenseGemmEFCBlockScaledSm107``.

Configuration note: ``enable_breuse`` at N=192 and N=256 runs a single
accumulator stage, as in the Rubin reference blockscaled kernel.  The
operator enumerates those designs; ranking is the heuristics layer's job.
"""

from __future__ import annotations

from cutlass.operators.arguments import GemmArguments
from cutlass.operators.providers.cutedsl import CuTeDSLProvider
from cutlass.operators.providers.cutedsl.gemm.sm100_blockscaled_static_persistent_efc import (
    Sm100PersistentBlockScaledGemmEFCOperator,
)
from cutlass.operators.providers.cutedsl.gemm.sm107_static_persistent_efc import (
    _Sm107EFCDesignMixin,
)

from .implementations.sm107_dense_blockscaled_static_persistent_efc_impl import (
    Sm107PersistentDenseBlockScaledGemmEFCKernel,
)


@CuTeDSLProvider.register
class Sm107PersistentBlockScaledGemmEFCOperator(
    _Sm107EFCDesignMixin, Sm100PersistentBlockScaledGemmEFCOperator
):
    """SM107 (Rubin) block-scaled (MXFP8) persistent dense GEMM with EFC
    epilogue fusion.

    Args:
        metadata (OperatorMetadata): One validated kernel configuration
            (operands, design, and optional epilogue) to instantiate.

    Note:
        Operands as for the SM100 block-scaled EFC operator (fp8 x fp8
        quantized A/B, E8M0 scales over 32 K elements, Float32 accumulator).

    Note:
        Design constraints (see the shared ``_valid_design``): per-CTA tile
        M is 128, or 256 with ``enable_breuse``; tile N is 64, 128, 192 or
        256; tile K is twice the K=64 instruction; cluster M is a multiple
        of the MMA CTA count; cluster M/N are powers of 2 with product <= 16.
    """

    supported_args_type = GemmArguments
    designed_for_min_cc = 107
    # The mixin's RubinTcgen05Mma covers the block-scaled fp8 MMA too (no
    # separate type exists); the shim kernel builds the K=64 block-scaled atom.
    _shim_kernel_type = Sm107PersistentDenseBlockScaledGemmEFCKernel
