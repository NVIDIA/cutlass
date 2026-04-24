# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause


def pytest_configure(config):
    config.default_SMs[__file__] = "120a"
