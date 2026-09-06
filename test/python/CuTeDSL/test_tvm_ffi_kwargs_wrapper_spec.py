# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import inspect
from cutlass.base_dsl.jit_executor import ExecutionArgs, KwargsWrapperSpec


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
