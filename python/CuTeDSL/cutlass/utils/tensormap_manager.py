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

import warnings
from typing import Any

from typing_extensions import deprecated

from cutlass.tensor_utils.tensormap import TensorMapManager as _TensorMapManager


@deprecated(
    "cutlass.utils.tensormap_manager.TensorMapManager is deprecated; use "
    "cutlass.tensor_utils.TensorMapManager instead. It will be removed in a future "
    "release."
)
class TensorMapManager(_TensorMapManager):
    """Deprecated alias for `cutlass.tensor_utils.TensorMapManager`."""


# Enum members compare by object identity, so the canonical class itself must
# be handed out rather than a deprecated subclass copy. A module-level
# __getattr__ (PEP 562) adds the deprecation warning a wrapper class cannot.
def __getattr__(name: str) -> Any:
    if name == "TensorMapUpdateMode":
        warnings.warn(
            "cutlass.utils.tensormap_manager.TensorMapUpdateMode is deprecated; "
            "use cutlass.tensor_utils.TensorMapUpdateMode instead. It will be "
            "removed in a future release.",
            DeprecationWarning,
            stacklevel=2,
        )
        from cutlass.tensor_utils.tensormap import TensorMapUpdateMode

        return TensorMapUpdateMode
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


__all__ = [
    "TensorMapManager",
    "TensorMapUpdateMode",  # noqa: F822  # provided by module __getattr__
]
