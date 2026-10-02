# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Observe tracing and compilation through the DSL's hooks.

For example, ``register_hook(HookEvent.POST_COMPILE, on_compile)`` observes
implicit JIT compilations as well as explicit ``cute.compile`` calls. Every
hook receives an event object. Registration defaults to CuTeDSL; pass ``dsl=``
to observe another DSL instance. These functions share registrations and scopes
with that instance's ``register_hook``, ``remove_hook`` and ``hooks`` methods.
"""

from contextlib import AbstractContextManager
from typing import TYPE_CHECKING, Any, Callable, Iterable

from .base_dsl.hooks_manager import CompilationEvent, HookEvent, TraceFinalizeEvent

if TYPE_CHECKING:
    from .base_dsl.dsl import BaseDSL


def _get_dsl(dsl: "BaseDSL | None") -> "BaseDSL":
    if dsl is None:
        # Resolve lazily: importing the public API must not initialize a DSL.
        from .cutlass_dsl import CuTeDSL

        return CuTeDSL._get_dsl()
    return dsl


def register_hook(
    event: HookEvent, hook: Callable[[Any], None], *, dsl: "BaseDSL | None" = None
) -> None:
    """Register a hook globally on the selected DSL; duplicates are ignored."""
    _get_dsl(dsl).register_hook(event, hook)


def remove_hook(
    event: HookEvent, hook: Callable[[Any], None], *, dsl: "BaseDSL | None" = None
) -> None:
    """Remove a hook from the selected DSL; no-op when it is absent."""
    _get_dsl(dsl).remove_hook(event, hook)


def hooks(
    event: HookEvent,
    hooks: Callable[[Any], None] | Iterable[Callable[[Any], None]],
    *,
    dsl: "BaseDSL | None" = None,
) -> AbstractContextManager[None]:
    """Scope hooks to the current context, restoring them when the block exits."""
    return _get_dsl(dsl).hooks(event, hooks)


__all__ = [
    "CompilationEvent",
    "HookEvent",
    "TraceFinalizeEvent",
    "hooks",
    "register_hook",
    "remove_hook",
]
