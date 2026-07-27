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

"""CuTe DSL-specific integration utilities for wiring operators into the cutlass.operators backend.

Functions here should depend on the CuTe DSL framework (cutlass.cute / cutlass.utils).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

import cutlass
import cutlass.cute as cute
from cutlass.cute import nvgpu

if TYPE_CHECKING:
    from cutlass.operators.arguments.gemm import GemmArguments
    from cutlass.operators.metadata.operands.gemm import GemmOperandsMetadata
    from cutlass.operators.utils.tensor import TensorWrapper


def make_ptr(
    tensor: TensorWrapper,
    nullptr: bool = False,
    address_space: cutlass.AddressSpace = cutlass.AddressSpace.gmem,
    assumed_align: int | None = 16,
) -> cute.Pointer:
    """Shim for cute.runtime.make_ptr that accepts a TensorWrapper.

    :param tensor: The tensor to create a pointer for
    :param nullptr: Use nullptr if True, otherwise use data_ptr from TensorWrapper
    :param address_space: The address space of the pointer
    :param assumed_align: Assumed alignment in bytes
    """

    def ptr(x):
        return 0 if nullptr else x.data_ptr

    return cute.runtime.make_ptr(
        tensor.dtype, ptr(tensor), address_space, assumed_align
    )


@dataclass(frozen=True)
class GemmMajorModes:
    A: nvgpu.OperandMajorMode
    B: nvgpu.OperandMajorMode
    out: nvgpu.OutputMajorMode


def gemm_major_modes(gemm: GemmArguments | GemmOperandsMetadata) -> GemmMajorModes:
    a_major_mode = (
        nvgpu.OperandMajorMode.K
        if gemm.A.stride[-2:].index(1) == 1
        else nvgpu.OperandMajorMode.MN
    )

    b_major_mode = (
        nvgpu.OperandMajorMode.K
        if gemm.B.stride[-2:].index(1) == 0
        else nvgpu.OperandMajorMode.MN
    )

    out_major_mode = (
        nvgpu.OutputMajorMode.N
        if gemm.out.stride[-2:].index(1) == 1
        else nvgpu.OutputMajorMode.M
    )

    return GemmMajorModes(A=a_major_mode, B=b_major_mode, out=out_major_mode)
