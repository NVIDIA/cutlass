# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import warnings

from cutlass.base_dsl.dsl import BaseDSL


def test_print_warning_once_caches_each_distinct_message():
    BaseDSL.print_warning_once.cache_clear()
    try:
        with warnings.catch_warnings(record=True) as caught:
            warnings.simplefilter("always")
            BaseDSL.print_warning_once(None, "first warning")
            BaseDSL.print_warning_once(None, "second warning")
            BaseDSL.print_warning_once(None, "first warning")

        assert [str(item.message) for item in caught] == [
            "first warning",
            "second warning",
        ]
    finally:
        BaseDSL.print_warning_once.cache_clear()
