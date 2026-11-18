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

from __future__ import annotations

from collections.abc import Iterable
from dataclasses import dataclass
from typing import TYPE_CHECKING

from cutlass.operators.status import Status

if TYPE_CHECKING:
    from cutlass.operators.arguments.pdl import ProgrammaticDependentLaunchControl


@dataclass(frozen=True, slots=True)
class ProgrammaticDependentLaunchMetadata:
    """Describe a kernel's Programmatic Dependent Launch (PDL) capabilities.

    PDL allows a dependent kernel to begin executing before its producer has
    completed. A launch can use same-stream serialization, a programmatic CUDA
    event, or both.

    * ``early_launch_dependent`` indicates whether the kernel can signal
      dependent kernels.
    * ``early_start`` indicates whether the kernel can start as a consumer
      before its producer completes.

    .. _Programmatic Dependent Launch: https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/programmatic-dependent-launch.html
    """

    early_launch_dependent: bool = False
    """Whether this kernel supports signaling dependent kernels for early launch."""

    early_start: EarlyStartMetadata | None = None
    """Whether the kernel can start before its producer completes.

    Optional independent operands may load without waiting for the producer.
    """

    def supports(
        self,
        runtime_pdl_controls: ProgrammaticDependentLaunchControl | None,
    ) -> Status:
        """Check whether PDL metadata supports the requested runtime controls."""
        if runtime_pdl_controls is None:
            return Status.success()

        if not runtime_pdl_controls.is_enabled():
            return Status.success()

        if runtime_pdl_controls.early_launch_dependent is not None and not (
            self.early_launch_dependent
        ):
            return Status.fail(
                "Requested PDL early launch but the kernel does not support it"
            )

        runtime_early_start = runtime_pdl_controls.early_start
        if runtime_early_start is None:
            return Status.success()
        if self.early_start is None:
            return Status.fail(
                "Requested PDL early start but the kernel does not support it"
            )

        compiled_independent_operands = set(self.early_start.independent_operands)
        runtime_independent_operands = set(runtime_early_start.independent_operands)
        unsupported_independent_operands = (
            compiled_independent_operands - runtime_independent_operands
        )
        if unsupported_independent_operands:
            return Status.fail(
                "Metadata may load PDL operands "
                f"{sorted(unsupported_independent_operands)} independently, but "
                "the runtime arguments declare those operands dependent"
            )

        return Status.success()

    def is_enabled(self) -> bool:
        """Whether PDL is enabled."""
        return self.early_launch_dependent or self.early_start is not None


@dataclass(frozen=True, slots=True)
class EarlyStartMetadata:
    """Metadata for compiling a kernel with PDL early-start support."""

    independent_operands: Iterable[str] = ()
    """Operands that may load without waiting on the PDL dependency.

    An empty iterable means all operands are dependent and must wait. The names
    are validated against the kernel's declared operands by
    :class:`~cutlass.operators.metadata.OperatorMetadata`.
    """

    def __post_init__(self) -> None:
        if isinstance(self.independent_operands, str) or not isinstance(
            self.independent_operands, Iterable
        ):
            raise ValueError(
                "PDL independent_operands must be an iterable of operand names, "
                "not a string"
            )

        independent_operands = tuple(self.independent_operands)
        if any(not isinstance(name, str) for name in independent_operands):
            raise ValueError("PDL independent operand names must be strings")
        object.__setattr__(self, "independent_operands", independent_operands)
