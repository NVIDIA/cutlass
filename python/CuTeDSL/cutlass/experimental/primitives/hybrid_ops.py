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

"""``cutlass.experimental.primitives.hybrid_ops`` -- ops valid in both contexts.

Operations that work in both GPU (``@cute.kernel``) and CPU (``@cute.jit``)
contexts.
"""

from cutlass import dsl_user_op
from cutlass.base_dsl.array import _print_runtime_impl


@dsl_user_op
def print_runtime(
    fmt: str,
    *args: object,
    loc: object = None,
    ip: object = None,
) -> None:
    """Print formatted output at runtime (works on both CPU and GPU).

    Uses vprintf internally, which is available on both CPU (libc) and
    GPU (device printf). Supports f-strings when used with the DSL preprocessor.

    Args:
        fmt: Printf-style format string (e.g., "x = %d, y = %f\\n")
             Or an f-string: f"x = {x}, y = {y}"
        *args: Values to print (MLIR Values or DSL types like Int32, Float32)

    Example:
        from cutlass import Int32, Float32
        from cutlass.experimental.primitives import print_runtime

        x = Int32(42)
        y = Float32(3.14)

        # Printf-style
        print_runtime("x = %d, y = %f\\n", x, y)

        # F-string style (requires DSL preprocessor)
        print_runtime(f"x = {x}, y = {y}\\n")
    """
    _print_runtime_impl(fmt, *args, loc=loc, ip=ip)


__all__ = [
    "print_runtime",
]
