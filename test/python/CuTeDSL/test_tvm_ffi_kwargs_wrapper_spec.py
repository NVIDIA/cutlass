# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import inspect
import pytest

import cutlass.cute as cute
from cutlass import Int32
from cutlass.base_dsl.jit_executor import ExecutionArgs
from cutlass.cutlass_dsl.tvm_ffi_provider import (
    TVMFFIJitCompiledFunction,
    TVMFFIJitCompiledFunctionWithKwargs,
)


pytest.importorskip("tvm_ffi")


@cute.jit
def _positional_only(a: Int32, b: Int32, /):
    pass


@cute.jit
def _positional_or_keyword(a: Int32, b: Int32):
    pass


@cute.jit
def _positional_default(a: Int32, b: Int32 = Int32(2), /):
    pass


@cute.jit
def _keyword_only(a: Int32, /, *, k: Int32 = Int32(2)):
    pass


def _compile(func, *args):
    return cute.compile(func, *args, options="--enable-tvm-ffi")


def test_tvm_ffi_routes_positional_only_signature_to_native_function():
    compiled = _compile(_positional_only, Int32(1), Int32(2))

    assert isinstance(compiled, TVMFFIJitCompiledFunction)
    compiled(1, 2)


def test_tvm_ffi_routes_positional_or_keyword_signature_to_kwargs_wrapper():
    compiled = _compile(_positional_or_keyword, Int32(1), Int32(2))

    assert isinstance(compiled, TVMFFIJitCompiledFunctionWithKwargs)
    compiled(a=1, b=2)


def test_tvm_ffi_routes_positional_default_signature_to_kwargs_wrapper():
    compiled = _compile(_positional_default, Int32(1))

    assert isinstance(compiled, TVMFFIJitCompiledFunctionWithKwargs)
    compiled(1)


def test_tvm_ffi_routes_keyword_only_signature_to_kwargs_wrapper():
    compiled = _compile(_keyword_only, Int32(1))

    assert isinstance(compiled, TVMFFIJitCompiledFunctionWithKwargs)
    compiled(1, k=2)


def test_kwargs_wrapper_spec_positional_only():
    def func_posonly(a, b, c, /):
        pass

    sig = inspect.signature(func_posonly)
    exec_args = ExecutionArgs(sig, "func_posonly")
    spec = exec_args.get_kwargs_wrapper_spec()

    assert spec.arg_names == ["a", "b", "c"]
    assert spec.arg_defaults == ()
    assert spec.kwonly_names == []
    assert spec.kwonly_defaults == {}
    assert spec.has_pos_or_kw is False


def test_kwargs_wrapper_spec_positional_or_keyword():
    def func_pos_or_kw(a, b, c):
        pass

    sig = inspect.signature(func_pos_or_kw)
    exec_args = ExecutionArgs(sig, "func_pos_or_kw")
    spec = exec_args.get_kwargs_wrapper_spec()

    assert spec.arg_names == ["a", "b", "c"]
    assert spec.has_pos_or_kw is True


def test_kwargs_wrapper_spec_mixed_posonly_and_pos_or_kw():
    def func_mixed(a, /, b):
        pass

    sig = inspect.signature(func_mixed)
    exec_args = ExecutionArgs(sig, "func_mixed")
    spec = exec_args.get_kwargs_wrapper_spec()

    assert spec.arg_names == ["a", "b"]
    assert spec.has_pos_or_kw is True
