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

from dataclasses import dataclass
from typing import TYPE_CHECKING, Literal

from cutlass.operators.arguments import (
    IndexPtrGroupedGemmArguments,
    RuntimeArguments,
)
from cutlass.operators.metadata.operands.base import OperandsMetadata
from cutlass.operators.status import Status

if TYPE_CHECKING:
    from cutlass.cute.typing import Numeric

    from cutlass.operators.metadata.operand_constraints import OperandConstraints



@dataclass
class IndexPtrGroupedGemmOperandsMetadata(OperandsMetadata):
    """Operand constraints for M/N/K index-pointer grouped GEMM operations."""

    A: OperandConstraints
    """Constraints on dense operand ``A``."""

    B: OperandConstraints
    """Constraints on dense operand ``B``."""

    out: OperandConstraints
    """Constraints on dense operand ``out``."""

    offsets: OperandConstraints
    """Constraints on the grouped-problem boundary tensor."""

    offsets_along: Literal["m", "n", "k"]
    """Logical GEMM dimension partitioned by ``offsets``."""

    accumulator_type: Numeric
    """Required accumulator data type."""

    def supports(
        self,
        other: RuntimeArguments | IndexPtrGroupedGemmOperandsMetadata,
    ) -> Status:
        """Check index-pointer arguments or peer metadata for compatibility."""
        if not isinstance(
            other,
            (
                IndexPtrGroupedGemmArguments,
                IndexPtrGroupedGemmOperandsMetadata,
            ),
        ):
            return Status.fail(
                f"Expected IndexPtrGroupedGemmArguments, got {type(other)}"
            )

        if not (status := self.A.supports(other.A)):
            return Status.fail(f"Operand `A` is unsupported: {status.error}")
        if not (status := self.B.supports(other.B)):
            return Status.fail(f"Operand `B` is unsupported: {status.error}")
        if not (status := self.out.supports(other.out)):
            return Status.fail(f"Operand `out` is unsupported: {status.error}")
        if not (status := self.offsets.supports(other.offsets)):
            return Status.fail(f"Operand `offsets` is unsupported: {status.error}")
        if self.offsets_along != other.offsets_along:
            return Status.fail(
                f"Expected offsets_along {self.offsets_along!r}, "
                f"got {other.offsets_along!r}"
            )
        if self.accumulator_type != other.accumulator_type:
            return Status.fail(
                f"Expected accumulator type {self.accumulator_type}, "
                f"got {other.accumulator_type}"
            )

        return Status.success()


@dataclass(init=False)
class GroupedGemmOperandsMetadata(IndexPtrGroupedGemmOperandsMetadata):
    """Compatibility metadata for the released M-offset grouped GEMM API."""

    def __init__(
        self,
        A: OperandConstraints,
        B: OperandConstraints,
        out: OperandConstraints,
        offsets: OperandConstraints,
        accumulator_type: Numeric,
    ):
        super().__init__(
            A=A,
            B=B,
            out=out,
            offsets=offsets,
            offsets_along="m",
            accumulator_type=accumulator_type,
        )
