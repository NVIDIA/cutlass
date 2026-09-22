# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

import cutlass
import cutlass.cute as cute
import pytest
from cutlass.base_dsl.common import DSLRuntimeError
from cutlass.base_dsl.dsl import BaseDSL


@cute.jit
def _add(a: cutlass.Int32, b: cutlass.Int32):
    return a + b


_offset = 1


@cute.jit
def _add_offset(value: cutlass.Int32):
    return value + _offset


def _clear_cache():
    BaseDSL._lazy_initialize_dsl(_add)
    BaseDSL._lazy_initialize_dsl(_add_offset)
    _add._dsl_object.jit_cache.clear()
    _add_offset._dsl_object.jit_cache.clear()


def test_compile_bypasses_cache_by_default(tmp_path, monkeypatch):
    monkeypatch.setenv("CUTE_DSL_CACHE_DIR", str(tmp_path))
    _clear_cache()

    first = cute.compile(_add, 1, 2)
    second = cute.compile(_add, 1, 2)

    assert first is not second
    assert not list(tmp_path.glob("*.mlir"))


def test_compile_can_reuse_in_memory_cache(tmp_path, monkeypatch):
    monkeypatch.setenv("CUTE_DSL_CACHE_DIR", str(tmp_path))
    _clear_cache()

    first = cute.compile(_add, 1, 2, use_cache=True)
    second = cute.compile(_add, 1, 2, use_cache=True)

    assert first is second
    assert len(list(tmp_path.glob("*.mlir"))) == 1


def test_compile_rejects_non_boolean_use_cache():
    with pytest.raises(DSLRuntimeError, match="`use_cache` must be a bool"):
        cute.compile(_add, 1, 2, use_cache=1)


def test_compile_cache_respects_global_no_cache(tmp_path, monkeypatch):
    monkeypatch.setenv("CUTE_DSL_CACHE_DIR", str(tmp_path))
    _clear_cache()
    monkeypatch.setattr(_add._dsl_object.envar, "no_cache", True)

    cute.compile(_add, 1, 2, use_cache=True)

    assert not list(tmp_path.glob("*.mlir"))


def test_compile_can_reuse_file_cache(tmp_path, monkeypatch):
    monkeypatch.setenv("CUTE_DSL_CACHE_DIR", str(tmp_path))
    _clear_cache()
    cute.compile(_add, 1, 2, use_cache=True)
    _clear_cache()

    def unexpected_backend_compile(*args, **kwargs):
        raise AssertionError("file cache hit unexpectedly ran backend compilation")

    monkeypatch.setattr(
        _add._dsl_object, "_compile_or_jit_module", unexpected_backend_compile
    )

    assert callable(cute.compile(_add, 1, 2, use_cache=True))


def test_compile_cache_invalidates_captured_value_change(tmp_path, monkeypatch):
    monkeypatch.setenv("CUTE_DSL_CACHE_DIR", str(tmp_path))
    _clear_cache()
    monkeypatch.setitem(globals(), "_offset", 1)
    first = cute.compile(_add_offset, 2, use_cache=True)
    monkeypatch.setitem(globals(), "_offset", 2)
    second = cute.compile(_add_offset, 2, use_cache=True)

    assert first is not second
    assert len(list(tmp_path.glob("*.mlir"))) == 2
