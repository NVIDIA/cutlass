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

from functools import cache
import logging

logger = logging.getLogger(__name__)

# This is the minimum JAX version that will work with CuTeDSL JAX extensions.
#
# See the following pages for details on JAX versioning:
#   - https://docs.jax.dev/en/latest/jep/25516-effver.html
#   - https://docs.jax.dev/en/latest/jep/9419-jax-versioning.html
CUTE_DSL_MIN_SUPPORTED_JAX_VERSION = (0, 5, 0)


@cache
def is_available():
    """Returns true if JAX extensions are supported and available."""
    try:
        import jax
        import jax.numpy  # Also verify jax.numpy is available
    except ImportError:
        logger.debug(
            "CuTeDSL JAX extensions are not available because JAX was not found or could not be imported."
        )
        return False

    if not (
        hasattr(jax.version, "__version_info__")
        and jax.version.__version_info__ >= CUTE_DSL_MIN_SUPPORTED_JAX_VERSION
    ):
        logger.debug(
            f"Your installed JAX v{jax.__version__} too old and not supported by CuTeDSL JAX extensions.\n"
            "Please upgrade to the latest version."
        )
        return False

    return True


if is_available():
    from .primitive import cutlass_call
    from .types import (
        jax_to_cutlass_dtype,
        cutlass_to_jax_dtype,
        jax_to_cutlass_layout_order,
        cutlass_to_jax_layout_order,
        from_dlpack,
        JaxArray,
        TensorSpec,
    )
    from .compile import (
        release_compile_cache,
    )
    from .ffi import (
        get_export_disabled_safety_checks,
        find_cute_dsl_runtime_library,
        register_ffi,
        is_ffi_registered,
        get_cutlass_call_ffi_version,
    )
    from . import testing

    # This is a legacy name for TensorSpec. It will be removed eventually.
    TensorMode = TensorSpec

    __all__ = [
        "CUTE_DSL_MIN_SUPPORTED_JAX_VERSION",
        "cutlass_call",
        "jax_to_cutlass_dtype",
        "cutlass_to_jax_dtype",
        "jax_to_cutlass_layout_order",
        "cutlass_to_jax_layout_order",
        "from_dlpack",
        "JaxArray",
        "TensorSpec",
        "TensorMode",
        "release_compile_cache",
        "get_export_disabled_safety_checks",
        "is_ffi_registered",
        "register_ffi",
        "get_cutlass_call_ffi_version",
        "is_available",
        "testing",
    ]
else:
    # export is_available check for callers or tests.
    __all__ = ["CUTE_DSL_MIN_SUPPORTED_JAX_VERSION", "is_available"]
