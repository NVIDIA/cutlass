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

import os
import warnings
from importlib.util import find_spec

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


class GlobalOptions:
    """Singleton class that configures global options for CUTLASS Operator API.

    This can be used to enable or disable certain features of the API. For example,
    the user can enable TVM-FFI support to allow for the use of framework-level tensors
    at run time.

    Each option may also be initialized from an environment variable read the
    first time ``GlobalOptions()`` is instantiated. Programmatic changes via the
    property setters always override the environment value afterwards.

    Supported environment variables:

    - ``CUTLASS_OPERATORS_USE_TVM_FFI`` --> ``GlobalOptions().use_tvm_ffi``

    Example:

    .. code-block:: python

        GlobalOptions().use_tvm_ffi = True
    """

    _instance = None

    def __new__(cls):
        """Create a new singleton instance of the GlobalOptions class only once."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._options = {
                "use_tvm_ffi": cls._init_use_tvm_ffi(),
            }
        return cls._instance

    @property
    def use_tvm_ffi(self) -> bool:
        """Check if TVM FFI support is enabled.

        Default: ``True`` if ``tvm_ffi`` is installed.

        Can be overridden at process start by setting the
        ``CUTLASS_OPERATORS_USE_TVM_FFI`` environment variable to a boolean value
        (``1``/``0``, ``true``/``false``, ``yes``/``no``, ``on``/``off``).

        When enabled, conversions from DLPack compatible tensors to
        cute.Tensor is via TVM FFI. Additionally, invoking the compiled Operator
        happens via TVM FFI. Both can offer significant (3x-10x) speedups.

        Dependencies:

            * Required: ``tvm_ffi`` (pip install apache-tvm-ffi).
            * Optional: ``torch_c_dlpack_ext`` (pip install torch-c-dlpack-ext).
        """
        return self._options["use_tvm_ffi"]

    @use_tvm_ffi.setter
    def use_tvm_ffi(self, value: bool) -> None:
        if value and not find_spec("tvm_ffi"):
            raise ImportError(
                "Attempted to enable TVM FFI, but it is not installed. "
                "Please install it via `pip install apache-tvm-ffi`."
            )
        self._options["use_tvm_ffi"] = value

    def save(self) -> dict:
        """Save the current options to a dictionary."""
        return self._options.copy()

    def restore(self, inp: dict) -> None:
        """Restore previously saved options from a dictionary."""
        self._options = inp.copy()

    @staticmethod
    def _init_use_tvm_ffi() -> bool:
        """Resolve the initial value of ``use_tvm_ffi``.

        Resolution order:
          1. Environment variable ``CUTLASS_OPERATORS_USE_TVM_FFI`` (if set).
          2. Whether the ``tvm_ffi`` package is importable.

        If the environment variable explicitly enables TVM FFI but the package
        is not installed, raise ``ImportError`` so the user notices the
        misconfiguration rather than silently losing the requested speedup.

        Cross-check against ``CUTE_DSL_ENABLE_TVM_FFI`` variable: if
        both env vars are set and resolve to opposite booleans, raise
        ``ValueError`` to avoid confusing behavior.
        """
        api_env_value = _parse_bool_env(_ENV_USE_TVM_FFI)
        dsl_env_value = _parse_bool_env(_ENV_DSL_ENABLE_TVM_FFI)

        if (
            dsl_env_value != api_env_value
            and dsl_env_value is not None
            and api_env_value is not None
        ):
            raise ValueError(
                f"Conflicting environment variables: {_ENV_USE_TVM_FFI}={api_env_value!r} "
                f"({'enables' if api_env_value else 'disables'} TVM FFI) with "
                f"{_ENV_DSL_ENABLE_TVM_FFI}={dsl_env_value!r} "
                f"({'enables' if dsl_env_value else 'disables'} TVM FFI). "
                f"Set both to consistent values, or unset one to avoid confusing behavior."
            )

        has_tvm_ffi = find_spec("tvm_ffi") is not None

        match api_env_value:
            case True:
                if not has_tvm_ffi:
                    raise ImportError(
                        f"{_ENV_USE_TVM_FFI} is set to enable TVM FFI, but it "
                        "is not installed. Please install it via "
                        "`pip install apache-tvm-ffi`."
                    )
                return True
            case False:
                return False
            case None:
                if not has_tvm_ffi:
                    warnings.warn(
                        "TVM FFI is not installed, and will be disabled. The "
                        "host overhead for running kernels may be 3-10x higher "
                        "without it. It is strongly recommended to install it "
                        "via `pip install apache-tvm-ffi`. To silence this "
                        f"warning, set {_ENV_USE_TVM_FFI}=0.",
                        stacklevel=3,  # warn -> _init_use_tvm_ffi -> __new__ -> caller
                    )
                return has_tvm_ffi


# ---------------------------------------------------------------------------
# Implementation details
# ---------------------------------------------------------------------------


# Environment variable that overrides the default value of the
# ``use_tvm_ffi`` option at the time ``GlobalOptions`` is first instantiated.
_ENV_USE_TVM_FFI = "CUTLASS_OPERATORS_USE_TVM_FFI"

# CuTe DSL-side environment variable that controls TVM FFI in the runtime
# (e.g. ``cute.runtime.from_dlpack``). We don't own this variable but we read
# it for cross-validation against ``_ENV_USE_TVM_FFI``.
_ENV_DSL_ENABLE_TVM_FFI = "CUTE_DSL_ENABLE_TVM_FFI"

_TRUE_VALUES = frozenset({"1", "true", "yes", "on"})
_FALSE_VALUES = frozenset({"0", "false", "no", "off"})


def _parse_bool_env(name: str) -> bool | None:
    """Parse a boolean-valued environment variable.

    Returns:
        ``True``  if set to ``1``/``true``/``yes``/``on``  (case-insensitive).
        ``False`` if set to ``0``/``false``/``no``/``off`` (case-insensitive).
        ``None``  if the variable is not set.

    Raises:
        ValueError: If the variable is set but the value is unrecognized.
            We fail-fast rather than silently picking a default so that typos
            (e.g. ``USE_TVM_FFI=ture``) cannot quietly degrade performance.
    """
    raw = os.environ.get(name)
    if raw is None:
        return None
    normalized = raw.strip().lower()
    if normalized in _TRUE_VALUES:
        return True
    if normalized in _FALSE_VALUES:
        return False
    raise ValueError(
        f"Invalid value for environment variable {name}={raw!r}. "
        f"Expected a boolean: one of "
        f"{sorted(_TRUE_VALUES) + sorted(_FALSE_VALUES)} (case-insensitive)."
    )
