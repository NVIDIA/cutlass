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

from cutlass.operators.arch import TargetSm
from cutlass.operators.status import Status

if TYPE_CHECKING:
    from cutlass.operators.arguments import RuntimeArguments
    from cutlass.operators.base import Operator
    from cutlass.operators.metadata.design import DesignMetadata
    from cutlass.operators.metadata.epilogue import EpilogueMetadata
    from cutlass.operators.metadata.operands import OperandsMetadata
    from cutlass.operators.providers import Provider


@dataclass
class OperatorMetadata:
    """OperatorMetadata exposes a uniform schema to inspect the properties of an Operator.

    It allows users to programmatically and uniformly inspect properties of an
    Operator without manually inspecting its source code, and without learning
    a different schema of properties for each Operator.

    It describes fixed properties of the Operator in three categories:

    - :class:`~cutlass.operators.metadata.OperandsMetadata`: properties of the
      operands passed to the Operator and the constraints it places on them.
      It describes the conditions for an Operator to functionally support
      (compute the correct result of) an operation.
    - :class:`~cutlass.operators.metadata.DesignMetadata`: architectural,
      performance, or design characteristics of the kernel. Useful for
      inspecting and comparing otherwise functionally equivalent Operators.
    - :class:`~cutlass.operators.metadata.EpilogueMetadata`: any custom epilogue
      computation that was fused into the Operator.

    These properties are declared by the ``Operator`` itself when it is instantiated,
    and are fixed after that.

    They may be determined by design, or the Operator's implementation may be parametrized
    to generate instances supporting different values of a metadata field.
    """

    operator_name: str
    """A unique human-readable Operator name.

    Important:
        There are no backward-compatibility guarantees for these names, even for
        patch releases. Users are strongly advised to not use these names for
        filtering, and use metadata fields instead.
    """

    operator_class: type[Operator]
    """The derived class of cutlass.operators.Operator that implements interfaces to expose a DSL kernel"""

    supported_targets: list[TargetSm]
    """Supported targets that this Operator can be compiled for

    Only the earliest portable target in each architecture family is reported,
    as support for future targets is implied.

    Examples:
        * ``supported_targets=[TargetSm("100f"), TargetSm("120f")]`` implies support for ``["100a", "103a", ... , "120a", "121a", ...]`` for all members of ``100f`` & ``120f`` arch families
        * ``supported_targets=[TargetSm("80")]`` implies support for ``["80","89","90","90a","100", ...]``

    To check if this Operator is supported on a desired target_sm, use ``target_sm.supports_operators_from(supported_targets)``.
    """

    operands: OperandsMetadata
    """Describes the per-operand requirements of the Operator: per-operand
    constraints and any operand-independent choices (e.g. the accumulator
    type for a GEMM)."""

    design: DesignMetadata | None = None
    """Describes characteristics of the design & implementation of the Operator"""

    epilogue: EpilogueMetadata | None = None
    """Describes the custom epilogue of the Operator."""

    @property
    def provider(self) -> Provider:
        """The :class:`~cutlass.operators.Provider` that this Operator's class is registered with."""
        return self.operator_class._provider

    def supports(
        self, args: RuntimeArguments | None, *, target_sm: TargetSm | str | None = None
    ) -> Status:
        """Check if the provided ``args``/``target_sm`` satisfy the properties described by this OperatorMetadata.

        Args:
            args (RuntimeArguments | None): Check if Operator supports these RuntimeArguments. Can be explicitly
                set to None, in order to check only target_sm.
            target_sm (TargetSm | str | None): Check if Operator can be compiled/ran on given TargetSm architecture, if any.

        Returns:
            Status: Status indicating whether the args/target_sm are supported, and reason for
            failure if not.

        Raises:
            ValueError: If both args and target_sm are None.
        """
        if args is None and target_sm is None:
            raise ValueError("Either args or target_sm must be provided")

        if target_sm is not None:
            target_sm = TargetSm.ensure(target_sm)
            if not target_sm.supports_operators_from(self.supported_targets):
                return Status.fail(
                    f"Operator cannot be compiled for target {target_sm}. "
                    f"Supported targets: {self.supported_targets}"
                )

        if args is None:
            return Status.success()

        # check args

        def supports_or_none(member, corresponding_arg, name: str) -> Status:
            # If metadata is absent, accept only when the corresponding argument is also absent.
            if member is None:
                if corresponding_arg is None:
                    return Status.success()
                return Status.fail(
                    f"{name} metadata is absent but argument is provided"
                )
            return member.supports(args)

        if not (status := self.operands.supports(args)):
            return status

        if not (status := supports_or_none(self.design, args.performance, "design")):
            return status

        if not (
            status := supports_or_none(
                self.epilogue, getattr(args, "epilogue", None), "epilogue"
            )
        ):
            return status

        return Status.success()
