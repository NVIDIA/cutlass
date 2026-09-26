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

"""IR-position validity checks for cached SSA values.

An emitted op is *positional*: its results are only usable where its block
dominates. A Python wrapper that caches an ``ir.Value`` (or anything built
from one) and outlives the region it was built in can therefore serve an
operand that is invalid at a later use site. These helpers let such caches
verify a stored value before serving it, mirroring how ``lru_cache_ir`` keys
on the insertion point instead of assuming position-independence.
"""

from typing import Any, Iterator

from .._mlir import ir

# The dominance query is a C++ binding that currently ships in the pyir
# dialect module. It is a generic MLIR facility (DominanceInfo), not a
# frontend feature; not every ``_mlir`` bundle carries the module, so its
# absence degrades to "assume reachable".
try:
    from .._mlir.dialects import pyir as _pyir_dialect
except ImportError:
    _pyir_dialect = None


def ssa_leaves(obj: Any) -> Iterator["ir.Value"]:
    """Yield the SSA values backing *obj*.

    Covers the shapes derived caches take in practice: a raw ``ir.Value``, a
    wrapper exposing ``.value``, and nested tuples/lists whose leaves may be
    plain Python numbers carrying no SSA at all.
    """
    if isinstance(obj, ir.Value):
        yield obj
    elif isinstance(obj, (tuple, list)):
        for item in obj:
            yield from ssa_leaves(item)
    else:
        inner = getattr(obj, "value", None)
        if isinstance(inner, ir.Value):
            yield inner


def value_reaches_current_ip(obj: Any) -> bool:
    """Whether every SSA leaf of *obj* is usable at the current insertion
    point. True when undecidable, so callers drop a cached value only once
    the escape is positively proven.

    The insertion point's ref operation is part of the query: insertion may
    sit *before* an existing op (e.g. ``InsertionPoint.at_block_begin``), and
    a same-block value defined after that position must not count as
    reachable."""
    if _pyir_dialect is None:
        return True
    try:
        ip = ir.InsertionPoint.current
        ref_op = ip.ref_operation
        if ref_op is not None:
            ref_op = getattr(ref_op, "operation", ref_op)
        return all(
            _pyir_dialect.value_dominates_ip(leaf, ip.block, ref_op)
            for leaf in ssa_leaves(obj)
        )
    except (RuntimeError, ValueError):
        return True
