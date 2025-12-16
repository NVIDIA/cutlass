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
import logging
from typing import Type

from cutlass_api.arguments import EpilogueArguments
from cutlass_api.kernel import Kernel
from cutlass_api.metadata import KernelMetadata
from cutlass_api.providers import register_provider


def try_import() -> bool:
    import importlib.util

    if importlib.util.find_spec("cutlass") is None:
        logging.warning(
            "'cutlass' could not be imported. The cutedsl provider will not be available."
        )
        return False
    return True


available = try_import()


if available:

    @register_provider("cutedsl")
    class CuTeDSLProvider:
        # Kernel classes currently registered with this provider
        _kernel_classes = []

        @classmethod
        def generate_kernels(
            cls,
            metadata_filter: Callable[[KernelMetadata], bool] | None,
            epilogue_args: EpilogueArguments = None,
            cc: int = None,
        ) -> list[Kernel]:
            kernels_for_provider = []
            for kernel_cls in cls._kernel_classes:
                kernels_for_provider.extend(
                    kernel_cls.generate_kernels(
                        metadata_filter, epilogue_args=epilogue_args, cc=cc
                    )
                )

            return kernels_for_provider

        @classmethod
        def register(cls, kernel_class: type[Kernel]) -> type[Kernel]:
            cls._kernel_classes.append(kernel_class)
            return kernel_class

    # Imports for side effects (kernel registration)
    import cutlass_api.providers.cutedsl.elementwise  # noqa: F401
    import cutlass_api.providers.cutedsl.gemm  # noqa: F401

    __all__ = ["CuTeDSLProvider"]
else:
    __all__ = []
