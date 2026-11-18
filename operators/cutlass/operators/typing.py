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

"""Type markers for CUTLASS Operator API field annotations."""

from __future__ import annotations

from typing import Any, Generic, Protocol, TypeAlias, TypeVar, runtime_checkable

import cutlass.cute as cute

from cutlass.operators.utils.tensor import TensorWrapper

_ValueT = TypeVar("_ValueT")


@runtime_checkable
class _SupportsDLPack(Protocol):
    """Protocol for Tensor-like objects that support the DLPack protocol.

    CUTLASS Operator API supports tensor-like objects (e.g., torch.Tensor, cute.Tensor) that
    implement ``__dlpack__`` and ``__dlpack_device__``.
    """

    def __dlpack__(self, *, stream: Any = None) -> Any:
        """Return a DLPack capsule representing the tensor data."""
        ...

    def __dlpack_device__(self) -> tuple[int, int]:
        """Return the device type and device id as a tuple."""
        ...


TensorLike: TypeAlias = _SupportsDLPack | cute.Tensor | TensorWrapper
"""Tensor-like inputs accepted by the Operator API.

Includes:
    * Any DLPack-compatible tensor (``torch.Tensor``, ``jax.Array``, ``numpy.ndarray``, ...).
    * ``cutlass.cute.Tensor`` (CuTe DSL host tensor; does not implement DLPack but is handled natively by ``TensorWrapper``).
    * ``cutlass.operators.utils.tensor.TensorWrapper`` (implements DLPack).
"""


class NumericLike(Protocol):
    """Type marker for fields that accept numeric-like types.

    Fields annotated with NumericLike accept the following:
        * ``cutlass.Numeric``
        * ``torch.dtype``
    """


class AnyValue(Generic[_ValueT]):
    """A domain that contains every value of type ``_ValueT``."""

    def __init__(self, value_type: type[_ValueT]) -> None:
        self.value_type = value_type

    def __contains__(self, value: object) -> bool:
        """Return whether ``value`` belongs to this domain, which is always true."""
        return True

    def __repr__(self) -> str:
        return f"AnyValue[{self.value_type.__name__}]"


class SupportsConversionToInternalTypes(Protocol):
    """Protocol for objects that support conversion to internal Cutlass Operator types.

    Used by RuntimeArguments and Operand classes.
    """

    def _tensor_like_field_names(self) -> tuple[str, ...]:
        """Names of fields holding a ``TensorLike`` value that must be wrapped in a ``TensorWrapper``.

        e.g. torch.tensor
        """
        ...

    def _numeric_like_field_names(self) -> tuple[str, ...]:
        """Names of fields holding a ``NumericLike`` value that must be converted to ``cutlass.Numeric``.

        e.g. torch.dtype
        """
        ...
