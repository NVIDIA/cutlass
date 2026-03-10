# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from typing import Sequence
from pathlib import Path
from functools import cache
import os
import logging
import ctypes

import cutlass
from cutlass.base_dsl.env_manager import find_libs_in_ancestors
from cutlass.cutlass_dsl.cutlass import CuTeDSL

import jax
import jax.export

logger = logging.getLogger(__name__)

_CUTE_DSL_RUNTIME_LIBRARY_NAME = "cute_dsl_runtime"

_CUTLASS_CALL_TARGETS = {
    "CuteDSLRT_NvJaxCutlassCall": {"execute": "CuteDSLRT_NvJaxCutlassCallExecute"},
    "CuteDSLRT_NvJaxCutlassCallNoCudaGraph": {
        "execute": "CuteDSLRT_NvJaxCutlassCallExecuteNoCudaGraph"
    },
}


def get_cutlass_call_ffi_name(allow_cuda_graph):
    """Returns the FFI target to call when running cutlass_call functions."""
    disable_cuda_graph = not allow_cuda_graph
    if not disable_cuda_graph:
        return "CuteDSLRT_NvJaxCutlassCall"
    else:
        return "CuteDSLRT_NvJaxCutlassCallNoCudaGraph"


def get_export_disabled_safety_checks() -> Sequence[jax.export.DisabledSafetyCheck]:
    """Returns jax.export.DisabledSafetyCheck to allow cutlass_call kernels."""
    checks = []
    for target in _CUTLASS_CALL_TARGETS:
        checks.append(jax.export.DisabledSafetyCheck.custom_call(target))
    return tuple(checks)


@cache
def find_cute_dsl_runtime_library():
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
        logger.debug(f"Failed to locate libraries due to an exception:", e)

    for lib in candidate_libs:
        if lib.endswith(f"{_CUTE_DSL_RUNTIME_LIBRARY_NAME}.so"):
            return lib

    return None


_FFI_CALLS_REGISTERED = False


def register_ffi():
    """Registers custom calls with Jax/XLA runtime."""
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

    def _capsule(funcptr):
        destructor = ctypes.CFUNCTYPE(None, ctypes.py_object)
        builder = ctypes.pythonapi.PyCapsule_New
        builder.restype = ctypes.py_object
        builder.argtypes = (ctypes.c_void_p, ctypes.c_char_p, destructor)
        return builder(funcptr, None, destructor(0))

    def _register_ffi_targets(lib, targets):
        for target_name, target in targets.items():
            handler = {}
            for stage, fn_name in target.items():
                fn = getattr(lib, fn_name)
                fn.restype = ctypes.c_void_p
                handler[stage] = _capsule(fn)
            logger.debug(f"Registering ffi handler: {target_name}, {handler}")
            jax.ffi.register_ffi_target(
                target_name, handler["execute"], platform="CUDA"
            )

    # Register the custom FFI targets
    _register_ffi_targets(lib, _CUTLASS_CALL_TARGETS)

    _FFI_CALLS_REGISTERED = True


def is_ffi_registered():
    """Returns true if the FFI calls have been registered with Jax/XLA."""
    global _FFI_CALLS_REGISTERED
    return _FFI_CALLS_REGISTERED
