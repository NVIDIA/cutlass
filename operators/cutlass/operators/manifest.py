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

import logging
from typing import TYPE_CHECKING

from cutlass.operators.arch import TargetSm
from cutlass.operators.providers import available_providers

if TYPE_CHECKING:
    from collections.abc import Callable

    from cutlass.operators.arguments import RuntimeArguments
    from cutlass.operators.base import Operator
    from cutlass.operators.metadata import OperatorMetadata
    from cutlass.operators.providers import Provider

_logger = logging.getLogger(__name__)


class Manifest:
    """A Manifest holds a collection of generated Operators."""

    def __init__(self) -> None:
        self._candidate_operators = []

    @staticmethod
    def get_operators(
        args: RuntimeArguments = None,
        metadata_filter: Callable[[OperatorMetadata], bool] | None = None,
        target_sm: TargetSm | str | None = None,
        providers: list[Provider] = None,
    ) -> list[Operator]:
        """Get the operators that match the given arguments, metadata filter, compute capability and available providers.

        Args:
            args (RuntimeArguments): The arguments of the operator
            metadata_filter (Callable[[OperatorMetadata], bool]): A boolean function that takes in OperatorMetadata and returns whether
                                an Operator with this metadata should be included
            target_sm (TargetSm | str | None): Optional target compute capability for which operators should be fetched
            providers (list[Provider]): Optionally limit the search to the given providers. If None, all available providers are used.

        Returns:
            list[Operator]: The operators that match the given arguments, metadata filter, and compute capability
        """
        target_sm = TargetSm.ensure(target_sm)
        providers = providers if providers is not None else available_providers.values()
        filter_fn = metadata_filter or (lambda x: True)

        if args is None and target_sm is None:
            full_filter_fn = filter_fn
        else:

            def full_filter_fn(metadata: OperatorMetadata) -> bool:
                if not filter_fn(metadata):
                    return False
                if not (supports := metadata.supports(args, target_sm=target_sm)):
                    _logger.debug(
                        f"Rejecting operator {metadata.operator_name}. Reason: {supports.error}"
                    )
                    return False
                return True

        epilogue_args = getattr(args, "epilogue", None)
        operators = [
            op
            # Generate operators from all providers
            for provider in providers
            # Filter operators by metadata and args
            for op in provider.generate_operators(
                full_filter_fn,
                target_sm=target_sm,
                epilogue_args=epilogue_args,
                args=args,
            )
            # Do any additional checks on args that are not captured by metadata
            if not args or op._supports(args, target_sm=target_sm)
        ]
        return operators

    def add_operators(
        self,
        operators: list[Operator],
    ) -> None:
        """Add the given operators to the Manifest's set of discovered operators.

        Args:
            operators (list[Operator]): The operators to add to the Manifest
        """
        self._candidate_operators.extend(operators)

    def filter_operators(
        self,
        args: RuntimeArguments = None,
        metadata_filter: Callable[[OperatorMetadata], bool] | None = None,
        target_sm: TargetSm | str | None = None,
        providers: list[Provider] = None,
    ) -> list[Operator]:
        """Filter the operators that have been added to this Manifest.

        This is similar to ``get_operators``, but only considers operators previously added
        to this Manifest using :meth:`add_operators`.
        """
        target_sm = TargetSm.ensure(target_sm)
        metadata_filter = metadata_filter or (lambda x: True)

        # Append provider filter to metadata_filter
        if providers is not None:

            def full_metadata_filter(metadata: OperatorMetadata) -> bool:
                return metadata.provider in providers and metadata_filter(metadata)
        else:
            full_metadata_filter = metadata_filter

        # Filter self._candidate_operators to those that support inputs & full_metadata_filter
        return [
            op
            for op in self._candidate_operators
            if op.supports(args, target_sm=target_sm)
            and full_metadata_filter(op.metadata)
        ]

    @property
    def operators(self) -> list[Operator]:
        """Get the operators that have been added to this Manifest."""
        return self._candidate_operators
