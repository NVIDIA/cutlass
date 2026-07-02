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

"""Unit tests for ``cutlass.operators.config.GlobalOptions``.

Covers environment-variable based initialization, programmatic overrides via
the property setters, and graceful behavior when the optional ``tvm_ffi``
dependency is missing.
"""

from importlib.util import find_spec

import pytest

import cutlass.operators as ops
from cutlass.operators import config
from cutlass.operators.config import _ENV_USE_TVM_FFI, _parse_bool_env


@pytest.fixture
def reset_singleton(monkeypatch):
    """Reset the ``GlobalOptions`` singleton so ``__new__`` re-runs init logic.

    ``monkeypatch.setattr`` restores ``_instance`` after the test, so other
    tests keep observing the original singleton (preserving the ``save`` /
    ``restore`` autouse fixture in ``conftest.py``).
    """
    monkeypatch.setattr(ops.GlobalOptions, "_instance", None)
    monkeypatch.delenv(_ENV_USE_TVM_FFI, raising=False)


# ---------------------------------------------------------------------------
# _parse_bool_env
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "raw, expected",
    [
        ("1", True),
        ("true", True),
        ("True", True),
        ("TRUE", True),
        ("yes", True),
        ("YES", True),
        ("on", True),
        ("  on  ", True),
        ("0", False),
        ("false", False),
        ("False", False),
        ("FALSE", False),
        ("no", False),
        ("NO", False),
        ("off", False),
    ],
)
def test_parse_bool_env_recognized_values(monkeypatch, raw, expected):
    monkeypatch.setenv("CUTLASS_OPERATORS_TEST_FLAG", raw)
    assert _parse_bool_env("CUTLASS_OPERATORS_TEST_FLAG") is expected


def test_parse_bool_env_unset_returns_none(monkeypatch):
    monkeypatch.delenv("CUTLASS_OPERATORS_TEST_FLAG", raising=False)
    assert _parse_bool_env("CUTLASS_OPERATORS_TEST_FLAG") is None


@pytest.mark.parametrize("raw", ["maybe", "ture", "2", "", "yes please"])
def test_parse_bool_env_rejects_unrecognized_values(monkeypatch, raw):
    """Typos must fail loudly so they don't silently pick a default."""
    monkeypatch.setenv("CUTLASS_OPERATORS_TEST_FLAG", raw)
    with pytest.raises(ValueError, match="Invalid value"):
        _parse_bool_env("CUTLASS_OPERATORS_TEST_FLAG")


# ---------------------------------------------------------------------------
# GlobalOptions environment-variable initialization
# ---------------------------------------------------------------------------


def test_env_var_disable_is_respected(monkeypatch, reset_singleton):
    """Setting the env var to a falsy value disables ``use_tvm_ffi`` even if
    ``tvm_ffi`` is installed."""
    monkeypatch.setenv(_ENV_USE_TVM_FFI, "0")
    assert ops.GlobalOptions().use_tvm_ffi is False


@pytest.mark.skipif(
    find_spec("tvm_ffi") is None, reason="apache-tvm-ffi is not installed"
)
def test_env_var_enable_is_respected(monkeypatch, reset_singleton):
    monkeypatch.setenv(_ENV_USE_TVM_FFI, "1")
    assert ops.GlobalOptions().use_tvm_ffi is True


def test_env_var_invalid_value_raises(monkeypatch, reset_singleton):
    monkeypatch.setenv(_ENV_USE_TVM_FFI, "maybe")
    with pytest.raises(ValueError, match="Invalid value"):
        ops.GlobalOptions()


def test_env_var_enable_without_tvm_ffi_raises(monkeypatch, reset_singleton):
    """If the user explicitly opts in via env var but ``tvm_ffi`` is missing,
    fail fast so the misconfiguration is visible."""
    monkeypatch.setattr(config, "find_spec", lambda name: None)
    monkeypatch.setenv(_ENV_USE_TVM_FFI, "1")
    with pytest.raises(ImportError, match=_ENV_USE_TVM_FFI):
        ops.GlobalOptions()


def test_env_var_disable_without_tvm_ffi_does_not_warn(
    monkeypatch, reset_singleton, recwarn
):
    """If the user explicitly opts out via env var, do not warn about the
    missing optional dependency: they made a deliberate choice."""
    monkeypatch.setattr(config, "find_spec", lambda name: None)
    monkeypatch.setenv(_ENV_USE_TVM_FFI, "0")
    assert ops.GlobalOptions().use_tvm_ffi is False
    tvm_warnings = [w for w in recwarn.list if "TVM FFI" in str(w.message)]
    assert tvm_warnings == [], (
        "Expected no TVM FFI warning when user explicitly disables via env var, "
        f"got: {[str(w.message) for w in tvm_warnings]}"
    )


# ---------------------------------------------------------------------------
# GlobalOptions default behavior (env var unset)
# ---------------------------------------------------------------------------


def test_default_warns_when_tvm_ffi_missing(monkeypatch, reset_singleton):
    """Without env var, a missing ``tvm_ffi`` is reported via UserWarning so
    users notice the performance hit but the API still functions."""
    monkeypatch.setattr(config, "find_spec", lambda name: None)
    with pytest.warns(UserWarning, match="TVM FFI is not installed"):
        opts = ops.GlobalOptions()
    assert opts.use_tvm_ffi is False


@pytest.mark.skipif(
    find_spec("tvm_ffi") is None, reason="apache-tvm-ffi is not installed"
)
def test_default_enabled_when_tvm_ffi_present(reset_singleton):
    assert ops.GlobalOptions().use_tvm_ffi is True


# ---------------------------------------------------------------------------
# Setter overrides env var
# ---------------------------------------------------------------------------


def test_setter_overrides_env_var(monkeypatch, reset_singleton):
    """Programmatic assignment should win over the env var seed value."""
    monkeypatch.setenv(_ENV_USE_TVM_FFI, "0")
    opts = ops.GlobalOptions()
    assert opts.use_tvm_ffi is False
    if find_spec("tvm_ffi") is not None:
        opts.use_tvm_ffi = True
        assert opts.use_tvm_ffi is True
