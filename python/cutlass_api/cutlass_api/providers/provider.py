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

from collections.abc import Callable
from typing import Protocol, runtime_checkable

from cutlass_api.arguments import EpilogueArguments
from cutlass_api.kernel import Kernel
from cutlass_api.metadata import KernelMetadata


@runtime_checkable
class ProviderBase(Protocol):
    @classmethod
    def generate_kernels(
        cls,
        metadata_filter: Callable[[KernelMetadata], bool] | None = None,
        epilogue_args: EpilogueArguments | None = None,
        cc: int | None = None,
    ) -> list[Kernel]:
        """
        Return a list of kernels that support the type of the provided metadata.

        :param metadata_filter: boolean filter function to apply to the metadata
        :type metadata_filter: Callable[[KernelMetadata], bool]
        :param epilogue_args: the epilogue arguments
        :type epilogue_args: EpilogueArguments
        :param cc: compute capability of device for which kernels should be compiled. For example, if running on H100, this should be set to 90
        :type cc: int

        :return: list of all supported kernel configurations
        :rtype: list[Kernel]
        """
        raise NotImplementedError

    @classmethod
    def register(cls, kernel_class: type[Kernel]) -> type[Kernel]:
        """
        Registers a Kernel class as being able to be discovered through the given provider.

        :param kernel_class: the Kernel class to register
        :type kernel_class: Type[Kernel]

        :return: the registered kernel class
        :rtype: Type[Kernel]
        """
        raise NotImplementedError
