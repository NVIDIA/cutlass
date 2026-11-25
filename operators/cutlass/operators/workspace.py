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

from cutlass.operators.utils.tensor import TensorWrapper

if TYPE_CHECKING:
    from cutlass.operators.typing import TensorLike


@dataclass
class Workspace:
    """Container for a user-provided memory allocation used by an Operator.

    A workspace is a user-provided, contiguous block of memory some Operators may use to store intermediate results,
    which may be used by the underlying kernel for any temporary storage, book keeping, intermediate results, semaphores etc.
    The workspace is typically allocated by the user and passed to the Operator via the :meth:`Operator.run` method.
    Its size and pointer alignment must satisfy the :class:`AllocationRequirement`
    returned by :meth:`Operator.get_workspace_size`.
    """

    data: TensorLike
    """Tensor holding workspace data, converted to a :class:`TensorWrapper`."""

    alignment_bytes: int = 1
    """Minimum byte alignment guaranteed by the caller for ``data``'s pointer."""

    leading_zero_bytes: int = 0
    """Number of bytes from the beginning of the workspace have been set to zero by user."""

    def __post_init__(self) -> None:
        if (
            isinstance(self.alignment_bytes, bool)
            or not isinstance(self.alignment_bytes, int)
            or self.alignment_bytes <= 0
        ):
            raise ValueError(
                "alignment_bytes must be a positive integer, got "
                f"{self.alignment_bytes!r}"
            )
        if (
            isinstance(self.leading_zero_bytes, bool)
            or not isinstance(self.leading_zero_bytes, int)
            or self.leading_zero_bytes < 0
        ):
            raise ValueError(
                "leading_zero_bytes must be a nonnegative integer, got "
                f"{self.leading_zero_bytes!r}"
            )

        if not isinstance(self.data, TensorWrapper):
            self.data = TensorWrapper(
                self.data,
                alignment_bytes=self.alignment_bytes,
            )
        if self.data.data_ptr % self.alignment_bytes:
            raise ValueError(
                f"Workspace data pointer must be {self.alignment_bytes}B-aligned, "
                f"got address {self.data.data_ptr}."
            )


@dataclass
class AllocationRequirement:
    """Describes requirements for a user-provided memory allocation."""

    size_bytes: int
    """The minimal size (in bytes) that must be allocated assuming perfect alignment."""

    ptr_alignment: int
    """Alignment requirement for the pointer to the allocation in bytes."""

    @classmethod
    def empty(cls) -> AllocationRequirement:
        """Returns a requirement for an empty allocation."""
        return cls(size_bytes=0, ptr_alignment=1)
