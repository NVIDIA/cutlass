# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""Provider import failures must not retain their importers via tracebacks."""

import gc
import importlib.util
import sys
import types
import weakref

import pytest

import cutlass.operators as ops

_CUTEDSL_MODULE = "cutlass.operators.providers.cutedsl"


class _Payload:
    pass


def _import_fresh_providers():
    """Load a fresh providers module while an importer-local object is alive."""
    payload = _Payload()
    spec = importlib.util.spec_from_file_location(
        "_fresh_operator_providers", ops.providers.__file__
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module, weakref.ref(payload)


@pytest.mark.parametrize(
    "patched_module, expected_prefix, original_type",
    [
        (
            None,
            "CuTeDSLProvider is unavailable: install " + repr("nvidia-cutlass-dsl"),
            "ModuleNotFoundError",
        ),
        (
            types.ModuleType(_CUTEDSL_MODULE),
            "CuTeDSLProvider failed to import.",
            "ImportError",
        ),
    ],
    ids=["missing", "broken"],
)
def test_failed_provider_import_does_not_retain_importer(
    monkeypatch, patched_module, expected_prefix, original_type
):
    monkeypatch.setitem(sys.modules, _CUTEDSL_MODULE, patched_module)
    module, payload_ref = _import_fresh_providers()
    gc.collect()
    assert payload_ref() is None
    for _ in range(2):
        with pytest.raises(ImportError, match="Original error:") as excinfo:
            _ = module.CuTeDSLProvider
        assert str(excinfo.value).startswith(expected_prefix)
        assert original_type in str(excinfo.value)
        assert _CUTEDSL_MODULE in str(excinfo.value)
        assert excinfo.value.__cause__ is None


def test_missing_known_provider_and_unknown_attribute(monkeypatch):
    provider = types.ModuleType(_CUTEDSL_MODULE)
    provider.CuTeDSLProvider = type("FakeProvider", (), {})
    monkeypatch.setitem(sys.modules, _CUTEDSL_MODULE, provider)
    module, _ = _import_fresh_providers()
    del module.CuTeDSLProvider
    with pytest.raises(ImportError, match="CuTeDSLProvider is unavailable"):
        _ = module.CuTeDSLProvider
    with pytest.raises(AttributeError, match="unknown_provider"):
        _ = module.unknown_provider
