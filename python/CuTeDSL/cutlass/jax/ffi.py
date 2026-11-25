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
from threading import Lock
import logging
import ctypes

from cutlass.cutlass_dsl.cutlass_env_manager import find_cute_dsl_runtime_library

import jax
import jax.export

logger = logging.getLogger(__name__)

_JAX_FFI_V2_MIN_VERSION = (0, 9, 1)

# CuTeDSL call ABI versions are independent of the XLA FFI API version. These
# are the logical wrapper signatures; CompactBuffer is ``{data, dims}``.
#
# V1:
#   cutlass_call_fn(
#       CUstream, CompactBuffer inputs..., CompactBuffer outputs..., cudaError_t*)
#   Attributes: ``module``, ``key``. Stateless; no workspace outputs.
#
# V2:
#   cutlass_call_fn(
#       CUstream, CompactBuffer inputs..., CompactBuffer outputs..., cudaError_t*)
#   Same attributes as V1. Runtime state is tied to the owning XLA computation;
#   no workspace outputs.
#
# V3:
#   cutlass_call_fn(
#       CUstream, XLA_FFI_Buffer* inputs..., XLA_FFI_Buffer* outputs...,
#       void* workspaces..., cudaError_t*)
#   Attributes: ``module``, ``key``, ``ffi_abi_version``, and
#   ``num_workspace_outputs``. Runtime state is tied to the owning XLA
#   computation. Workspaces are trailing outputs passed as device pointers.
#
# Callers select a contract with ``ffi_abi_version``; omitting it uses the
# process-wide default. All versions load modules in Prepare.
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
    # V2 preserves stateful calls without compiler-managed workspace metadata.
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
    # V3 adds compiler-managed workspace metadata and passes public XLA C
    # buffer descriptors directly to compiled wrappers.
    3: {
        "CuteDSLRT_NvJaxCutlassCall_v3": {
            "execute": "CuteDSLRT_NvJaxCutlassCallExecute_v3",
            "instantiate": "CuteDSLRT_NvJaxCutlassCallInstantiate_v3",
            "prepare": "CuteDSLRT_NvJaxCutlassCallPrepare_v3",
        },
        "CuteDSLRT_NvJaxCutlassCallNoCudaGraph_v3": {
            "execute": "CuteDSLRT_NvJaxCutlassCallExecuteNoCudaGraph_v3",
            "instantiate": "CuteDSLRT_NvJaxCutlassCallInstantiate_v3",
            "prepare": "CuteDSLRT_NvJaxCutlassCallPrepare_v3",
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
    3: {
        "CuteDSLRT_NvJaxCutlassCallTypes_v3": {
            "type_id": "CuteDSLRT_NvJaxCutlassCallStateTypeId_v3",
            "type_info": "CuteDSLRT_NvJaxCutlassCallStateTypeInfo_v3",
        }
    },
}
_CUTLASS_CALL_VERSION_DEPENDENCIES = {3: (2,)}
_LATEST_CUTLASS_CALL_ABI_VERSION = max(_CUTLASS_CALL_TARGETS)

_FFI_REGISTRATION_LOCK = Lock()
_REGISTERED_FFI_CALL_TARGETS: set[str] = set()
_REGISTERED_FFI_TYPES: set[str] = set()
_AUTOMATIC_FFI_REGISTRATION_ENABLED = True
_FFI_CALL_TARGETS_OVERRIDE: tuple[str, str] | None = None
_CUTLASS_CALL_FFI_VERSION_OVERRIDE: int | None = None


def get_cutlass_call_ffi_version() -> int:
    """Returns the process-wide default CuTeDSL call ABI version."""
    with _FFI_REGISTRATION_LOCK:
        override = _CUTLASS_CALL_FFI_VERSION_OVERRIDE
    if override is not None:
        return override
    return (
        _LATEST_CUTLASS_CALL_ABI_VERSION
        if jax.version.__version_info__ >= _JAX_FFI_V2_MIN_VERSION
        else 1
    )


def _validate_cutlass_call_ffi_abi_version(version: int) -> None:
    if (
        not isinstance(version, int)
        or isinstance(version, bool)
        or version not in _CUTLASS_CALL_TARGETS
    ):
        supported = ", ".join(str(item) for item in _CUTLASS_CALL_TARGETS)
        raise ValueError(
            f"Unsupported CuTeDSL FFI call ABI version {version!r}; "
            f"expected one of: {supported}"
        )


def set_cutlass_call_ffi_version(version: int | None) -> None:
    """Overrides the process-wide ABI version used by future FFI calls.

    ``None`` restores automatic selection based on the installed JAX version.
    Explicit ``ffi_abi_version`` arguments continue to take precedence.
    Existing callables and registrations are unchanged.
    """
    if version is not None:
        _validate_cutlass_call_ffi_abi_version(version)

    global _CUTLASS_CALL_FFI_VERSION_OVERRIDE
    with _FFI_REGISTRATION_LOCK:
        _CUTLASS_CALL_FFI_VERSION_OVERRIDE = version


def get_cutlass_call_ffi_name(allow_cuda_graph: bool, version: int) -> str:
    """Returns the FFI target for ``version``."""
    _validate_cutlass_call_ffi_abi_version(version)
    suffix = "" if allow_cuda_graph else "NoCudaGraph"
    return f"CuteDSLRT_NvJaxCutlassCall{suffix}_v{version}"


def _get_cutlass_call_target_version(target: str) -> int | None:
    """Returns the ABI version of a built-in target, or ``None`` if external."""
    return next(
        (
            version
            for version, targets in _CUTLASS_CALL_TARGETS.items()
            if target in targets
        ),
        None,
    )


def get_export_disabled_safety_checks() -> Sequence[jax.export.DisabledSafetyCheck]:
    """Returns export safety checks for the built-in FFI targets."""
    targets = set().union(*_CUTLASS_CALL_TARGETS.values())
    return tuple(
        jax.export.DisabledSafetyCheck.custom_call(target) for target in sorted(targets)
    )


def _is_ffi_version_registered(version: int) -> bool:
    return all(
        name in _REGISTERED_FFI_CALL_TARGETS for name in _CUTLASS_CALL_TARGETS[version]
    ) and all(name in _REGISTERED_FFI_TYPES for name in _CUTLASS_CALL_TYPES[version])


def _register_ffi(version: int) -> None:
    """Registers ``version`` while ``_FFI_REGISTRATION_LOCK`` is held."""
    _validate_cutlass_call_ffi_abi_version(version)
    for dependency in _CUTLASS_CALL_VERSION_DEPENDENCIES.get(version, ()):
        _register_ffi(dependency)

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

    If ``version`` is omitted, the process-wide default is registered together
    with its compatibility dependencies. Multiple supported versions may be
    registered in one process.
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
    :func:`register_ffi` calls continue to register built-in targets. Each
    :func:`cutlass_call` must select the ABI implemented by the override using
    its ``ffi_abi_version`` argument or the process-wide default.
    """
    if no_cuda_graph_call_target is None:
        no_cuda_graph_call_target = default_call_target

    global _FFI_CALL_TARGETS_OVERRIDE
    with _FFI_REGISTRATION_LOCK:
        _FFI_CALL_TARGETS_OVERRIDE = (
            default_call_target,
            no_cuda_graph_call_target,
        )


def _register_and_get_default_ffi_call_target(
    allow_cuda_graph: bool, version: int
) -> str:
    """Returns and, unless disabled, registers the JAX-compatible FFI target."""
    _validate_cutlass_call_ffi_abi_version(version)
    with _FFI_REGISTRATION_LOCK:
        if _FFI_CALL_TARGETS_OVERRIDE is not None:
            return _FFI_CALL_TARGETS_OVERRIDE[0 if allow_cuda_graph else 1]

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
    this module. Without a selector, this checks the process-wide default.
    """
    if version is not None and name is not None:
        raise ValueError("'version' and 'name' cannot both be specified")
    if name is not None:
        with _FFI_REGISTRATION_LOCK:
            return name in _REGISTERED_FFI_CALL_TARGETS or name in _REGISTERED_FFI_TYPES
    if version is None:
        version = get_cutlass_call_ffi_version()
    _validate_cutlass_call_ffi_abi_version(version)
    with _FFI_REGISTRATION_LOCK:
        return _is_ffi_version_registered(version)
