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

import contextlib
import logging
from collections.abc import Callable

from cutlass.operators.providers.provider import Provider

_logger = logging.getLogger(__name__)

available_providers: dict[str, type[Provider]] = {}
"""Dictionary of available providers by name."""


def register_provider(name: str) -> Callable[[type[Provider]], type[Provider]]:
    """
    Decorator used to register a provider class with the given name.

    Args:
        name (str): The name of the provider

    Returns:
        Callable[[Type[Provider]], Type[Provider]]: The wrapper function
    """

    def wrapper(provider_class: type[Provider]) -> type[Provider]:
        """
        Wrapper function to register a provider class with the given name.

        Args:
            provider_class (Type[Provider]): The provider class to register

        Returns:
            Type[Provider]: The registered provider class
        """
        global available_providers
        available_providers[name] = provider_class
        return provider_class

    return wrapper


# Import each provider submodule's ``*Provider`` class. The submodule
# registers its class as a side effect when its underlying DSL is importable
# and otherwise leaves the class undefined

with contextlib.suppress(ImportError):
    from cutlass.operators.providers.cutedsl import CuTeDSLProvider


def __getattr__(name: str) -> object:
    """Give a clear ImportError for known but unavailable providers.

    For unknown attributes, raise the generic AttributeError.
    """
    PROVIDER_INSTALL_HINTS = {
        "CuTeDSLProvider": "install 'nvidia-cutlass-dsl' to enable it",
    }
    if name in PROVIDER_INSTALL_HINTS:
        raise ImportError(
            f"{name} is unavailable: "
            f"{PROVIDER_INSTALL_HINTS[name]}. Check "
            f"`available_providers` for runtime availability."
        )
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


__all__ = [
    "available_providers",
    "register_provider",
    "Provider",
    "CuTeDSLProvider",
]
