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

"""
Compatibility patches for nanobind-based MLIR Python bindings.

The LLVM prebuilt is compiled with -fno-exceptions. Several nanobind
binding methods signal errors or end-of-iteration by throwing C++
exceptions (nb::stop_iteration, nb::value_error, ...). With
-fno-exceptions the throw cannot unwind and calls std::terminate/abort.
The patches below replace those code paths with alternatives
that never reach the throwing C++ code.
"""

from threading import local
from typing import Any, Iterator

from .._mlir import ir

_thread_local = local()


# -- InsertionPoint.current --------------------------------------------------
# ir.InsertionPoint.current throws nb::value_error when no insertion
# point is active. Track enter/exit at the Python level so callers can
# check before touching the C++ property.


def has_insertion_point() -> bool:
    return getattr(_thread_local, "ip_depth", 0) > 0


_orig_ip_enter = ir.InsertionPoint.__enter__
_orig_ip_exit = ir.InsertionPoint.__exit__


def _tracked_ip_enter(self: ir.InsertionPoint) -> ir.InsertionPoint:
    _thread_local.ip_depth = getattr(_thread_local, "ip_depth", 0) + 1
    return _orig_ip_enter(self)


def _tracked_ip_exit(self: ir.InsertionPoint, *args: Any) -> None:
    _thread_local.ip_depth = getattr(_thread_local, "ip_depth", 1) - 1
    _orig_ip_exit(self, *args)


ir.InsertionPoint.__enter__ = _tracked_ip_enter
ir.InsertionPoint.__exit__ = _tracked_ip_exit


# -- Block.__iter__ -----------------------------------------------------------
# PyOperationIterator.__next__ throws nb::stop_iteration() at
# end-of-block. Replace with indexed access via Block.operations
# whose __len__ and __getitem__ use the C API without throwing.


def _safe_block_iter(self: ir.Block) -> Iterator[Any]:
    ops = self.operations
    for i in range(len(ops)):
        yield ops[i]


ir.Block.__iter__ = _safe_block_iter
