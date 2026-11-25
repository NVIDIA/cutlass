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

from cutlass.operators.arguments import PerGroupScaleEpilogueArguments
from cutlass.operators.status import Status

if TYPE_CHECKING:
    import cutlass.cute as cute
    from cutlass.cute.typing import Numeric

    from cutlass.operators.arguments import (
        EpilogueArguments,
        RuntimeArguments,
    )
    from cutlass.operators.metadata.operand_constraints import DenseTensorConstraints


class EpilogueMetadataBase(ABC):
    """Common metadata interface for custom and fixed epilogues."""

    @abstractmethod
    def supports(self, args: RuntimeArguments) -> Status:
        """Check whether runtime arguments satisfy this epilogue metadata."""
        raise NotImplementedError


class EpilogueMetadata(EpilogueMetadataBase):
    """Describes properties related to custom EpilogueArguments that an Operator may support."""

    def __init__(self, epilogue_args: EpilogueArguments):
        self.traced_epilogue = epilogue_args.traced_epilogue
        self.tensors = epilogue_args.tensors
        self.epilogue_fn = epilogue_args.epilogue_fn
        # Per-parameter Load/Store transport descriptors (empty when the user
        # passed only bare tensors).
        self.transports = getattr(epilogue_args, "transports", {})

    @classmethod
    def from_args(cls, args: EpilogueArguments) -> EpilogueMetadata:
        """Creates an EpilogueMetadata from an EpilogueArguments."""
        # For now, EpilogueArguments and EpilogueMetadata are the same
        return cls(args)

    @property
    def parameters(self) -> list[cute.Tensor | Numeric]:
        """Returns the list of input and output parameters of the epilogue."""
        return list(self.tensors.values())

    @property
    def parameter_names(self) -> list[str]:
        """Returns the list of names of the input and output parameters of the epilogue."""
        return list(self.tensors.keys())

    def supports(self, args: RuntimeArguments) -> Status:
        """Checks if the provided EpilogueArguments are supported by the Operator."""
        return Status.success()


@dataclass
class PerGroupScaleEpilogueMetadata(EpilogueMetadataBase):
    """Constraints for a :class:`PerGroupScaleEpilogueArguments` fixed epilogue."""

    global_scale_a: DenseTensorConstraints | None = None
    """Constraints for A's per-group scale, or None when the scale is omitted."""
    global_scale_b: DenseTensorConstraints | None = None
    """Constraints for B's per-group scale, or None when the scale is omitted."""

    def supports(self, args: RuntimeArguments) -> Status:
        """Check whether runtime arguments provide compatible per-group scales."""
        epilogue = getattr(args, "epilogue", None)
        if not isinstance(epilogue, PerGroupScaleEpilogueArguments):
            return Status.fail(
                "Expected PerGroupScaleEpilogueArguments, "
                f"got {type(epilogue).__name__}"
            )
        for name in ("global_scale_a", "global_scale_b"):
            constraints = getattr(self, name)
            scale = getattr(epilogue, name)
            if (constraints is not None) != (scale is not None):
                return Status.fail(f"{name} presence must match the metadata.")
            if constraints is not None and not (status := constraints.supports(scale)):
                return Status.fail(f"{name} is unsupported: {status.error}")
        return Status.success()
