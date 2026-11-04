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

import logging
import traceback
from collections.abc import Callable

from cutlass.operators.providers.provider import Provider

_logger = logging.getLogger(__name__)

available_providers: dict[str, type[Provider]] = {}
"""Dictionary of available providers by name."""

# Formatted diagnostics for providers that failed to import. Keeping only text
# avoids retaining the importing frames and their local variables.
_import_errors: dict[str, str] = {}
_PROVIDER_INSTALL_HINTS = {
    "CuTeDSLProvider": "install 'nvidia-cutlass-dsl' to enable it",
}


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


def _record_import_error(name: str, exc: ImportError) -> None:
    _logger.debug("%s unavailable: %s", name, exc, exc_info=True)
    if isinstance(exc, ModuleNotFoundError):
        reason = f"{name} is unavailable: {_PROVIDER_INSTALL_HINTS[name]}."
    else:
        reason = f"{name} failed to import."
    original = "".join(traceback.format_exception(exc))
    _import_errors[name] = f"{reason}\n\nOriginal error:\n{original}"


# Import provider submodules' ``*Provider`` subclasses independently.  A
# failure in one must never block the others.  Failures are logged and stored
# so __getattr__ can surface the error without retaining live traceback frames.

try:
    from cutlass.operators.providers.cutedsl import CuTeDSLProvider
except ImportError as _exc:
    _record_import_error("CuTeDSLProvider", _exc)


def __getattr__(name: str) -> object:
    """Give a clear ImportError for known but unavailable providers."""
    if name in _import_errors:
        raise ImportError(_import_errors[name])
    if name in _PROVIDER_INSTALL_HINTS:
        raise ImportError(f"{name} is unavailable: {_PROVIDER_INSTALL_HINTS[name]}.")
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


__all__ = [
    "available_providers",
    "register_provider",
    "Provider",
    "CuTeDSLProvider",
]
