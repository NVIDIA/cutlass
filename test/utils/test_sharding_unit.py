# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from types import SimpleNamespace

import pytest

from test_sharding import DefaultSMs, mark_values, params_in_context


class _FakeMark:
    def __init__(self, name, args=(), kwargs=None):
        self.name = name
        self.args = args
        self.kwargs = kwargs or {}


def test_mark_values_reads_defaults_and_kwargs():
    get_values = mark_values(
        ("ratio", 1.0, lambda x: isinstance(x, float), None),
        ("enabled", True, lambda x: isinstance(x, bool), None),
    )

    mark = _FakeMark("L0", kwargs={"ratio": 0.5})
    ratio, enabled = get_values(mark)

    assert ratio == 0.5
    assert enabled is True


def test_mark_values_formats_and_validates_list_like_sms():
    get_values = mark_values(
        (
            "sms",
            None,
            lambda x: isinstance(x, (list, str, int)),
            lambda x: [str(x)] if not isinstance(x, list) else [str(sm) for sm in x],
        ),
    )

    mark = _FakeMark("arch", kwargs={"sms": [90, "100a"]})
    (sms,) = get_values(mark)

    assert sms == ["90", "100a"]


def test_mark_values_rejects_unknown_kwargs():
    get_values = mark_values(("ratio", 1.0, lambda x: True, None))
    mark = _FakeMark("L1", kwargs={"unknown": 7})

    with pytest.raises(AssertionError, match="unknown arguments"):
        get_values(mark)


def test_mark_values_rejects_invalid_value():
    get_values = mark_values(("ratio", 1.0, lambda x: 0 <= x <= 1.0, None))
    mark = _FakeMark("L2", kwargs={"ratio": 2.0})

    with pytest.raises(AssertionError, match="is invalid"):
        get_values(mark)


def test_params_in_context_with_named_params():
    def checker(m, n):
        return m < n

    checker_in_context = params_in_context(checker)

    assert checker_in_context({"m": 3, "n": 4, "k": 5}) is True
    assert checker_in_context({"m": 4, "n": 1, "k": 5}) is False


def test_params_in_context_eval_style_lambda():
    checker_in_context = params_in_context(lambda: m * n == k)

    assert checker_in_context({"m": 2, "n": 4, "k": 8}) is True
    assert checker_in_context({"m": 2, "n": 3, "k": 8}) is False


def test_default_sms_inherits_from_parent_directory(tmp_path):
    cfg = SimpleNamespace(rootdir=str(tmp_path))
    default_sms = DefaultSMs(cfg)

    parent_conftest = tmp_path / "test" / "examples" / "conftest.py"
    child_test = tmp_path / "test" / "examples" / "CuTeDSL" / "sample_test.py"

    default_sms[str(parent_conftest)] = [90, "100a"]

    assert default_sms[str(child_test)] == ["90", "100a"]


def test_default_sms_prefers_nearest_directory(tmp_path):
    cfg = SimpleNamespace(rootdir=str(tmp_path))
    default_sms = DefaultSMs(cfg)

    top_conftest = tmp_path / "test" / "conftest.py"
    child_conftest = tmp_path / "test" / "examples" / "conftest.py"
    child_test = tmp_path / "test" / "examples" / "x.py"

    default_sms[str(top_conftest)] = "80"
    default_sms[str(child_conftest)] = [90, 100]

    assert default_sms[str(child_test)] == ["90", "100"]
