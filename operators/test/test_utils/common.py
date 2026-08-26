# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from __future__ import annotations

import os
from typing import TYPE_CHECKING

import pytest

import cutlass.operators as ops
from cutlass.operators.utils.device import device_or_env_target_sm

if TYPE_CHECKING:
    from collections.abc import Iterable

# Environment variable used to propagate the test level ("L0" / "L1" / "L2")
# to helpers invoked during test collection
_TEST_LEVEL_ENV_VAR = "CUTLASS_OPERATORS_TEST_LEVEL"


def reference_device() -> str:
    """Return the device reference computation and comparison should run on."""
    return "cuda"


def get_test_level() -> str:
    """Return the test level set via ``CUTLASS_OPERATORS_TEST_LEVEL`` (defaults to ``"L0"``)."""
    return os.environ.get(_TEST_LEVEL_ENV_VAR, "L0")


def skip_if_unsupported_target(operator_targets: Iterable[ops.TargetSm | str]) -> None:
    """
    Skips the test if the current device or CUTE_DSL_ARCH does not support the requested Operator targets.

    :param operator_targets: Set of Operator targets to check compatibility for
    :type operator_targets: Iterable[TargetSm | str]
    """
    operator_targets = {ops.TargetSm.ensure(sm) for sm in operator_targets}

    device_sm = device_or_env_target_sm()
    if not device_sm.supports_operators_from(operator_targets):
        pytest.skip(
            f"Current device {device_sm} does not support requested Operator targets {operator_targets}"
        )


