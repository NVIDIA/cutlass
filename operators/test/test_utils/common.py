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

import functools
import os
from typing import TYPE_CHECKING

import pytest
import torch

import cutlass.operators as ops
from cutlass.operators.utils.device import device_or_env_target_sm

if TYPE_CHECKING:
    from collections.abc import Iterable

# Environment variable used to propagate the test level ("L0" / "L1" / "L2")
# to helpers invoked during test collection
_TEST_LEVEL_ENV_VAR = "CUTLASS_OPERATORS_TEST_LEVEL"

_CUDA_DEVICE_ENV_VAR = "CUTLASS_OPERATORS_TEST_CUDA_DEVICE"


def reference_device() -> str:
    """Return the device reference computation and comparison should run on."""
    return "cuda"


@functools.cache
def get_cuda_device_id() -> int:
    """Return the CUDA device every part of a test session must agree on.

    Cached: consumers ask at different times, and module-level pools are built
    during collection, before any fixture runs.
    """
    device_id = int(os.environ.get(_CUDA_DEVICE_ENV_VAR, "0"))
    count = torch.cuda.device_count() if torch.cuda.is_available() else 0
    if count and not 0 <= device_id < count:
        raise ValueError(
            f"{_CUDA_DEVICE_ENV_VAR}={device_id} is not a visible CUDA device "
            f"(this host exposes {count})"
        )
    return device_id


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



def _cuda_status_failed(error: object) -> bool:
    """Return whether a cuda-bindings status object is a non-success error.

    String placeholders used in unit tests (``"ok"``) have no numeric
    ``value`` and are treated as success.
    """
    value = getattr(error, "value", None)
    if isinstance(value, int):
        return value != 0
    name = getattr(error, "name", None)
    if isinstance(name, str):
        return name not in {"cudaSuccess", "CUDA_SUCCESS"}
    return False


def unpack_cuda_graph_get_edges(result: tuple, *, filling: bool):
    """Normalize ``cudaGraphGetEdges`` across cuda-python 12 and 13.3.

    A fill that omitted ``edgeData`` on a PDL graph returns
    ``cudaErrorLossyQuery`` and a 4-tuple of Nones.
    That is a CUDA status, not a Python arity bug — return the error so
    the caller can retry with an ``edgeData`` buffer.
    """
    error = result[0]
    if not filling:
        return error, None, result[-1]
    if _cuda_status_failed(error):
        return error, None, None
    if len(result) >= 5:
        return error, result[3], result[-1]
    edge_data = result[3] if len(result) == 4 else None
    if edge_data is None or isinstance(edge_data, int):
        raise RuntimeError(
            "cudaGraphGetEdges fill query did not return edge payloads: "
            f"arity={len(result)}"
        )
    return error, edge_data, len(edge_data)


