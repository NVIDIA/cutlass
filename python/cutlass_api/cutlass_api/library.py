# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

import enum
from enum import auto as enum_auto
from typing import Self


class ScaleMode(enum.Enum):
    """
    Type of scaling used for scaled operations. Each scaling enum corresponds to
    a tuple indicating the units the scale covers in the (L, M, K) modes.

    For example, Blockwise1x16 corresponds to (1, 1, 16), meaning the scale operates
    over 16 elements in the K mode.
    """

    Blockwise1x16 = (1, 1, 16)
    Blockwise1x32 = (1, 1, 32)

    @staticmethod
    def compare(mode1: Self | tuple[int, ...], mode2: Self | tuple[int, ...]) -> bool:
        if isinstance(mode1, ScaleMode) and isinstance(mode2, ScaleMode):
            return mode1.value == mode2.value

        # One of the two modes is a tuple. Use tuple comparison and allow
        # for different lengths as long as long as the longer tuple contains
        # only 1s for the extra leading positions (i.e., allow (1,1,16) == (1, 16))
        tuple1 = mode1 if isinstance(mode1, tuple) else mode1.value
        tuple2 = mode2 if isinstance(mode2, tuple) else mode2.value

        if len(tuple1) == len(tuple2):
            return tuple1 == tuple2
        elif len(tuple1) < len(tuple2):
            padding = (1,) * (len(tuple2) - len(tuple1))
            return padding + tuple1 == tuple2
        else:
            padding = (1,) * (len(tuple1) - len(tuple2))
            return padding + tuple2 == tuple1

    def __eq__(self, other: Self | tuple[int, ...]) -> bool:
        return ScaleMode.compare(self, other)

    def __ne__(self, other: Self | tuple[int, ...]) -> bool:
        return not ScaleMode.compare(self, other)

    def __getitem__(self, index: int) -> int:
        return self.value[index]

    def __len__(self) -> int:
        return len(self.value)


class ScaleSwizzleMode(enum.Enum):
    """Swizzle mode used for scale factors"""
    SwizzleNone = enum_auto()
    Swizzle32x4x4 = enum_auto()
