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

from typing import Any, Sequence
from pathlib import Path
from functools import cache
from threading import Lock
import logging
import ctypes

import cutlass
from cutlass.base_dsl.env_manager import find_libs_in_ancestors
from cutlass.cutlass_dsl.cutlass import CuTeDSL

import jax
import jax.export

logger = logging.getLogger(__name__)

_CUTE_DSL_RUNTIME_LIBRARY_NAME = "cute_dsl_runtime"

_JAX_FFI_V2_MIN_VERSION = (0, 9, 1)

_CUTLASS_CALL_TARGETS = {
    # V1 targets for older JAX clients.
    1: {
        "CuteDSLRT_NvJaxCutlassCall_v1": {
            "prepare": "CuteDSLRT_NvJaxCutlassCallPrepare_v1",
            "execute": "CuteDSLRT_NvJaxCutlassCallExecute_v1",
        },
        "CuteDSLRT_NvJaxCutlassCallNoCudaGraph_v1": {
            "prepare": "CuteDSLRT_NvJaxCutlassCallPrepare_v1",
            "execute": "CuteDSLRT_NvJaxCutlassCallExecuteNoCudaGraph_v1",
        },
    },
    # V2 targets for newer JAX clients supporting stateful FFI calls.
    2: {
        "CuteDSLRT_NvJaxCutlassCall_v2": {
            "execute": "CuteDSLRT_NvJaxCutlassCallExecute_v2",
            "instantiate": "CuteDSLRT_NvJaxCutlassCallInstantiate_v2",
            "prepare": "CuteDSLRT_NvJaxCutlassCallPrepare_v2",
        },
        "CuteDSLRT_NvJaxCutlassCallNoCudaGraph_v2": {
            "execute": "CuteDSLRT_NvJaxCutlassCallExecuteNoCudaGraph_v2",
            "instantiate": "CuteDSLRT_NvJaxCutlassCallInstantiate_v2",
            "prepare": "CuteDSLRT_NvJaxCutlassCallPrepare_v2",
        },
    },
}
_CUTLASS_CALL_TYPES = {
    1: {},
    2: {
        "CuteDSLRT_NvJaxCutlassCallTypes_v2": {
            "type_id": "CuteDSLRT_NvJaxCutlassCallStateTypeId_v2",
            "type_info": "CuteDSLRT_NvJaxCutlassCallStateTypeInfo_v2",
        }
    },
}

_FFI_REGISTRATION_LOCK = Lock()
_REGISTERED_FFI_CALL_TARGETS: set[str] = set()
_REGISTERED_FFI_TYPES: set[str] = set()
_AUTOMATIC_FFI_REGISTRATION_ENABLED = True
_FFI_CALL_TARGETS_OVERRIDE: tuple[str, str] | None = None


def get_cutlass_call_ffi_version() -> int:
    """Returns the FFI version supported by the installed JAX."""
    return 2 if jax.version.__version_info__ >= _JAX_FFI_V2_MIN_VERSION else 1


def get_cutlass_call_ffi_name(allow_cuda_graph: bool, version: int) -> str:
    """Returns the FFI target for ``version``."""
    suffix = "" if allow_cuda_graph else "NoCudaGraph"
    return f"CuteDSLRT_NvJaxCutlassCall{suffix}_v{version}"


def get_export_disabled_safety_checks() -> Sequence[jax.export.DisabledSafetyCheck]:
    """Returns export safety checks for the built-in FFI targets."""
    targets = set().union(*_CUTLASS_CALL_TARGETS.values())
    return tuple(
        jax.export.DisabledSafetyCheck.custom_call(target) for target in sorted(targets)
    )


@cache
def find_cute_dsl_runtime_library() -> str | None:
    """Searches for the CuTeDSL runtime library."""
    dsl = CuTeDSL._get_dsl()
    candidate_libs = []

    try:
        # Prefer the environment variable if we find it there.
        if dsl.envar.shared_libs:
            for lib in dsl.envar.shared_libs.split(":"):
                if lib.endswith(f"{_CUTE_DSL_RUNTIME_LIBRARY_NAME}.so"):
                    return lib

        # Otherwise try to search for the library inside the wheel
        def get_libs_cand(start: str | Path) -> list[str]:
            libs_cand = find_libs_in_ancestors(
                start, {_CUTE_DSL_RUNTIME_LIBRARY_NAME}, ["lib"]
            )
            if libs_cand:
                return libs_cand
            return []

        dsl_libs = get_libs_cand(cutlass.__file__)
        if not dsl_libs:
            dsl_libs = get_libs_cand(Path(__file__).parent.parent.resolve())

        candidate_libs.extend(dsl_libs)

    except Exception as e:
        logger.debug(
            f"Failed to locate {_CUTE_DSL_RUNTIME_LIBRARY_NAME} library: {e}",
            exc_info=True,
        )

    for lib in candidate_libs:
        if lib.endswith(f"{_CUTE_DSL_RUNTIME_LIBRARY_NAME}.so"):
            return lib

    return None


def _is_ffi_version_registered(version: int) -> bool:
    return all(
        name in _REGISTERED_FFI_CALL_TARGETS for name in _CUTLASS_CALL_TARGETS[version]
    ) and all(name in _REGISTERED_FFI_TYPES for name in _CUTLASS_CALL_TYPES[version])


