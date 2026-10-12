# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class PipelineEmpty:
    """A no-op pipeline with no barriers -- a drop-in replacement for a
    real pipeline when, under a compile-time condition, no pipeline is needed.

    This is not an abstract base class. Every method below is an
    intentional no-op, so a caller can invoke the normal pipeline API and have
    each call compile away. It lets one kernel be reused across configs that do
    and don't need a pipeline -- e.g.
    ``pipeline = RealPipeline(...) if const_expr(is_dynamic) else PipelineEmpty()``
    (the CLC scheduler needs a CLC pipeline; the static scheduler does not). The
    ``get_barrier`` methods are omitted on purpose so as to not fail silently if this
    pipeline class is incorrectly selected.
    """

    @staticmethod
    def create(*args: Any, **kwargs: Any) -> "PipelineEmpty":
        return PipelineEmpty()

    def producer_acquire(self, *args: Any, **kwargs: Any) -> None:
        pass

    def producer_try_acquire(self, *args: Any, **kwargs: Any) -> None:
        pass

    def producer_commit(self, *args: Any, **kwargs: Any) -> None:
        pass

    def consumer_wait(self, *args: Any, **kwargs: Any) -> None:
        pass

    def consumer_try_wait(self, *args: Any, **kwargs: Any) -> None:
        pass

    def consumer_release(self, *args: Any, **kwargs: Any) -> None:
        pass

    # get_barrier methods are not implemented on purpose
