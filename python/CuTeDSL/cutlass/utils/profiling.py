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

"""Unified profiling scope for NameLoc annotations.

Provides ``Scope`` (base, with optional metadata) and ``WarpScope``
(typed wrapper for warp groups with warp_start/warp_end).

All metadata is collected in a global symbol registry and dumped as
``kernel_symbols.json`` by ``dump_kernel_symbols()``.

Usage::

    from cutlass.utils.profiling import Scope, WarpScope

    # Context manager (nested scopes for pipeline phases):
    with Scope("tmem_sp0/ConsumerWork"):
        ...  # all MLIR ops tagged with NameLoc

    # Flat switch (warp dispatch):
    scope = WarpScope("LoadWarp", warp_start=13, warp_end=14)
    ...
    scope.switch("MmaWarp", warp_start=12, warp_end=13)
    ...
    scope.close()
"""

from __future__ import annotations

from typing import Any, Union

from cutlass._mlir._mlir_libs._cutlass_ir._mlir import ir


# ── Symbol registry ──────────────────────────────────────────────────────────

_symbol_registry: dict[str, dict[str, Any]] = {}


def register_symbol(name: str, kind: str, **metadata: Any) -> None:
    """Register a named symbol with metadata for kernel_symbols.json.

    Merges with existing entry if present (later calls add fields).
    """
    if name:
        existing = _symbol_registry.get(name, {})
        existing.update({"kind": kind, **metadata})
        _symbol_registry[name] = existing


def get_symbol_registry() -> dict[str, dict[str, Any]]:
    """Return the current symbol registry (for inspection)."""
    return dict(_symbol_registry)


def dump_kernel_symbols() -> dict[str, Any]:
    """Return the symbol registry grouped by kind, then clear it.

    Returns::

        {
            "warps": {"Softmax0Warp": {"warp_start": 0, "warp_end": 4}, ...},
            "barriers": {"load_q": {"num_stages": 2, "pipeline_type": "..."}, ...},
        }
    """
    warps = {}
    barriers = {}
    for name, meta in _symbol_registry.items():
        kind = meta.pop("kind", "")
        if kind == "warp":
            warps[name] = meta
        elif kind == "barrier":
            barriers[name] = meta
        # other kinds can be added later
    result: dict[str, Any] = {}
    if warps:
        result["warps"] = warps
    if barriers:
        # Also emit bar_alloc for backward compat with stall_attribution
        alloc_parts = []
        for bname, bmeta in barriers.items():
            stages = bmeta.get("num_stages", 1)
            alloc_parts.append(f"{bname}:{stages}")
        result["bar_alloc"] = ", ".join(alloc_parts)
        result["barriers"] = barriers
    _symbol_registry.clear()
    return result


def reset_symbol_registry() -> None:
    """Clear the symbol registry."""
    _symbol_registry.clear()


# ── Scope ────────────────────────────────────────────────────────────────────


class Scope:
    """Profiling scope: NameLoc + optional metadata.

    :param name: Scope label(s). A string creates one NameLoc.
        A tuple creates nested NameLocs (outermost first)::

            with Scope(("tmem_sp0", "ConsumerWork[1]")):
                ...  # NameLocs: loc("tmem_sp0"(loc("ConsumerWork[1]"(...))))

    :type name: str or tuple[str, ...]
    :param metadata: Arbitrary key-value pairs registered in the symbol registry.
        Pass ``kind="warp"`` or ``kind="barrier"`` to categorize.
    """

    def __init__(
        self,
        name: Union[str, tuple[str, ...]] = "",
        *,
        iket: bool = False,
        **metadata: Any,
    ):
        self._iket_enabled = iket
        self._iket_token = None
        self._locs: list = []  # stack of NameLoc context managers
        if metadata:
            label = name if isinstance(name, str) else name[0]
            register_symbol(label, **metadata)
        if name:
            self._enter(name)

    def _enter(self, name: Union[str, tuple[str, ...]]) -> None:
        """Push NameLoc scope(s)."""
        ctx = ir.Location.current.context
        parts = (name,) if isinstance(name, str) else name
        for part in parts:
            loc = ir.Location.name(part, childLoc=ir.Location.current, context=ctx)
            loc.__enter__()
            self._locs.append(loc)
        if self._iket_enabled:
            import cutlass.cute.experimental.iket as _iket

            iket_label = "/".join(parts)
            self._iket_token = _iket.range_start(iket_label)

    def _exit(self) -> None:
        """Pop all NameLoc scopes."""
        if self._iket_token is not None:
            import cutlass.cute.experimental.iket as _iket

            _iket.range_end(self._iket_token)
            self._iket_token = None
        # Exit in reverse order (innermost first)
        while self._locs:
            loc = self._locs.pop()
            loc.__exit__(None, None, None)

    def switch(self, name: Union[str, tuple[str, ...]], **metadata: Any) -> "Scope":
        """Exit current scope and enter a new one (flat dispatch pattern).

        Accepts the same metadata kwargs as __init__.
        """
        self._exit()
        if metadata:
            label = name if isinstance(name, str) else name[0]
            register_symbol(label, **metadata)
        self._enter(name)
        return self

    def close(self) -> None:
        """Explicitly close the scope."""
        self._exit()

    def __enter__(self) -> "Scope":
        return self

    def __exit__(self, *exc: Any) -> None:
        self._exit()

    def __del__(self) -> None:
        try:
            self._exit()
        except Exception:
            pass


class WarpScope(Scope):
    """Typed scope for warp groups — registers warp_start/warp_end metadata.

    Usage::

        scope = WarpScope("Softmax0Warp", warp_start=0, warp_end=4, iket=True)
        scope.switch("MmaWarp", warp_start=12, warp_end=13)
        scope.close()
    """

    def __init__(
        self,
        name: str,
        *,
        warp_start: int,
        warp_end: int,
        iket: bool = False,
    ):
        super().__init__(
            name,
            iket=iket,
            kind="warp",
            warp_start=warp_start,
            warp_end=warp_end,
        )

    def switch(  # type: ignore[override]
        self,
        name: str,
        *,
        warp_start: int,
        warp_end: int,
    ) -> "WarpScope":
        """Switch to a new warp scope."""
        super().switch(
            name,
            kind="warp",
            warp_start=warp_start,
            warp_end=warp_end,
        )
        return self
