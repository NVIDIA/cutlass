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

import copy
from abc import ABC, abstractmethod
from dataclasses import dataclass, field, fields
from types import EllipsisType  # noqa: TC003
from typing import Any, final

from cutlass.operators.typing import SupportsConversionToInternalTypes
from cutlass.operators.utils.dtype import to_cutlass_type
from cutlass.operators.utils.tensor import TensorWrapper


@dataclass
class RuntimeArguments(SupportsConversionToInternalTypes):
    """Describes the operands and all other arguments passed to an Operator at runtime.

    It contains runtime operands (usually tensors) passed to the operation, as well as
    any custom epilogue fusions, and runtime performance controls.

    This is an abstract base class, whose subclass describes the operation type itself
    (e.g. GemmArguments, GroupedGemmArguments, etc.). All operators that implement the same
    operation type accept the same RuntimeArguments subclass.
    """

    performance: PerformanceControls | None | EllipsisType = field(
        default=..., kw_only=True
    )
    """Optional runtime performance controls passed to the Operator.

    ``...`` (the default) expresses no opinion, and every operator matches.
    ``None`` asks for an operator that exposes no performance controls at all.
    """

    @classmethod
    def _tensor_like_field_names(cls) -> tuple[str, ...]:
        """Names of fields holding a ``TensorLike`` value that must be wrapped in a ``TensorWrapper``.

        Declared explicitly per subclass, rather than inferred from the field's type
        annotation via ``typing.get_type_hints``, to avoid the cost of resolving
        postponed annotations (this module uses ``from __future__ import
        annotations``) on every construction. Override in subclasses that have such
        fields; the default is none.
        """
        return ()

    @classmethod
    def _numeric_like_field_names(cls) -> tuple[str, ...]:
        """Names of fields holding a ``NumericLike`` value that must be converted to ``cutlass.Numeric``.

        See :meth:`_tensor_like_field_names` for why this is declared explicitly.
        """
        return ()

    def _validate(self):
        """Checks that the arguments are valid.

        This is run before all fields have been converted to TensorWrapper and cutlass.Numeric.
        """

    def __post_init__(self):
        _convert_to_internal_types(self)


@dataclass
class PerformanceControls:
    """Optional runtime performance controls passed to the Operator.

    Some operators may support performance options that can be controlled at runtime.
    This class is the general container for all such controls.
    """


class Operand(ABC, SupportsConversionToInternalTypes):
    """Base class for all operands to Operators, which encapsulates one or more TensorLike objects.

    In the most basic case, an Operand enacapsulates a single tensor.

    In more complex cases, an Operand may encapsulate multiple tensors that encapsulate a single logical operand.
    For instance, a :class:`~cutlass.operators.ScaledOperand` encapsulates a quantized and scale tensor, that together
    reconstruct the logical value of the operand.
    """

    @final
    def copy(self) -> Operand:
        """Returns a copy of the operand. Does not copy the underlying tensor."""
        return self.__copy__()

    @abstractmethod
    def __copy__(self) -> Operand:
        """Returns a copy of the operand. Does not copy the underlying tensor."""
        raise NotImplementedError

    @classmethod
    def _tensor_like_field_names(cls) -> tuple[str, ...]:
        """Names of fields holding a ``TensorLike`` value that must be wrapped in a ``TensorWrapper``.

        See :meth:`RuntimeArguments._tensor_like_field_names` for why this is
        declared explicitly rather than inferred from the field's type annotation.
        """
        return ()

    @classmethod
    def _numeric_like_field_names(cls) -> tuple[str, ...]:
        """Names of fields holding a ``NumericLike`` value that must be converted to ``cutlass.Numeric``.

        See :meth:`RuntimeArguments._tensor_like_field_names` for why this is
        declared explicitly rather than inferred from the field's type annotation.
        """
        return ()

    def _convert_to_internal_types(self, metadata: dict[str, Any] = None):
        _convert_to_internal_types(self, metadata=metadata)


def _convert_to_internal_types(
    caller: SupportsConversionToInternalTypes, metadata: dict[str, Any] = None
):
    """Converts fields of the caller to internal types.

    Current fields that are converted:
    * ``TensorLike`` -> ``TensorWrapper``
    * ``NumericLike`` -> ``cutlass.Numeric``
    * Classes that implement ``_convert_to_internal_types`` -> their internal types

    Which fields are ``TensorLike``/``NumericLike`` is determined by
    ``type(caller)._tensor_like_field_names()``/``_numeric_like_field_names()``
    rather than by inspecting the field's type annotation, since resolving
    postponed annotations via ``typing.get_type_hints`` on every call is expensive
    and depends only on the (statically known) class.

    Args:
        caller (Any): The caller object to convert the fields of.
        metadata (dict[str, Any] | None): Additional metadata to be used for conversion
    """
    cls = type(caller)
    tensor_like_fields = cls._tensor_like_field_names()
    numeric_like_fields = cls._numeric_like_field_names()
    for f in fields(caller):
        value = getattr(caller, f.name)

        global_metadata = {} if metadata is None else copy.deepcopy(metadata)
        global_metadata.update(f.metadata)

        if isinstance(value, TensorWrapper):
            # No conversion needed
            setattr(caller, f.name, value)
        elif f.name in tensor_like_fields:
            # Wrap fields declared as TensorLike in TensorWrapper
            setattr(caller, f.name, TensorWrapper(value, **global_metadata))
        elif f.name in numeric_like_fields:
            # Convert fields declared as NumericLike to cutlass.Numeric
            setattr(caller, f.name, to_cutlass_type(value))
        elif hasattr(value, "_convert_to_internal_types"):
            # If the field is an instance of a class that implements
            # _convert_to_internal_types, convert it to internal types
            value._convert_to_internal_types(metadata=global_metadata)
            setattr(caller, f.name, value)
