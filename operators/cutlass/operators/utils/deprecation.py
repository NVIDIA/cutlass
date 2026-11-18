# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""Helper for keeping moved names importable while warning their users."""

from __future__ import annotations

import importlib
import warnings
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import Callable, Mapping


def deprecated_module_attributes(
    module_name: str, moved: Mapping[str, str]
) -> Callable[[str], object]:
    """Return a module ``__getattr__`` that serves moved names with a warning.

    Set the result as ``__getattr__`` in the module that used to define the
    names (PEP 562).  Python calls it only for names that the module does not
    define.  For a name in ``moved``, it gives a ``DeprecationWarning`` that
    tells the caller the new path, and returns the object at that path.  It is
    the same object, so ``is`` and ``isinstance`` checks stay correct.

    Args:
        module_name (str): ``__name__`` of the module that used to define the names.
        moved (Mapping[str, str]): Maps each old name to the full import path of
            its replacement, for example ``"cutlass.operators.Operand"``.

    Returns:
        Callable[[str], object]: The module ``__getattr__``.  It raises
        ``AttributeError`` for a name that is not in ``moved``.
    """

    def __getattr__(name: str) -> object:
        if name not in moved:
            raise AttributeError(f"module {module_name!r} has no attribute {name!r}")
        new_path = moved[name]
        warnings.warn(
            f"{module_name}.{name} is deprecated and will be removed in a future "
            f"release; use {new_path} instead.",
            DeprecationWarning,
            stacklevel=2,
        )
        new_module, _, new_name = new_path.rpartition(".")
        return getattr(importlib.import_module(new_module), new_name)

    return __getattr__
