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

"""Fully modular seam for the Operator API heuristics (ranking) layer."""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import Callable

    from cutlass.operators.arch import TargetSm
    from cutlass.operators.arguments import RuntimeArguments
    from cutlass.operators.base import Operator


class Heuristic(ABC):
    """Orders already-filtered Operators best-first for a problem.

    A concrete heuristic implements :meth:`rank`, which
    ranks the given Operators for the given problem by estimated performance.
    The returned Operators are an ordered subset of the candidates -- a heuristic
    may prune some suboptimal candidates, but must not invent new Operators.

    Turning a heuristic on or off changes candidate order and possibly
    which candidates are present, never their correctness.

    Heuristics classes are addressable by name through a small registry
    (:data:`cutlass.operators.available_heuristics`).
    """

    @abstractmethod
    def rank(
        self,
        args: RuntimeArguments | None,
        operators: list[Operator],
        *,
        target_sm: TargetSm | str | None = None,
        limit: int | None = None,
    ) -> list[Operator]:
        """Return ``operators`` reordered best-first for ``args``.

        Args:
            args (RuntimeArguments | None): Runtime arguments describing the
                problem being ranked for (e.g. a :class:`GemmArguments`). May be
                ``None`` if the caller did not provide arguments.
            operators (list[Operator]): The already-filtered candidate Operators
                to order. Every element is known to support ``args``.
            target_sm (TargetSm | str | None): Optional compute capability the
                operators are being ranked for.
            limit (int | None): When set, the caller will keep only the first
                ``limit`` Operators from the ranked result.

        Returns:
            list[Operator]: A subset of ``operators`` (possibly all of them),
            reordered best-first. Must not contain an Operator absent from
            ``operators``, or duplicate one beyond its count there.
        """


available_heuristics: dict[str, type[Heuristic]] = {}
"""Registry of heuristics addressable by name."""


def register_heuristic(name: str) -> Callable[[type[Heuristic]], type[Heuristic]]:
    """Return a decorator that registers a :class:`Heuristic` subclass under ``name``.

    Mirrors :func:`cutlass.operators.providers.register_provider`.

    Args:
        name (str): The name to register the heuristic under. Reusing a name
            overrides the previous registration.

    Returns:
        Callable[[type[Heuristic]], type[Heuristic]]: A class decorator that
        registers and returns the decorated heuristic class unchanged.
    """

    def wrapper(heuristic_class: type[Heuristic]) -> type[Heuristic]:
        """Register ``heuristic_class`` under ``name`` and return it unchanged."""
        available_heuristics[name] = heuristic_class
        return heuristic_class

    return wrapper


def get_heuristic(name: str) -> type[Heuristic]:
    """Return the registered :class:`Heuristic` subclass for ``name``.

    Args:
        name (str): The name the heuristic was registered under.

    Returns:
        type[Heuristic]: The registered heuristic class.

    Raises:
        KeyError: If no heuristic is registered under ``name``.
    """
    try:
        return available_heuristics[name]
    except KeyError:
        raise KeyError(
            f"No heuristic registered under {name!r}. "
            f"Available heuristics: {sorted(available_heuristics)}"
        ) from None
