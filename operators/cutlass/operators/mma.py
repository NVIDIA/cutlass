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

from __future__ import annotations

from typing import TYPE_CHECKING

import cutlass

from cutlass.operators.arch import TargetSm

if TYPE_CHECKING:
    from cutlass.operators.metadata import DesignMetadata, OperandsMetadata


class MmaInstruction:
    """Models properties of an abstract MMA instruction."""

    @staticmethod
    def supported_targets(
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Return all the supported targets for the MMA instruction, given optional design and operands metadata."""
        raise NotImplementedError

    @staticmethod
    def shape_k(
        operands: OperandsMetadata,
    ) -> int:
        """Return the K dimension of the shape of matrix multiplication performed by this instruction."""
        raise NotImplementedError



class BlackwellTcgen05Mma(MmaInstruction):
    """Models the tcgen05.mma instruction for the Blackwell architecture."""

    @staticmethod
    def supported_targets(
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """See :meth:`MmaInstruction.supported_targets`."""
        # See:
        # https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#release-notes-a-spec-f-spec-ptx-feature-release-history

        # Most tcgen05.mma instructions are supported on the full family
        default_targets = [TargetSm("100f"), TargetSm("110f")]

        if operands is None or design is None:
            return default_targets

        A = getattr(operands, "A", None)
        tile_shape = getattr(design, "tile_shape", None)
        if A is None:
            raise NotImplementedError(
                f"Could not determine MMA operand A for {type(operands)}"
            )
        if tile_shape is None:
            raise NotImplementedError(
                f"Could not determine MMA tile shape for {type(design)}"
            )

        if A.dtype in [cutlass.Int8, cutlass.Uint8]:
            # Only 100a, 110a support int types with tcgen05.mma
            return [TargetSm("100a"), TargetSm("110a")]

        # tile K == 96 is only supported on sm103a
        if tile_shape[2] == 96:
            return [TargetSm("103a")]

        return default_targets

    @staticmethod
    def shape_k(
        operands: OperandsMetadata,
    ) -> int:
        """See :meth:`MmaInstruction.shape_k`."""
        try:
            A = operands.A
            B = operands.B
        except AttributeError as err:
            raise AttributeError(
                f"{type(operands)} does not have attributes for operands `A` and `B`"
            ) from err

        if A.dtype in [cutlass.Float32, cutlass.TFloat32]:
            return 8
        elif A.dtype in [cutlass.Float16, cutlass.BFloat16]:
            return 16
        elif A.dtype in [cutlass.Int8, cutlass.Uint8]:
            return 32
        elif A.dtype == cutlass.Float4E2M1FN and B.dtype == cutlass.Float4E2M1FN:
            return 64
        elif A.dtype in [
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
            cutlass.Float6E3M2FN,
            cutlass.Float6E2M3FN,
            cutlass.Float4E2M1FN,
        ]:
            return 32
        else:
            raise NotImplementedError(f"Unsupported operand dtype: {A.dtype}")


class BlackwellTcgen05MmaSparse(MmaInstruction):
    """Models the tcgen05.mma.sp instruction for the Blackwell architecture."""

    @staticmethod
    def supported_targets(
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """See :meth:`MmaInstruction.supported_targets`."""
        raise NotImplementedError


class HopperWgmma(MmaInstruction):
    """Models the wgmma Tensor Core MMA instruction for the Hopper architecture."""

    @staticmethod
    def supported_targets(
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """See :meth:`MmaInstruction.supported_targets`."""
        return [TargetSm("90a")]


class AmpereMma(MmaInstruction):
    """Models the Tensor Core MMA instruction for the Ampere architecture."""

    @staticmethod
    def supported_targets(
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """See :meth:`MmaInstruction.supported_targets`."""
        return [TargetSm(cc=80)]
