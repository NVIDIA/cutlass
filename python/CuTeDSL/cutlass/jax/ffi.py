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

from typing import Sequence, Optional
from pathlib import Path
from functools import cache
import logging
import ctypes

import cutlass
from cutlass.base_dsl.env_manager import find_libs_in_ancestors
from cutlass.cutlass_dsl.cutlass import CuTeDSL

import jax
import jax.export

logger = logging.getLogger(__name__)

_CUTE_DSL_RUNTIME_LIBRARY_NAME = "cute_dsl_runtime"

# V1 targets for older jax clients
_CUTLASS_CALL_TARGETS_V1 = {
    "CuteDSLRT_NvJaxCutlassCall": {
        "prepare": "CuteDSLRT_NvJaxCutlassCallPrepare_v1",
        "execute": "CuteDSLRT_NvJaxCutlassCallExecute_v1",
    },
    "CuteDSLRT_NvJaxCutlassCallNoCudaGraph": {
        "prepare": "CuteDSLRT_NvJaxCutlassCallPrepare_v1",
        "execute": "CuteDSLRT_NvJaxCutlassCallExecuteNoCudaGraph_v1",
    },
}

# V2 targets for newer jax clients supporting stateful FFI calls.
_JAX_FFI_V2_MIN_VERSION = (0, 9, 1)
_CUTLASS_CALL_TARGETS_V2 = {
    "CuteDSLRT_NvJaxCutlassCall": {
        "execute": "CuteDSLRT_NvJaxCutlassCallExecute_v2",
        "instantiate": "CuteDSLRT_NvJaxCutlassCallInstantiate_v2",
        "prepare": "CuteDSLRT_NvJaxCutlassCallPrepare_v2",
    },
    "CuteDSLRT_NvJaxCutlassCallNoCudaGraph": {
        "execute": "CuteDSLRT_NvJaxCutlassCallExecuteNoCudaGraph_v2",
        "instantiate": "CuteDSLRT_NvJaxCutlassCallInstantiate_v2",
        "prepare": "CuteDSLRT_NvJaxCutlassCallPrepare_v2",
    },
}
_CUTLASS_CALL_TYPES_V2 = {
    "CuteDSLRT_NvJaxCutlassCallTypes": {
        "type_id": "CuteDSLRT_NvJaxCutlassCallStateTypeId_v2",
        "type_info": "CuteDSLRT_NvJaxCutlassCallStateTypeInfo_v2",
    }
}


def get_cutlass_call_ffi_version() -> int:
    """Returns the FFI API version based on JAX version."""
    if jax.version.__version_info__ >= _JAX_FFI_V2_MIN_VERSION:
        return 2
    else:
        return 1


def get_cutlass_call_ffi_name(allow_cuda_graph: bool) -> str:
    """Returns the FFI target to call when running cutlass_call functions."""
    if allow_cuda_graph:
        return "CuteDSLRT_NvJaxCutlassCall"
    else:
        return "CuteDSLRT_NvJaxCutlassCallNoCudaGraph"


def get_export_disabled_safety_checks() -> Sequence[jax.export.DisabledSafetyCheck]:
    """Returns jax.export.DisabledSafetyCheck to allow cutlass_call kernels."""
    targets = set(_CUTLASS_CALL_TARGETS_V1.keys()) | set(
        _CUTLASS_CALL_TARGETS_V2.keys()
    )
    return tuple([jax.export.DisabledSafetyCheck.custom_call(t) for t in targets])


@cache
def find_cute_dsl_runtime_library() -> Optional[str]:
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
        def get_libs_cand(start):
            libs_cand = find_libs_in_ancestors(
                start, [_CUTE_DSL_RUNTIME_LIBRARY_NAME], ["lib"]
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


_FFI_CALLS_REGISTERED = False


def register_ffi(ffi_version: int = get_cutlass_call_ffi_version()):
    """Registers custom calls with Jax/XLA runtime.

    A specific version can be requested using `ffi_version` argument. Attempting
    to register non default FFI versions may not work with your specific JAX.
    """
    global _FFI_CALLS_REGISTERED
    if _FFI_CALLS_REGISTERED:
        return

    runtime_library = find_cute_dsl_runtime_library()
    if not runtime_library:
        logger.debug(
            "No CuTeDSL runtime library found - skipping python ffi registration."
        )
        return

    lib = ctypes.CDLL(runtime_library)

    def _register_ffi_targets(lib, targets):
        for target_name, target in targets.items():
            handler = {}
            for stage, fn_name in target.items():
                fn = getattr(lib, fn_name)
                fn.restype = ctypes.c_void_p
                handler[stage] = jax.ffi.pycapsule(fn)
            logger.debug(f"Registering ffi handler: {target_name}, {handler}")
            jax.ffi.register_ffi_target(target_name, handler, platform="CUDA")

    def _register_ffi_types(lib, types):
        for type_name, type_dict_targets in types.items():
            type_dict = {}
            for field, fn_name in type_dict_targets.items():
                fn = getattr(lib, fn_name)
                fn.restype = ctypes.c_void_p
                type_dict[field] = jax.ffi.pycapsule(fn())
            logger.debug(f"Registering ffi type: {type_name}, {type_dict}")
            jax.ffi.register_ffi_type(type_name, type_dict, platform="CUDA")  # type: ignore[arg-type]

    # Register the custom FFI targets.
    match ffi_version:
        case 1:
            _register_ffi_targets(lib, _CUTLASS_CALL_TARGETS_V1)
            # no types for v1
        case 2:
            _register_ffi_types(lib, _CUTLASS_CALL_TYPES_V2)
            _register_ffi_targets(lib, _CUTLASS_CALL_TARGETS_V2)
        case _:
            raise ValueError(f"Invalid FFI version {ffi_version}")

    _FFI_CALLS_REGISTERED = True


def is_ffi_registered():
    """Returns true if the FFI calls have been registered with Jax/XLA."""
    global _FFI_CALLS_REGISTERED
    return _FFI_CALLS_REGISTERED
