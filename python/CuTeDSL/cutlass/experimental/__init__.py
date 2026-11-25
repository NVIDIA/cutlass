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

"""Experimental CUTLASS Python APIs.

Submodules:

- ``primitives`` — typed hardware MMA descriptors for the SM90 ``wgmma`` and
  SM100 ``tcgen05`` instructions (``Tcgen05SmemDesc``, ``Tcgen05InstrDesc``,
  ``WgmmaSmemDesc``, the swizzle/format enums, ...), plus the NVVM op wrappers
  from its own ``nvvm_wrapper`` submodule. Imported eagerly.
- ``cuda`` — CUDA graph and tensor-map utilities (lazily loaded).
- ``task_scheduling`` — resource/task scheduling framework (lazily loaded).

``cuda`` and ``task_scheduling`` are loaded lazily (PEP 562 ``__getattr__``)
because they import back into ``cutlass`` itself (``cutlass.cute``,
``cutlass.pipeline``, ``cutlass.experimental.primitives``), which is still
initializing when this module first runs — importing them eagerly here would
form a cycle.
"""

import importlib as _importlib
import sys as _sys
import types as _types

# Low-level hardware primitives (typed SM90 wgmma / SM100 tcgen05 MMA
# descriptors etc.) live under ``cutlass.experimental.primitives``.  The
# subpackage depends only on cutlass/base_dsl/NVVM, so it is safe to import
# eagerly.
from . import primitives as primitives

# ``cuda`` and ``task_scheduling`` reach back into ``cutlass`` itself
# (``cutlass.cute``, ``cutlass.pipeline``, ``cutlass.experimental.primitives``).
# Because this module runs while ``cutlass`` is still initializing, importing
# those submodules eagerly here would form an import cycle
# (cutlass -> experimental -> task_scheduling -> cutlass).  Defer them via PEP
# 562 module ``__getattr__`` so they load only on first real use, by which
# point ``cutlass`` is fully initialized.
_LAZY_SUBMODULES = ("cuda", "task_scheduling")


_ts_audit_loaded = False


def _load_ts_audit() -> None:
    """Attach the ts-dialect audit observer to ``task_scheduling``.

    ``ts_audit`` is compiler infrastructure, not part of the scheduling
    product: the framework never imports it, so this is the one place
    that connects the two. It runs only after ``task_scheduling`` is
    fully imported (``ts_audit`` imports back into it), and fail-open --
    an audit package that is absent or failing must never cost a compile.
    """
    global _ts_audit_loaded
    if _ts_audit_loaded:
        return
    _ts_audit_loaded = True
    try:
        _importlib.import_module(f"{__name__}.ts_audit")
    except Exception as error:  # noqa: BLE001 - fail-open by design.
        # The warning itself must not raise: this runs while the import
        # machinery binds the submodule, and under ``-W error`` a warning
        # IS an exception -- which would turn a missing audit package into
        # a failed ``import cutlass.experimental.task_scheduling``.
        import warnings

        try:
            warnings.warn(f"TS IR emission unavailable (ignored): {error!r}")
        except Exception:  # noqa: BLE001 - fail-open by design.
            pass


def __getattr__(name: str) -> _types.ModuleType:
    if name in _LAZY_SUBMODULES:
        mod = _importlib.import_module(f"{__name__}.{name}")
        globals()[name] = mod  # cache so __getattr__ runs at most once per name
        if name == "task_scheduling":
            _load_ts_audit()
        return mod
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


class _ExperimentalModule(_types.ModuleType):
    """This package's module type, so the ts_audit hookup cannot be missed.

    ``__getattr__`` above only fires for ``cutlass.experimental.<name>``
    attribute access; a direct ``import cutlass.experimental.<name>``
    (what every kernel writes) is handled by the import machinery, which
    binds the submodule with ``setattr`` and never consults
    ``__getattr__``. Binding is therefore the reliable trigger, and it
    fires only once the submodule has finished initializing.
    """

    def __setattr__(self, name: str, value: object) -> None:
        super().__setattr__(name, value)
        if name == "task_scheduling":
            _load_ts_audit()


_sys.modules[__name__].__class__ = _ExperimentalModule


def __dir__() -> list[str]:
    return sorted({*globals(), *_LAZY_SUBMODULES})


__all__ = ["cuda", "primitives", "task_scheduling"]
