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

from functools import cache

@cache
def is_available():
    """Returns true of Jax support is enabled."""
    try:
        import jax

        _HAVE_JAX = True
    except ImportError as e:
        _HAVE_JAX = False

    return _HAVE_JAX


if is_available():
    from .primitive import cutlass_call
    from .types import (
        jax_to_cutlass_dtype,
        cutlass_to_jax_dtype,
        from_dlpack,
        JaxArray,
        TensorSpec,
    )
    from .compile import (
        release_compile_cache,
        initialize_cutlass_dsl,
    )
    from .ffi import (
        get_export_disabled_safety_checks,
        find_cute_dsl_runtime_library,
        register_ffi,
        is_ffi_registered,
    )
    from . import testing

    # This is a legacy name for TensorSpec. It will be removed eventually.
    TensorMode = TensorSpec

    # This explicit init method ensures that we avoid initialization at
    # unexpected times in jax tracing.
    initialize_cutlass_dsl()

    __all__ = [
        "cutlass_call",
        "jax_to_cutlass_dtype",
        "cutlass_to_jax_dtype",
        "from_dlpack",
        "JaxArray",
        "TensorSpec",
        "TensorMode",
        "release_compile_cache",
        "get_export_disabled_safety_checks",
        "is_available",
        "testing",
    ]
else:
    # export is_available check for callers or tests.
    __all__ = ["is_available"]
