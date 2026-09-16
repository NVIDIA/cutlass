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
"""Task Scheduling (TS) public API.

The top-level package re-exports the captured-schedule helpers and work
decorators most kernels need directly:

``schedule``
    Decorator that traces a schedule function into a ``Schedule``.
``domain_loop`` and ``work_tile_loop``
    Context managers for the runtime domain loop and optional persistent
    work-tile loop.
``consumer_work`` and ``producer_work``
    Decorators for resource methods that read from or write into a resource.
``WorkAttr``
    Work callback attributes such as ``WorkAttr.AUXILIARY``.
"""

from .enums import (
    Every,
    IterationPredicate,
    OpaqueCondition,
    WorkAttr,
)
from . import pipeline
from .resources import consumer_work, producer_work
from .schedule_builder import (
    domain_loop,
    schedule,
    when_false,
    when_true,
    work_tile_loop,
)


__all__ = [
    "consumer_work",
    "domain_loop",
    "Every",
    "IterationPredicate",
    "OpaqueCondition",
    "pipeline",
    "producer_work",
    "schedule",
    "when_false",
    "when_true",
    "WorkAttr",
    "work_tile_loop",
]
