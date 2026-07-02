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
from typing import TYPE_CHECKING, Any

import cutlass.operators.utils as utils
from cutlass.operators.arguments import (
    DenseTensor,
    Operand,
    ScaledOperand,
    ScaleMode,
    ScaleSwizzleMode,
)
from cutlass.operators.status import Status

if TYPE_CHECKING:
    from cutlass.cute.typing import Numeric


class OperandConstraints(ABC):
    """Abstract base class describing the constraints an Operator places on an Operand.

    An instance of this class describes the requirements an Operator
    places on one :class:`~cutlass.operators.arguments.Operand`, such as
    its data type, stride pattern, divisibility, and pointer alignment.
    """

    @abstractmethod
    def supports(self, operand: Operand | OperandConstraints) -> Status:
        """Check whether ``operand`` satisfies these constraints.

        Args:
            operand (Operand | OperandConstraints): The runtime operand or
                another constraints object to check against ``self``.

        Returns:
            Status: ``Status.success()`` when ``operand`` is accepted, otherwise
            ``Status.fail(...)`` with a human-readable reason.
        """


@dataclass
class DenseTensorConstraints(OperandConstraints):
    """Constraints on a single :class:`~cutlass.operators.arguments.DenseTensor`.

    Describes the data type, stride pattern, divisibility, and pointer alignment
    that an Operator requires a :class:`~cutlass.operators.arguments.DenseTensor` to satisfy.
    """

    dtype: Numeric
    """The data type of the tensor"""

    stride: tuple[int, ...] | None
    """The stride of the tensor. If none, any arbitrary stride is allowed."""

    divisibility: int
    """The divisibility requirement on a tensor's stride and shape elements"""

    ptr_alignment_bytes: int
    """The alignment of the tensor's data pointer, in bytes
    By default, it matches the number of bytes in stride/shape alignment.
    """

    def __init__(
        self,
        dtype: Numeric,
        stride: tuple[int, ...],
        divisibility: int,
        ptr_alignment_bytes: int | None = None,
    ):
        self.dtype = dtype
        self.stride = stride
        self.divisibility = divisibility
        self.ptr_alignment_bytes = ptr_alignment_bytes or (
            (divisibility * dtype.width) // 8
        )

    def supports(self, operand: DenseTensor | DenseTensorConstraints) -> Status:
        """Check whether ``operand`` satisfies the constraints described by this object.

        Args:
            operand (Operand | OperandConstraints): Operand or peer
                constraints object to validate.

        Returns:
            Status: ``Status.success()`` if accepted, ``Status.fail(...)``
            otherwise.
        """
        is_operand = isinstance(operand, DenseTensor)
        is_constraint = isinstance(operand, DenseTensorConstraints)
        if not (is_operand or is_constraint):
            return Status.fail(
                f"Expected DenseTensor or DenseTensorConstraints, got {type(operand)}"
            )

        if operand.dtype != self.dtype:
            return Status.fail(
                f"Expected element type {self.dtype}, got {operand.dtype}"
            )

        if self.stride is None:
            major_mode_idx = (
                utils.tensor.major_mode(operand.shape, operand.stride)
                if is_operand
                else None
            )
        else:
            # If the operand is batched, the expected stride is the same as the self.stride
            if len(self.stride) == len(operand.stride):
                expected_stride = self.stride
            # We can try if strides match without the batch mode
            elif len(self.stride) - 1 == len(operand.stride):
                expected_stride = self.stride[1:]
            else:
                return Status.fail(
                    f"Expected tensor with strides of rank {len(self.stride)} (batched) or "
                    f"{len(self.stride) - 1} (unbatched), got {len(operand.stride)} "
                    f"({operand.stride})"
                )

            # Strides are considered compatible if:
            #  1. They have the same rank (checked above)
            #  2. The major mode is the same

            # When setting stride from args, any modes of stride 1 and shape 1
            # are changed to have stride 0. Thus, there will only be one mode
            # with stride 1.
            major_mode_idx = expected_stride.index(1)
            if operand.stride[major_mode_idx] != 1:
                return Status.fail(
                    f"Expected stride[{major_mode_idx}] to be 1, got "
                    f"{operand.stride[major_mode_idx]} "
                    f"(strides: {operand.stride})"
                )

        # Check that divisibility constraints are met
        if is_operand:
            if not self._is_tuple_aligned(
                operand.stride, self.divisibility, major_mode_idx
            ):
                return Status.fail(
                    f"Expected operand stride to be divisible by {self.divisibility} for "
                    f"all non-contiguous modes, got {operand.stride}"
                )
        else:
            # When comparing another DenseTensorConstraints, ensure its divisibility
            # is a refinement (i.e. a multiple) of ours.
            if operand.divisibility % self.divisibility != 0:
                return Status.fail(
                    f"Expected operand divisibility {operand.divisibility} to be divisible "
                    f"by {self.divisibility}"
                )

        # Check data ptr alignment, if available
        if is_operand and operand.data_ptr % self.ptr_alignment_bytes != 0:
            return Status.fail(
                f"Expected data pointer to be {self.ptr_alignment_bytes}B-aligned."
            )

        return Status.success()

    def _is_tuple_aligned(
        self, tup: tuple[int, ...], divisibility: int, contiguous_dim: int
    ) -> bool:
        """Check that all elements of ``tup`` are divisible by ``divisibility``.

        The element at ``contiguous_dim`` is 1, and so is exempt from the check.
        """
        return all(
            t % divisibility == 0 for dim, t in enumerate(tup) if dim != contiguous_dim
        )


@dataclass
class ScaledOperandConstraints(OperandConstraints):
    """Constraints on a scaled (quantized + scale-factor) operand.

    A scaled operand combines a quantized tensor and a scale tensor with a
    chosen scale mode + scale swizzle. Constraints on each piece are carried
    in :attr:`quantized` and :attr:`scale`; :meth:`supports` checks all four.
    """

    quantized: DenseTensorConstraints
    """Constraints on the narrow-precision tensor holding the quantized values."""

    scale: DenseTensorConstraints
    """Constraints on the scale-factor tensor."""

    mode: ScaleMode | tuple[int, ...]
    """Descriptor of the elements over which each scale factor operates"""

    swizzle: ScaleSwizzleMode
    """Swizzling pattern used within scale factor tensor"""

    def supports(self, operand: ScaledOperand | ScaledOperandConstraints) -> Status:
        """Check whether ``operand`` satisfies these scaled-operand constraints."""
        if not isinstance(operand, (ScaledOperand, ScaledOperandConstraints)):
            return Status.fail(
                f"Expected ScaledOperand or ScaledOperandConstraints, got {type(operand)}"
            )

        if not (status := self.quantized.supports(operand.quantized)):
            return status

        if not (status := self.scale.supports(operand.scale)):
            return status

        if not ScaleMode.compare(self.mode, operand.mode):
            return Status.fail(f"Expected scale mode {self.mode}, got {operand.mode}")

        if self.swizzle != operand.swizzle:
            return Status.fail(
                f"Expected scale swizzle mode {self.swizzle}, got {operand.swizzle}"
            )

        return Status.success()

    def __getattr__(self, attr: str) -> Any:
        if hasattr(self.quantized, attr):
            return getattr(self.quantized, attr)
        else:
            raise AttributeError(
                f"'{self.__class__.__name__}' object has no attribute '{attr}'"
            )


