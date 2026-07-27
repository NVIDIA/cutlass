# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""Utilities for CUTLASS Operator API."""

from __future__ import annotations

import importlib
import logging

_logger = logging.getLogger(__name__)


def ceil_div(a: int, b: int) -> int:
    """Compute the ceiling division of a by b.

    :param a: The dividend.
    :type a: int
    :param b: The divisor.
    :type b: int

    :return: The ceiling division of a by b.
    :rtype: int
    """
    return (a + b - 1) // b


def round_up(a: int, b: int) -> int:
    """Round a up to the nearest multiple of b.

    :param a: The value to round up.
    :type a: int
    :param b: The multiple to round up to.
    :type b: int

    :return: The value of a rounded up to the nearest multiple of b.
    :rtype: int
    """
    return ((a + b - 1) // b) * b


def is_numpy_available() -> bool:
    """Check if numpy is available."""
    return importlib.util.find_spec("numpy") is not None


def is_torch_available() -> bool:
    """Check if torch is available."""
    return importlib.util.find_spec("torch") is not None


def is_jax_available() -> bool:
    """Check if jax is available."""
    return importlib.util.find_spec("jax") is not None


def tuple_to_string(tuple: tuple[int, ...]) -> str:
    """Convert a tuple of integers to an 'x'-separated string (e.g., (2, 3, 4) -> '2x3x4')."""
    return "x".join(str(x) for x in tuple) if len(tuple) > 1 else str(tuple[0])
