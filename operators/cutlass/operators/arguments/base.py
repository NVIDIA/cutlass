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
from typing import Any, final, get_type_hints

from cutlass.operators.typing import NumericLike, TensorLike
from cutlass.operators.utils.dtype import to_cutlass_type
from cutlass.operators.utils.tensor import TensorWrapper


@dataclass
class RuntimeArguments:
    """Describes the operands and all other arguments passed to an Operator at runtime.

    It contains runtime operands (usually tensors) passed to the operation, as well as
    any custom epilogue fusions, and runtime performance controls.

    This is an abstract base class, whose subclass describes the operation type itself
    (e.g. GemmArguments, GroupedGemmArguments, etc.). All operators that implement the same
    operation type accept the same RuntimeArguments subclass.
    """

    performance: PerformanceControls | None = field(default=None, kw_only=True)
    """Optional runtime performance controls passed to the Operator"""

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


class Operand(ABC):
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

    def _convert_to_internal_types(self, metadata: dict[str, Any] = None):
        _convert_to_internal_types(self, metadata=metadata)


def _convert_to_internal_types(caller, metadata: dict[str, Any] = None):
    """Converts fields of the caller to internal types.

    Current fields that are converted:
    * ``TensorLike`` -> ``TensorWrapper``
    * ``NumericLike`` -> ``cutlass.Numeric``
    * Classes that implement ``_convert_to_internal_types`` -> their internal types

    Args:
        caller (Any): The caller object to convert the fields of
        metadata (dict[str, Any] | None): Additional metadata to be used for conversion
    """
    type_hints = get_type_hints(type(caller))
    for f in fields(caller):
        hint = type_hints.get(f.name)
        value = getattr(caller, f.name)

        global_metadata = {} if metadata is None else copy.deepcopy(metadata)
        global_metadata.update(f.metadata)

        if isinstance(value, TensorWrapper):
            # No conversion needed
            setattr(caller, f.name, value)
        elif hint is TensorLike:
            # Find all fields that are annotated as TensorLike,
            # and wrap them in TensorWrapper
            setattr(caller, f.name, TensorWrapper(value, **global_metadata))
        elif hint is NumericLike:
            # Find all fields that are annotated as NumericLike,
            # and convert them to cutlass.Numeric
            setattr(caller, f.name, to_cutlass_type(value))
        elif hasattr(value, "_convert_to_internal_types"):
            # If the field is an instance of a class that implements
            # _convert_to_internal_types, convert it to internal types
            value._convert_to_internal_types(metadata=global_metadata)
            setattr(caller, f.name, value)
