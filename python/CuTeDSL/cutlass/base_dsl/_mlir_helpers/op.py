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

"""
This module provides MLIR's OP helper functions
"""

import inspect
import os
import types
from functools import wraps

from ..._mlir import ir
from ..common import DSLRuntimeError
from ..utils.stacktrace import walk_to_top_module


# The DSL package root is empty by default.
_DSL_PACKAGE_ROOT = ""


def _is_framework_frame(filename: str) -> bool:
    """Check if a frame's filename belongs to DSL library code."""
    global _DSL_PACKAGE_ROOT
    if _DSL_PACKAGE_ROOT == "":
        # Compute the DSL package root once
        # Any frame whose file starts with this prefix is considered DSL library code.
        _DSL_PACKAGE_ROOT = walk_to_top_module(
            os.path.dirname(os.path.abspath(__file__))
        )

    if _DSL_PACKAGE_ROOT is None:
        return False

    return os.path.abspath(filename).startswith(_DSL_PACKAGE_ROOT)


def _find_user_frame(start_frame: types.FrameType | None) -> types.FrameType | None:
    """Walk up the call stack from start_frame to find the first user (non-library) frame.

    Returns the first frame whose file is not under the DSL package root.
    Falls back to start_frame if no user frame is found (e.g. all frames are library code).
    """
    frame = start_frame
    while frame is not None:
        if not _is_framework_frame(frame.f_code.co_filename):
            return frame
        frame = frame.f_back
    # Fallback: if everything is framework code, use the original caller
    return start_frame


def dsl_user_op(opFunc):
    """
    This is a decorator that needs to be used in each user-facing API to
    manage source location for toolchain.

    :param opFunc: The user-facing API function.
    :type opFunc: Callable
    :return: The wrapped user-facing API function.
    :rtype: Callable
    """

    @wraps(opFunc)
    def wrapper(*args, **kwargs):
        loc = kwargs.pop("loc", None)
        frameInfo = None
        verifier_error = False

        if loc is None and ir.Context.current is not None:
            frame = _find_user_frame(inspect.currentframe().f_back)
            frameInfo = inspect.getframeinfo(frame)
            try:
                # In Python < 3.11, getframeinfo returns a NamedTuple without positions
                if not hasattr(frameInfo, "positions"):
                    file_loc = ir.Location.file(
                        frameInfo.filename,
                        frameInfo.lineno,
                        0,
                    )
                else:
                    file_loc = ir.Location.file(
                        frameInfo.filename,
                        frameInfo.positions.lineno,
                        frameInfo.positions.col_offset or 0,
                    )
                loc = ir.Location.name(
                    (
                        "".join([c.strip() for c in frameInfo.code_context])
                        if frameInfo.code_context
                        else frameInfo.function
                    ),
                    childLoc=file_loc,
                )
            except RuntimeError:
                # No MLIR context available (e.g. validation-only call
                # outside a kernel).  Proceed with loc=None so that the
                # wrapped function's own validation can still fire.
                pass

        try:
            res_or_list = opFunc(*args, **kwargs, loc=loc)
        except TypeError as e:
            # Provide a helpful error message when function doesn't accept 'loc'
            func_name = getattr(opFunc, "__name__", str(opFunc))
            if "unexpected keyword argument 'loc'" in str(e):
                raise DSLRuntimeError(
                    f"Function '{func_name}' decorated with @dsl_user_op does not accept the required 'loc' parameter.",
                    suggestion=[
                        f"1. Add 'loc=None' as a keyword-only parameter to {func_name}:",
                        f"  def {func_name}(..., *, loc=None):",
                        "",
                        f"2. Remove the @dsl_user_op decorator if location tracking is not needed",
                    ],
                    cause=e,
                ) from e
            else:
                # Re-raise other TypeErrors as-is
                raise
        return res_or_list

    return wrapper
