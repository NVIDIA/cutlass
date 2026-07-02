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
from typing import TYPE_CHECKING

from cutlass.operators.arguments import GemmArguments, RuntimeArguments
from cutlass.operators.metadata.operands.base import OperandsMetadata
from cutlass.operators.status import Status

if TYPE_CHECKING:
    from cutlass.cute.typing import Numeric

    from cutlass.operators.metadata.operand_constraints import OperandConstraints


@dataclass
class GemmOperandsMetadata(OperandsMetadata):
    """Describes conditions under which an Operation functionally supports :class:`~cutlass.operators.GemmArguments`."""

    A: OperandConstraints
    """Constraints on operand ``A`` of the GEMM"""

    B: OperandConstraints
    """Constraints on operand ``B`` of the GEMM"""

    out: OperandConstraints
    """Constraints on operand ``out`` of the GEMM"""

    accumulator_type: Numeric
    """The required data type of the accumulator tensor"""

    def supports(self, other: GemmArguments | GemmOperandsMetadata) -> Status:
        """Check whether ``other`` arguments or metadata are compatible with GEMM operands described by this metadata.

        Args:
            other (GemmArguments | GemmOperandsMetadata): Either runtime
                :class:`~cutlass.operators.GemmArguments` or a peer ``GemmOperandsMetadata`` to
                validate.

        Returns:
            Status: ``Status.success()`` if every operand and the accumulator
            type match, otherwise ``Status.fail(...)`` with the first failing
            operand's reason.
        """
        if isinstance(other, RuntimeArguments) and not isinstance(other, GemmArguments):
            return Status.fail(f"Expected GemmArguments, got {type(other)}")

        if not (status := self.A.supports(other.A)):
            return Status.fail(f"Operand `A` is unsupported: {status.error}")

        if not (status := self.B.supports(other.B)):
            return Status.fail(f"Operand `B` is unsupported: {status.error}")

        if not (status := self.out.supports(other.out)):
            return Status.fail(f"Operand `out` is unsupported: {status.error}")

        if self.accumulator_type != other.accumulator_type:
            return Status.fail(
                f"Expected accumulator type {self.accumulator_type}, got {other.accumulator_type}"
            )

        return Status.success()
