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

from ... import cutlass_dsl as _dsl

jit = _dsl.CuteExperimentalDSL.jit
kernel = _dsl.CuteExperimentalDSL.kernel
compile = _dsl.CompileCallable()

from .algorithm import *
from .core import *
from .host_runtime import *
from .math import *
from .memory import *
from .pipeline import *
from .utils import *

try:
    from . import iket
except ImportError:

    class _IketUnavailable:
        """Stub so that ``cute.experimental.iket.<anything>`` gives a clear error."""

        def __getattr__(self, name: str) -> None:
            raise ImportError(
                "IKET (In-Kernel Event Tracing) is not available in this "
                "installation. Reinstall nvidia-cutlass-dsl to restore it."
            )

    iket = _IketUnavailable()  # type: ignore[assignment]
