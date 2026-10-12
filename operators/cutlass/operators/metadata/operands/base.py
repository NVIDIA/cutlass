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

if TYPE_CHECKING:
    from cutlass.operators.arguments import RuntimeArguments
    from cutlass.operators.status import Status


@dataclass
class OperandsMetadata(ABC):
    """Describes properties expected of the logical operands passed to an Operator.

    It describes the conditions under which an Operator can correctly execute
    a given :class:`~cutlass.operators.RuntimeArguments`.
    It mirrors the fields of a :class:`~cutlass.operators.RuntimeArguments` subclass implemented by
    the Operator, and describes requirements placed on each field. For instance,
    :class:`~cutlass.operators.metadata.GemmOperandsMetadata` mirrors
    :class:`~cutlass.operators.GemmArguments`.

    | :class:`~cutlass.operators.RuntimeArguments` describes what operation the user wishes
      to perform, independent of which Operator will perform it.
    | ``OperandsMetadata`` describes conditions under which an :class:`~cutlass.operators.Operator`
      can accept and correctly execute :class:`~cutlass.operators.RuntimeArguments` passed to it.

    If an Operator's ``OperandsMetadata`` supports the ``RuntimeArguments`` presented by a user, then
    it produces functionally correct result for those RuntimeArguments.
    """

    @abstractmethod
    def supports(self, args: RuntimeArguments) -> Status:
        """Check whether ``args`` satisfy the operand requirements described by this metadata.

        Args:
            args (RuntimeArguments): Runtime arguments to validate.

        Returns:
            Status: Status indicating whether ``args`` satisfy the operand
            requirements described by this metadata.
        """
