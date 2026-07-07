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

if TYPE_CHECKING:
    from cutlass.operators.typing import TensorLike


@dataclass
class Workspace:
    """Container for a user-provided memory allocation used by an Operator.

    A workspace is a user-provided, contiguous block of memory some Operators may use to store intermediate results,
    which may be used by the underlying kernel for any temporary storage, book keeping, intermediate results, semaphores etc.
    The workspace is typically allocated by the user and passed to the Operator via the :meth:`Operator.run` method.
    """

    data: TensorLike | int
    """Tensor holding workspace data, or an integer address of the start of the workspace."""

    leading_zero_bytes: int = 0
    """Number of bytes from the beginning of the workspace have been set to zero by user."""


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
