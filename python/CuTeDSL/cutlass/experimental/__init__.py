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
  ``WgmmaSmemDesc``, the swizzle/format enums, ...), plus lazy aliases for
  low-level NVVM wrappers. Imported eagerly; wrapper-backed symbols resolve
  lazily.
- ``cuda`` — CUDA tensor-map utilities (lazily loaded).
- ``task_scheduling`` — resource/task scheduling framework (lazily loaded).

``cuda`` and ``task_scheduling`` are loaded lazily (PEP 562 ``__getattr__``)
because they import back into ``cutlass`` itself (``cutlass.cute``,
``cutlass.pipeline``, ``cutlass.experimental.primitives``), which is still
initializing when this module first runs -- importing them eagerly here would
form a cycle.
"""

import importlib as _importlib
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


def __getattr__(name: str) -> _types.ModuleType:
    if name in _LAZY_SUBMODULES:
        mod = _importlib.import_module(f"{__name__}.{name}")
        globals()[name] = mod  # cache so __getattr__ runs at most once per name
        return mod
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


def __dir__() -> list[str]:
    return sorted({*globals(), *_LAZY_SUBMODULES})


__all__ = ["cuda", "primitives", "task_scheduling"]
