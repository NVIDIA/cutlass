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

"""Validation for block-scaled GEMM scale-factor buffers."""

from __future__ import annotations

from typing import TYPE_CHECKING

from cutlass.operators.arguments import ScaledOperand
from cutlass.operators.status import Status

if TYPE_CHECKING:
    from cutlass.operators.arguments import GemmArguments


def validate_blockscaled_factors(args: GemmArguments) -> Status:
    """Validate flat scale buffers consumed by block-scaled GEMM kernels."""
    m, n = args.out.shape[-2:]
    k = args.A.shape[-1]
    batch = args.A.shape[0] if len(args.A.shape) == 3 else 1
    for name, operand, outer in (("A", args.A, m), ("B", args.B, n)):
        scale = operand.scale
        expected = ScaledOperand.numel_scale(
            (batch, outer, k), operand.mode, operand.swizzle
        )
        if scale.numel() != expected:
            return Status.fail(
                f"Scale factor {name} for tensor {name} of shape {operand.shape} must have "
                f"{expected} elements. Scale factor {name} is of shape {scale.shape} "
                f"and has {scale.numel()} elements."
            )
        # The kernel uses the base pointer as a flat array, ignoring strides.
        # Singleton dimensions may have arbitrary strides without affecting the data.
        expected_stride = 1
        for size, stride in zip(reversed(scale.shape), reversed(scale.stride)):
            if size > 1 and stride != expected_stride:
                return Status.fail(f"Scale factor {name} must be contiguous.")
            expected_stride *= size
    return Status.success()
