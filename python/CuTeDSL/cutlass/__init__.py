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

from ._mlir._mlir_libs import _cutlass_ir

_cutlass_ir.populate(_cutlass_ir)


def _ensure_mlir_type_compat() -> None:
    """Patch `.isinstance()` onto MLIR type classes that no longer expose it."""
    try:
        from ._mlir import ir as _mlir_ir
    except Exception:
        return
    for name in dir(_mlir_ir):
        if not name.endswith("Type"):
            continue
        cls = getattr(_mlir_ir, name)
        if not isinstance(cls, type) or hasattr(cls, "isinstance"):
            continue
        try:
            cls.isinstance = staticmethod(lambda ty, _cls=cls: isinstance(ty, _cls))  # type: ignore[attr-defined]
        except Exception:
            continue


_ensure_mlir_type_compat()
del _ensure_mlir_type_compat

__version__ = "@CUTLASS_IR_WHEEL_RELEASE_VERSION@"
# Monkey patch CUDA version query function
from ._mlir._mlir_libs._cutlass_ir._base_dsl import (
    get_cuda_version as _get_cuda_version,
)
from .base_dsl import common as _common

_common._get_cuda_version = _get_cuda_version

# Import CUDA version from base_dsl
from .base_dsl.version_info import CUDA_VERSION
from .address_space import AddressSpace

from .cutlass_dsl import (
    Constexpr,
    dsl_user_op,
    as_numeric,
    min,
    max,
    and_,
    or_,
    not_,
    all_,
    any_,
    select_,
    # Control-flow without AST pre-processor
    if_generate,
    for_generate,
    LoopUnroll,
    while_generate,
    yield_out,
    # Control-flow with AST pre-processor
    range,
    range_constexpr,
    range_dynamic,
    const_expr,
    dynamic_expr,
    # Data types
    dtype,  # Provides conversions to types inheriting from NumericType
    DSLRuntimeError,
    DSLUserCodeError,
    JitArgAdapterRegistry,
    # Construction utilities for user-defined classes
    extract_mlir_values,
    new_from_mlir_values,
    DSLCudaVersion,
    target_version,
)

from .cute.typing import *
from .base_dsl.typing import Pointer as Pointer  # type: ignore[assignment]
from .base_dsl.typing import (
    TypedPointer,
    Uint128,
    align,
)
from .base_dsl.pointer import inttoptr
from .base_dsl.swizzle import Swizzle, apply_swizzle, load_swizzled, store_swizzled
from ._mlir_helpers.vector import Vector

# Utilities not belonging to CuTe
from .base_dsl import vector as vector

from . import runtime as runtime
from . import utils as utils
from . import pipeline as pipeline
from . import testing as testing
# Package-private symbol used by exported aliases below.
from . import cutlass_dsl as _dsl

# Aliases
LaunchConfig = _dsl.BaseDSL.LaunchConfig
register_jit_arg_adapter = _dsl.JitArgAdapterRegistry.register_jit_arg_adapter
gpu = _dsl.cutlass_gpu
cuda = _dsl.cuda_helpers

# Jax Framework support
from . import jax as jax

CACHE_FILE = "compiled_cache.db"

# --- cutlass namespace extension gate ----------------------------------------
# `cutlass` is shipped as a regular package (this __init__.py)
# rather than a PEP 420 namespace, so this file fully controls
# what goes in the `cutlass.*` namespace.
#
# A small, explicitly-named set of NVIDIA-owned sibling distributions outside of
# nvidia-cutlass-dsl are permitted to ship subpackages under `cutlass.*`.
# They are listed below. For each one that is actually installed, we resolve where
# pip placed its `cutlass/` portion on disk and append that directory to
# cutlass.__path__, so that `import cutlass.<sibling>` finds it via the standard
# import system.
#
# Anything NOT in this allowlist is silently ignored, even if it ships
# files at <site-packages>/cutlass/<X>/: the regular-package rule keeps it
# invisible. Adding a new approved sibling requires a release of
# nvidia-cutlass-dsl.
_APPROVED_CUTLASS_SIBLINGS = ("nvidia-cutlass-operators",)


def _extend_cutlass_path_for_approved_siblings() -> None:
    import importlib.metadata as _md
    from pathlib import Path

    for dist_name in _APPROVED_CUTLASS_SIBLINGS:
        try:
            dist = _md.distribution(dist_name)
        except _md.PackageNotFoundError:
            continue

        sibling_path = str(dist.locate_file("cutlass"))
        if Path(sibling_path).is_dir() and sibling_path not in __path__:
            __path__.append(sibling_path)


_extend_cutlass_path_for_approved_siblings()
del _extend_cutlass_path_for_approved_siblings
# --- end namespace extension gate --------------------------------------------
