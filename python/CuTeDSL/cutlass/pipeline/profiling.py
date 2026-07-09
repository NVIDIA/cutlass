# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Pipeline-level profiling helpers.

These helpers register pipeline barriers in the shared symbol registry
(defined in ``cutlass.utils.profiling``) and dump ``kernel_symbols.json``
for downstream profiling tools. They are deliberately kept in their own
module — the pipeline helper file holds MLIR-emitting primitives, not
profiling bookkeeping.
"""

import json
import os
from typing import Optional

from cutlass.utils.profiling import (
    dump_kernel_symbols,
    register_symbol,
    reset_symbol_registry,
)


def register_barrier(name: str, num_stages: int, pipeline_type: str) -> None:
    """Register a named barrier in the global symbol registry."""
    if name:
        register_symbol(
            name, kind="barrier", num_stages=num_stages, pipeline_type=pipeline_type
        )


def dump_barrier_registry() -> dict:
    """Return barrier data from the symbol registry (backward compat)."""
    return dump_kernel_symbols()


def reset_barrier_registry() -> None:
    """Clear the symbol registry."""
    reset_symbol_registry()


def dump_profiling_metadata(dump_dir: str, extra: Optional[dict] = None) -> None:
    """Dump ``kernel_symbols.json`` to ``dump_dir``.

    Call after ``cute.compile()`` returns. Merges the symbol registry
    (barriers + warps) with any extra metadata.

    :param dump_dir: Output directory.
    :type dump_dir: str
    :param extra: Additional fields to merge (e.g., TS schedule).
    :type extra: dict, optional
    :raises RuntimeError: If the output file cannot be written.
    """
    data = dump_kernel_symbols()
    if not data.get("bar_alloc") and not data.get("warps"):
        return
    if extra:
        data.update(extra)
    os.makedirs(dump_dir, exist_ok=True)
    path = os.path.join(dump_dir, "kernel_symbols.json")
    try:
        with open(path, "w") as f:
            json.dump(data, f, indent=2)
            f.write("\n")
    except OSError as e:
        raise RuntimeError(
            f"Failed to write kernel_symbols.json to {path!r}: {e}"
        ) from e
