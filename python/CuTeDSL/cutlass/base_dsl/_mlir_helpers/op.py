# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""
This module provides MLIR's OP helper functions
"""

import inspect
from functools import wraps

from ..._mlir import ir


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
        if loc is None:
            frame = inspect.currentframe().f_back
            frameInfo = inspect.getframeinfo(frame)
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
                    frameInfo.positions.col_offset,
                )
            loc = ir.Location.name(
                (
                    "".join([c.strip() for c in frameInfo.code_context])
                    if frameInfo.code_context
                    else frameInfo.function
                ),
                childLoc=file_loc,
            )
        res_or_list = opFunc(*args, **kwargs, loc=loc)
        return res_or_list

    return wrapper
