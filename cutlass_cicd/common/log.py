# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import logging
import sys
from typing import Any, Callable, TypeVar


LOGGER_NAME = "cutlass_cicd"
LOG_CALL_SEPARATOR_WIDTH = 80
_ReturnT = TypeVar("_ReturnT")


def _create_logger() -> logging.Logger:
    logger = logging.getLogger(LOGGER_NAME)
    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(logging.Formatter("%(message)s"))
        logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    logger.propagate = False
    return logger


def _callable_reference(func_to_call: Callable[..., Any]) -> str:
    callable_type = type(func_to_call)
    module = getattr(func_to_call, "__module__", callable_type.__module__)
    qualname = getattr(func_to_call, "__qualname__", callable_type.__qualname__)
    return f"{module}.{qualname}" if module else qualname


def log_call(
    log_func: Callable[[str], Any],
    func_to_call: Callable[..., _ReturnT],
    *args: Any,
    **kwargs: Any,
) -> _ReturnT:
    """Log a callable's qualified reference, invoke it, and return its result."""

    reference = _callable_reference(func_to_call)
    separator = f" {reference} ".center(LOG_CALL_SEPARATOR_WIDTH, "=")
    log_func(f"\n{separator}\n")
    return func_to_call(*args, **kwargs)


G_LOGGER = _create_logger()
