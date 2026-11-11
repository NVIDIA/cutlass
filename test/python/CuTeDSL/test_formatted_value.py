# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import pytest

from cutlass.base_dsl import ast_helpers


def test_dynamic_formatted_value_rejects_width_without_conversion(monkeypatch):
    monkeypatch.setattr(ast_helpers.executor, "_is_dynamic_expression", lambda value: True)
    value = object()

    with pytest.raises(ast_helpers.DSLUserCodeError):
        ast_helpers.FormattedValue(
            value=value,
            conversion=-1,
            format_spec=["8"],
        ).to_str()

    assert ast_helpers.FormattedValue(
        value=value,
        conversion=-1,
        format_spec=[".2f"],
    ).to_str() == ("%.2f", value)