def _register_ffi(version: int) -> None:
    """Registers ``version`` while ``_FFI_REGISTRATION_LOCK`` is held."""
    call_targets = {
        name: symbols
        for name, symbols in _CUTLASS_CALL_TARGETS[version].items()
        if name not in _REGISTERED_FFI_CALL_TARGETS
    }
    type_targets = {
        name: symbols
        for name, symbols in _CUTLASS_CALL_TYPES[version].items()
        if name not in _REGISTERED_FFI_TYPES
    }
    if not call_targets and not type_targets:
        return

    runtime_library = find_cute_dsl_runtime_library()
    if not runtime_library:
        logger.debug(
            "No CuTeDSL runtime library found - skipping python ffi registration."
        )
        return

    lib = ctypes.CDLL(runtime_library)

    def _register_ffi_targets(
        lib: ctypes.CDLL, targets: dict[str, dict[str, str]]
    ) -> None:
        for target_name, target in targets.items():
            handler: dict[str, Any] = {}
            for stage, fn_name in target.items():
                fn = getattr(lib, fn_name)
                fn.restype = ctypes.c_void_p
                handler[stage] = jax.ffi.pycapsule(fn)
            logger.debug(f"Registering ffi handler: {target_name}, {handler}")
            jax.ffi.register_ffi_target(target_name, handler, platform="CUDA")
            _REGISTERED_FFI_CALL_TARGETS.add(target_name)

    def _register_ffi_types(lib: ctypes.CDLL, types: dict[str, dict[str, str]]) -> None:
        for type_name, type_targets in types.items():
            type_dict: dict[str, Any] = {}
            for field, fn_name in type_targets.items():
                fn = getattr(lib, fn_name)
                fn.restype = ctypes.c_void_p
                type_dict[field] = jax.ffi.pycapsule(fn())
            logger.debug(f"Registering ffi type: {type_name}, {type_dict}")
            jax.ffi.register_ffi_type(type_name, type_dict, platform="CUDA")  # type: ignore[arg-type]
            _REGISTERED_FFI_TYPES.add(type_name)

    _register_ffi_types(lib, type_targets)
    _register_ffi_targets(lib, call_targets)


def register_ffi(version: int | None = None) -> None:
    """Explicitly registers a built-in FFI version.

    If ``version`` is omitted, the version supported by the installed JAX is
    registered. Multiple supported versions may be registered in one process.
    """
    if version is None:
        version = get_cutlass_call_ffi_version()

    with _FFI_REGISTRATION_LOCK:
        _register_ffi(version)


def set_ffi_call_targets(
    default_call_target: str,
    no_cuda_graph_call_target: str | None = None,
) -> None:
    """Overrides the process-wide targets used by future ``cutlass_call`` objects.

    If ``no_cuda_graph_call_target`` is omitted, ``default_call_target`` is used
    for both CUDA graph modes. CuTeDSL does not register these targets or add
    export safety checks for them; the caller is responsible for both. Explicit
    :func:`register_ffi` calls continue to register built-in targets.
    """
    if no_cuda_graph_call_target is None:
        no_cuda_graph_call_target = default_call_target

    global _FFI_CALL_TARGETS_OVERRIDE
    with _FFI_REGISTRATION_LOCK:
        _FFI_CALL_TARGETS_OVERRIDE = (
            default_call_target,
            no_cuda_graph_call_target,
        )


def _register_and_get_default_ffi_call_target(allow_cuda_graph: bool) -> str:
    """Returns and, unless disabled, registers the JAX-compatible FFI target."""
    with _FFI_REGISTRATION_LOCK:
        if _FFI_CALL_TARGETS_OVERRIDE is not None:
            return _FFI_CALL_TARGETS_OVERRIDE[0 if allow_cuda_graph else 1]

        version = get_cutlass_call_ffi_version()
        if _AUTOMATIC_FFI_REGISTRATION_ENABLED:
            _register_ffi(version)
        return get_cutlass_call_ffi_name(allow_cuda_graph, version)


def disable_automatic_ffi_registration() -> None:
    """Disables registration initiated by future ``cutlass_call`` objects.

    Call this before constructing a ``cutlass_call`` to prevent its automatic
    registration.
    Existing registrations are unchanged, and explicit :func:`register_ffi`
    calls remain enabled. This operation is process-wide and idempotent.
    """
    global _AUTOMATIC_FFI_REGISTRATION_ENABLED
    with _FFI_REGISTRATION_LOCK:
        _AUTOMATIC_FFI_REGISTRATION_ENABLED = False


def is_ffi_registered(version: int | None = None, *, name: str | None = None) -> bool:
    """Returns whether this module registered an FFI version or call/type name.

    ``name`` checks an individual built-in call target or type registered by
    this module. Without a selector, this checks the built-in version supported
    by the installed JAX.
    """
    if version is not None and name is not None:
        raise ValueError("'version' and 'name' cannot both be specified")
    if name is not None:
        with _FFI_REGISTRATION_LOCK:
            return name in _REGISTERED_FFI_CALL_TARGETS or name in _REGISTERED_FFI_TYPES
    if version is None:
        version = get_cutlass_call_ffi_version()
    with _FFI_REGISTRATION_LOCK:
        return _is_ffi_version_registered(version)
