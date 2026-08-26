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

import functools
from typing import Any

from typing_extensions import deprecated

from cutlass.block import block_copy as _block_copy


@deprecated(
    "cutlass.utils.block.block_copy is deprecated; use cutlass.block.block_copy "
    "instead. It will be removed in a future release."
)
@functools.wraps(_block_copy)
def block_copy(*args: Any, **kwargs: Any) -> Any:
    return _block_copy(*args, **kwargs)


__all__ = [
    "block_copy",
]
