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

from typing import TYPE_CHECKING

from cutlass.operators.arch import TargetSm
from cutlass.operators.base import Operator

if TYPE_CHECKING:
    from collections.abc import Callable

    from cutlass.operators.arguments import EpilogueArguments, RuntimeArguments
    from cutlass.operators.metadata import OperatorMetadata


class Provider:
    """Base class for operator providers with common implementation for operator registration and generation.

    Concrete providers should inherit from this class to gain automatic operator registration and generation functionality.
    """

    # Keyed by supported argument type for efficient lookup.
    # Each subclass gets its own dict via __init_subclass__.
    _operator_classes_by_argtype: dict[type[RuntimeArguments], list[type[Operator]]]

    def __init_subclass__(cls, **kwargs):
        super().__init_subclass__(**kwargs)
        # Each subclass gets its own dict to avoid sharing state
        cls._operator_classes_by_argtype = {}

    @classmethod
    def generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool] | None = None,
        epilogue_args: EpilogueArguments | None = None,
        target_sm: TargetSm | str | None = None,
        args: RuntimeArguments | None = None,
    ) -> list[Operator]:
        """Return a list of operators that match the given filters.

        Args:
            metadata_filter (Callable[[OperatorMetadata], bool]): boolean filter function to apply to the metadata
            epilogue_args (EpilogueArguments | None): the epilogue arguments
            target_sm (TargetSm | str | None): compute capability of device for which operators should be compiled
            args (RuntimeArguments | None): the arguments to filter operators by. If None, all operators are considered

        Returns:
            list[Operator]: list of all supported operator configurations
        """
        target_sm = TargetSm.ensure(target_sm)

        # Determine which Operator classes to iterate over
        if args is not None:
            # Only consider Operator classes that support the requested argument type
            operator_classes_to_use = cls._operator_classes_by_argtype.get(
                type(args), []
            )
        else:
            # No filtering - use all Operator classes
            operator_classes_to_use = [
                k
                for operator_classes in cls._operator_classes_by_argtype.values()
                for k in operator_classes
            ]
        if target_sm is not None:
            operator_classes_to_use = [
                k
                for k in operator_classes_to_use
                if k.designed_for_min_cc <= target_sm.cc
            ]

        import os

        args = args if os.getenv("DISABLE_ARGUMENT_FILTERING", "0") == "0" else None

        operators_for_provider = []
        for operator_cls in operator_classes_to_use:
            operators_for_provider.extend(
                operator_cls.generate_operators(
                    metadata_filter,
                    epilogue_args=epilogue_args,
                    target_sm=target_sm,
                    args=args,
                )
            )

        return operators_for_provider

    @classmethod
    def register(cls, operator_class: type[Operator]) -> type[Operator]:
        """Register an Operator class with this provider.

        Intended to be used as a class decorator:

        .. code-block:: python

            @MyProvider.register
            class MyOperator(Operator):
                supported_args_type = MyArguments
                ...


        Args:
            operator_class (type[Operator]): the Operator class to register

        Returns:
            type[Operator]: the registered Operator class (unchanged)

        Raises:
            TypeError: if operator_class does not define supported_args_type
        """
        if not issubclass(operator_class, Operator):
            raise TypeError(
                f"class {operator_class.__name__} must inherit from Operator to register with a Provider"
            )

        # Stash the provider on the class to later report it in
        # OperatorMetadata.provider.
        # Users should read `operator.metadata.provider`, not this attribute.
        operator_class._provider = cls

        args_type = operator_class.supported_args_type
        if args_type not in cls._operator_classes_by_argtype:
            cls._operator_classes_by_argtype[args_type] = []
        cls._operator_classes_by_argtype[args_type].append(operator_class)
        return operator_class
