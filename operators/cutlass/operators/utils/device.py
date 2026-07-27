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

import importlib
import logging
import os
from collections.abc import Iterable
from typing import TYPE_CHECKING, Any

import cutlass.operators.utils.common as common
from cutlass.operators.arch import TargetSm
from cutlass.operators.config import GlobalOptions
from cutlass.operators.status import Status

_logger = logging.getLogger(__name__)

if TYPE_CHECKING:
    import cuda
    import torch


def _lazy_import(mod_name: str) -> Any:
    """Internal utility to lazily import a module only when needed."""

    class Lazy:
        def __getattr__(self, name: str) -> Any:
            module = importlib.import_module(mod_name)
            return getattr(module, name)

    return Lazy()


def check_cuda_errors(result: list) -> Any:
    """Check whether ``result`` contains a CUDA error and raise it, otherwise return the rest.

    Args:
        result (list): Result of a ``cuda`` method, of the form
            ``(cudaError_t, result...)`` -- an error code followed by any method results.

    Returns:
        Any: Non-error-code results from ``result``. Returns ``None`` when the only element
        is the (success) error code, the single result when there is exactly one, or the
        tuple of remaining results otherwise.

    Raises:
        RuntimeError: If the leading error code in ``result`` is non-zero.
    """
    # `result` is of the format : (cudaError_t, result...)
    err = result[0]
    if err.value:
        _lazy_import("cuda.cuda")
        cuda_bindings_runtime = _lazy_import("cuda.bindings.runtime")
        raise RuntimeError(
            f"CUDA error: {cuda_bindings_runtime.cudaGetErrorString(err)[1].decode('utf-8')}"
        )

    if len(result) == 1:
        return None
    elif len(result) == 2:
        return result[1]
    else:
        return result[1:]


def device_cc(device: int = 0) -> int:
    """Query the device with ID ``device`` and return its compute capability.

    Args:
        device (int): ID of the device to query.

    Returns:
        int: Compute capability of the queried device (e.g., ``80`` for SM80).
    """
    _lazy_import("cuda.cuda")
    cuda_bindings_runtime = _lazy_import("cuda.bindings.runtime")
    deviceProp = check_cuda_errors(
        cuda_bindings_runtime.cudaGetDeviceProperties(device)
    )
    major = str(deviceProp.major)
    minor = str(deviceProp.minor)
    return int(major + minor)


def device_or_env_target_sm(
    device: int = 0, env_var: str = "CUTE_DSL_ARCH"
) -> TargetSm:
    """Return the target SM from environment variable ``env_var`` or device ``device``.

    The environment variable takes precedence over device detection.

    Args:
        device (int): CUDA device ID to query when the environment variable is not set.
        env_var (str): Name of the environment variable that overrides device detection.
            Expected format is ``"sm_<cc>"`` (e.g. ``"sm_100a"``).

    Returns:
        TargetSm: The target SM corresponding to the environment variable or the physical device.

    Raises:
        ValueError: If the environment variable is set but cannot be parsed as a valid ``TargetSm``.
    """
    cute_dsl_arch = os.environ.get(env_var, None)
    if cute_dsl_arch:
        try:
            return TargetSm(cute_dsl_arch.removeprefix("sm_"))
        except ValueError as e:
            raise ValueError(f"Invalid CUTE_DSL_ARCH: {cute_dsl_arch}. {e}") from e
    cc = device_cc(device)
    return TargetSm(cc=cc)


def device_or_env_supports(
    requested_targets: TargetSm | str | Iterable[TargetSm | str],
) -> Status:
    """Check whether the current device (or ``CUTE_DSL_ARCH``) supports ``requested_targets``.

    Args:
        requested_targets (TargetSm | str | Iterable[TargetSm | str]):
            Operator target(s) to check compatibility for.

    Returns:
        Status: ``Status.success()`` if the device or ``CUTE_DSL_ARCH`` supports
        ``requested_targets``; otherwise ``Status.fail(...)`` with a descriptive message.
    """
    try:
        # Allow passing a single target directly.
        if isinstance(requested_targets, str) or not isinstance(
            requested_targets, Iterable
        ):
            requested_targets = (requested_targets,)

        device = device_or_env_target_sm()
        if not device.supports_operators_from(requested_targets):
            return Status.fail(
                f"Device/CUTE_DSL_ARCH {device} does not support {requested_targets}."
            )
        return Status.success()
    except Exception as e:
        return Status.fail(f"Failed to get device or CUTE_DSL_ARCH: {e}")



def device_l2_cache_size(device: int | None = None) -> int:
    """Return L2 cache size in bytes for the requested device.

    Args:
        device (int | None): CUDA device ID to query. If ``None``, uses the current device.

    Returns:
        int: L2 cache size in bytes.
    """
    cuda_bindings_runtime = _lazy_import("cuda.bindings.runtime")
    if device is None:
        device = check_cuda_errors(cuda_bindings_runtime.cudaGetDevice())
    device_prop = check_cuda_errors(
        cuda_bindings_runtime.cudaGetDeviceProperties(device)
    )
    return device_prop.l2CacheSize


def to_cuda_stream(
    stream: cuda.bindings.driver.CUstream | torch.cuda.Stream,
    skip_if_ffi: bool = True,
) -> cuda.bindings.driver.CUstream:
    """Convert the provided stream to a ``cuda.bindings.driver.CUstream``.

    Args:
        stream (cuda.bindings.driver.CUstream | torch.cuda.Stream):
            The stream to convert.
        skip_if_ffi (bool): If ``True`` and TVM-FFI is enabled in
            :class:`~cutlass.operators.config.GlobalOptions`, return ``stream`` unchanged
            (TVM-FFI handles stream types directly, including raw int handles).

    Returns:
        cuda.bindings.driver.CUstream: The converted stream.

    Raises:
        ValueError: If ``stream`` is of an unsupported type.
    """
    if skip_if_ffi and GlobalOptions().use_tvm_ffi:
        # TVM-FFI can directly handle streams of various types, including raw int handles
        return stream

    cuda = _lazy_import("cuda.bindings.driver")
    if isinstance(stream, cuda.CUstream):
        return stream
    if common.is_torch_available():
        import torch

        if isinstance(stream, torch.cuda.Stream):
            return cuda.CUstream(stream.cuda_stream)
    raise ValueError(f"Unsupported stream type: {type(stream)}")


def get_cuda_version() -> tuple[int, int] | None:
    """Get the CUDA runtime version as a ``(major, minor)`` tuple.

    Returns:
        tuple[int, int] | None: CUDA version tuple ``(major, minor)``, or ``None``
        if the version cannot be determined.

    Example:
        >>> get_cuda_version()
        (12, 4)  # CUDA 12.4
    """
    try:
        cuda_bindings_runtime = _lazy_import("cuda.bindings.runtime")
        err, version = cuda_bindings_runtime.cudaRuntimeGetVersion()
        if err.value == 0:
            # Version is encoded as major * 1000 + minor * 10
            major = version // 1000
            minor = (version % 1000) // 10
            return (major, minor)
        else:
            _logger.debug(
                "cudaRuntimeGetVersion returned non-zero error code: %s", err.value
            )
    except Exception as e:
        _logger.debug("Failed to import cuda.bindings.runtime: %s", e)
    return None
