# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""Provider import failures must not retain their importers via tracebacks."""

import os
import subprocess
import sys
from pathlib import Path

import pytest

_PROBE = r"""
import gc
import importlib.abc
import sys
import weakref

import cutlass
cutlass.__path__.insert(0, sys.argv[1])
kind = sys.argv[2]

class RejectProvider(importlib.abc.MetaPathFinder):
    def find_spec(self, fullname, path=None, target=None):
        if fullname != "cutlass.operators.providers.cutedsl":
            return None
        try:
            raise ValueError("inner provider diagnostic")
        except ValueError:
            if kind == "missing":
                raise ModuleNotFoundError("missing dependency", name="missing_dependency")
            raise ImportError("broken provider")

sys.meta_path.insert(0, RejectProvider())

class Payload:
    pass

def caller():
    payload = Payload()
    ref = weakref.ref(payload)
    try:
        import cutlass.operators
    except ImportError as err:
        if kind == "missing":
            assert "is unavailable" in str(err)
            assert isinstance(err.__cause__, ModuleNotFoundError)
            assert err.__cause__.name == "missing_dependency"
        else:
            assert "failed to import" in str(err)
            assert type(err.__cause__) is ImportError
    else:
        raise AssertionError("provider failure was not propagated")
    return ref

ref = caller()
gc.collect()
providers = sys.modules["cutlass.operators.providers"]
stored = providers._import_errors["CuTeDSLProvider"]
assert stored.__traceback__ is None
assert stored.__context__.__traceback__ is None
if hasattr(stored, "__notes__"):
    assert "inner provider diagnostic" in "\n".join(stored.__notes__)
else:
    assert "inner provider diagnostic" in stored._provider_traceback_text
assert ref() is None
for _ in range(2):
    try:
        providers.CuTeDSLProvider
    except ImportError as err:
        assert err.__cause__ is stored
    else:
        raise AssertionError("missing provider unexpectedly succeeded")
assert stored.__traceback__ is None
try:
    providers.unknown_provider
except AttributeError:
    pass
else:
    raise AssertionError("unknown provider must raise AttributeError")
"""


@pytest.mark.parametrize("kind", ["missing", "broken"])
def test_provider_failure_does_not_retain_importer(kind):
    operator_package = Path(__file__).resolve().parents[2] / "cutlass"
    env = os.environ.copy()
    proc = subprocess.run(
        [sys.executable, "-c", _PROBE, str(operator_package), kind],
        env=env,
        text=True,
        capture_output=True,
        timeout=90,
    )
    assert proc.returncode == 0, proc.stdout + proc.stderr


def test_detach_clears_both_exception_links_and_group_members():
    import builtins
    import gc
    import weakref

    from cutlass.operators.providers import _detach_import_tracebacks

    class Payload:
        pass

    def make_error(message):
        payload = Payload()
        ref = weakref.ref(payload)
        try:
            raise ValueError(message)
        except ValueError as error:
            return error, ref

    cause, cause_ref = make_error("explicit cause")
    context, context_ref = make_error("implicit context")
    root = ImportError("provider failure")
    root.__cause__ = cause
    group_class = getattr(builtins, "ExceptionGroup", None)
    root.__context__ = (
        group_class("hidden context", [context]) if group_class else context
    )
    result = _detach_import_tracebacks(root)
    gc.collect()
    assert result is root
    assert root.__cause__ is cause
    assert cause.__traceback__ is None
    assert context.__traceback__ is None
    assert cause_ref() is None
    assert context_ref() is None


def test_provider_diagnostic_without_exception_notes(monkeypatch):
    from cutlass.operators import providers

    class LegacyImportError(ImportError):
        def __getattribute__(self, name):
            if name == "add_note":
                raise AttributeError(name)
            return super().__getattribute__(name)

    try:
        raise LegacyImportError("legacy diagnostic")
    except LegacyImportError as exc:
        stored = providers._detach_import_tracebacks(exc)
    monkeypatch.setitem(providers._import_errors, "CuTeDSLProvider", stored)
    with pytest.raises(ImportError, match="legacy diagnostic") as caught:
        providers.__getattr__("CuTeDSLProvider")
    assert caught.value.__cause__ is stored
    assert stored.__traceback__ is None
