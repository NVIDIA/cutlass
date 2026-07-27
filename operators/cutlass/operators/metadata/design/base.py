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

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import TYPE_CHECKING

from cutlass.operators.status import Status

if TYPE_CHECKING:
    from cutlass.operators.arguments import RuntimeArguments
    from cutlass.operators.mma import MmaInstruction


@dataclass
class DesignMetadata(ABC):
    """Describes architectural, performance, or design characteristics of the kernel separate from its functional contribution.

    These properties do not directly alter the logical result of the Operator.
    Instead, they distinguish the design characteristics of otherwise logically-equivalent Operators,
    and can be used to guide Operator selection and performance characterization.

    This could include properties like:

    * inherent design choices like which MMA instruction it uses, or use of other architectural features
    * its performance options, tile scheduling algorithm, etc.
    * its tile shape, cluster shape, number of shared memory stages, etc.
    """

    @abstractmethod
    def supports(self, args: RuntimeArguments) -> Status:
        """Checks whether the provided ``args`` satisfy the properties described by this DesignMetadata.

        It validates that :class:`~cutlass.operators.PerformanceControls` within
        ``args.performance`` are supported by the Operator with this DesignMetadata.

        ``DesignMetadata`` does not directly influence the logical result of the Operator,
        and thus does not affect what logical operands can be supported in ``RuntimeArguments``.

        Args:
            args (RuntimeArguments): The arguments to check support for.

        Returns:
            Status: Status indicating whether the provided args satisfy the properties described by the design in this metadata
        """


@dataclass(kw_only=True)
class BLASDesignMetadata(DesignMetadata):
    """Design metadata for a BLAS (basic-linear algebra subprogram) operation, like GEMM.

    It describes fields common to many kernels that perform BLAS-like operations, such as
    tile/cluster shape, MMA instruction type, etc.
    """

    mma_instruction_type: type[MmaInstruction]
    """The type of the MMA instruction used by the Operator, if any."""

    tile_shape: tuple[int, ...]
    """Shape of the threadblock-level tile"""

    cluster_shape: tuple[int, ...]
    """Shape of the cluster used in terms of threadblocks"""

    num_smem_stages: int | None = None
    """Number of shared memory buffers used to pipeline data loading and computation.
    When None, the Operator determines this internally."""

    def supports(self, args: RuntimeArguments) -> Status:
        """Checks whether the provided args satisfy the properties described by the design in this metadata.

        Args:
            args (RuntimeArguments): The arguments to check support for

        Returns:
            Status: Status indicating whether the provided args satisfy the properties described by the design in this metadata
        """
        if args.performance is not None:
            return Status.fail(
                "BLASDesignMetadata does not yet support performance controls"
            )
        return Status.success()
