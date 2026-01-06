# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

import logging
from collections.abc import Callable

from cutlass_api.arguments import RuntimeArguments
from cutlass_api.kernel import Kernel
from cutlass_api.metadata import KernelMetadata
from cutlass_api.providers import available_providers

_logger = logging.getLogger(__name__)


class Manifest:
    def __init__(self) -> None:
        self._candidate_kernels = []

    @staticmethod
    def get_kernels(
        args: RuntimeArguments = None,
        metadata_filter: Callable[[KernelMetadata], bool] | None = None,
        cc: int = None,
        providers: list[str] = None,
    ) -> list[Kernel]:
        """
        Get the kernels that match the given arguments, metadata filter, and compute capability.

        :param args: the arguments of the kernel
        :type args: RuntimeArguments
        :param metadata_filter: a boolean function that takes in KernelMetadata and returns whether
                                a Kernel from this metadata should be included
        :type metadata_filter: Callable[[KernelMetadata], bool]
        :param cc: the compute capability
        :type cc: int
        :param providers: the providers to use
        :type providers: list[str]

        :return: the kernels that match the given arguments, metadata filter, and compute capability
        :rtype: list[Kernel]
        """
        # Setup providers to use
        providers_to_use = []
        if providers is None:
            providers_to_use = list(available_providers.values())
        else:
            for provider in providers:
                if provider not in available_providers:
                    raise ValueError(f"Provider {provider} is not available")
                providers_to_use.append(available_providers[provider])

        # Setup filter function
        filter_fn = (lambda x: True) if metadata_filter is None else metadata_filter
        if args is None:
            full_filter_fn = filter_fn
        else:

            def full_filter_fn(metadata: KernelMetadata) -> bool:
                if not filter_fn(metadata):
                    return False
                if not (supports := metadata.supports(args)):
                    _logger.debug(
                        f"Rejecting kernel {metadata.kernel_name}. Reason: {supports.error}"
                    )
                    return False
                return True

        epilogue_args = None if args is None else args.epilogue
        kernels = [
            k
            # Generate kernels from all providers
            for provider in providers_to_use
            # Filter kernels by metadata
            for k in provider.generate_kernels(
                full_filter_fn, cc=cc, epilogue_args=epilogue_args
            )
            # Do any additional checks on args that are not captured by metadata
            if not args or k._supports(args)
        ]
        return kernels

    def add_kernels(
        self,
        args: RuntimeArguments = None,
        metadata_filter: Callable[[KernelMetadata], bool] | None = None,
        cc: int = None,
        providers: list[str] = None,
    ) -> list[Kernel]:
        """
        Get the kernels that match the given arguments, metadata filter, and compute capability,
        and add them to the Manifest's set of discovered kernels.

        :param args: the arguments of the kernel
        :type args: RuntimeArguments
        :param metadata_filter: a boolean function that takes in KernelMetadata and returns whether
                                a Kernel from this metadata should be included
        :type metadata_filter: Callable[[KernelMetadata], bool]
        :param cc: the compute capability
        :type cc: int
        :param providers: the providers to use
        :type providers: list[str]

        :return: the kernels that match the given arguments, metadata filter, and compute capability
        :rtype: list[Kernel]
        """
        matched_kernels = Manifest.get_kernels(args, metadata_filter, cc, providers)
        self._candidate_kernels.extend(matched_kernels)
        return matched_kernels

    @property
    def kernels(self) -> list[Kernel]:
        return self._candidate_kernels
