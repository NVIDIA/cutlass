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

"""Framework-agnostic argument validation for GEMM kernel integration."""

from __future__ import annotations

from typing import TYPE_CHECKING

from cutlass.operators.status import Status

if TYPE_CHECKING:
    from cutlass.operators.arguments import RuntimeArguments


def strip_batch_mode(dims: tuple[int, ...]) -> tuple[int, int]:
    """Strips the batch mode from the dimensions.

    :throws: ValueError if the dimensions are not [L, M, K] or [M, K].
    """
    if len(dims) == 3:
        return (dims[1], dims[2])
    elif len(dims) == 2:
        return (dims[0], dims[1])
    else:
        raise ValueError(f"Invalid dimensions: {dims}")


def tensor_rank_2_or_3(args: RuntimeArguments) -> Status:
    """Checks that the arguments are valid for a tensor of rank 2 or 3."""
    if len(args.A.shape) < 2 or len(args.A.shape) > 3:
        return Status.fail(
            f"A must be a tensor of rank 2 or 3 (L=1, M, K), got {args.A.shape}"
        )
    if len(args.B.shape) < 2 or len(args.B.shape) > 3:
        return Status.fail(
            f"B must be a tensor of rank 2 or 3 (L=1, K, N), got {len(args.B.shape)}"
        )
    if len(args.out.shape) < 2 or len(args.out.shape) > 3:
        return Status.fail(
            f"out must be a tensor of rank 2 or 3 (L=1, M, N), got {len(args.out.shape)}"
        )
    return Status.success()


def tensor_reduction_mode_matches(args: RuntimeArguments) -> Status:
    """Checks that A's K dimension matches B's K dimension."""
    if args.A.shape[-1] != args.B.shape[-2]:
        return Status.fail(
            f"A's K dimension ({args.A.shape[-1]}) must be equal to B's "
            f"K dimension ({args.B.shape[-2]}). "
            f"A shape (L, M, K): {args.A.shape}, B shape (L, K, N): {args.B.shape}"
        )
    return Status.success()


def tensor_output_shape_matches(args: RuntimeArguments) -> Status:
    """Checks that the output tensor's M and N dimensions match A and B respectively."""
    if args.out.shape[-2] != args.A.shape[-2]:
        return Status.fail(
            f"out's M dimension ({args.out.shape[-2]}) must be equal to A's "
            f"M dimension ({args.A.shape[-2]}). "
            f"A shape (L, M, K): {args.A.shape}, out shape (L, M, N): {args.out.shape}"
        )
    if args.out.shape[-1] != args.B.shape[-1]:
        return Status.fail(
            f"out's N dimension ({args.out.shape[-1]}) must be equal to B's "
            f"N dimension ({args.B.shape[-1]}). "
            f"B shape (L, K, N): {args.B.shape}, out shape (L, M, N): {args.out.shape}"
        )
    return Status.success()
