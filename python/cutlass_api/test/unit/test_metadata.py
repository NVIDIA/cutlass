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

import pytest
import torch

import cutlass
from cutlass import cute

import cutlass_api
from cutlass_api.arguments import ElementwiseArguments
from cutlass_api.config import GlobalOptions
from cutlass_api.metadata import (
    ElementwiseOperandsMetadata,
    DenseTensorAttributes,
)


class NoopKernelForTesting(cutlass_api.providers.cutedsl.kernel.CuteDslKernel):
    @cute.jit
    def impl(self, A, B, out, stream):
        cute.printf("Called kernel from host successfully!")
        return

    def compile(self, args: ElementwiseArguments):
        stream = cute.runtime.make_fake_stream()
        return self.cute_compile(
            self.impl, args.A.tensor, args.B.tensor, args.out.tensor, stream
        )

    def _run(
        self,
        args: ElementwiseArguments,
        compiled_artifact,
        stream,
        workspace=None,
    ):
        self.cute_run(
            compiled_artifact, args.A.tensor, args.B.tensor, args.out.tensor, stream
        )

    def generate_kernels(_ignored_filter, _ignored_epilogue_args, _ignored_cc):
        attrs = DenseTensorAttributes(
            stride=(0, 1),
            dtype=cutlass.Float16,
            divisibility=8,
        )
        metadata = cutlass_api.KernelMetadata(
            kernel_name="NoopKernelForTesting",
            kernel_class=NoopKernelForTesting,
            min_cc=80,
            operands=ElementwiseOperandsMetadata(
                A=attrs,
                B=attrs,
                out=attrs,
            ),
        )
        return [NoopKernelForTesting(metadata)]


kernel = NoopKernelForTesting.generate_kernels(None, None, None)[0]


def test_perfectly_aligned():
    divisibility = kernel.metadata.operands.A.divisibility
    A, B, out = [
        torch.randn(divisibility, divisibility * 2, dtype=torch.float16, device="cuda")
        for _ in range(3)
    ]
    args = ElementwiseArguments(A=A, B=B, out=out)
    kernel.run(args)


def test_overaligned():
    A, B, out = [
        torch.randn(1024, 1024, dtype=torch.float16, device="cuda") for _ in range(3)
    ]
    args = ElementwiseArguments(A=A, B=B, out=out)
    kernel.run(args)


def _check_misaligned_args(use_tvm_ffi: bool, error_match_string: str, **tensors):
    """Helper to test various misalignment errors are properly caught.

    With TVM-FFI:
        args creation may succeed, but kernel.supports must fail.
        TVM-FFI should still catch errors if user bypasses supports.
    Without TVM-FFI:
        error must be caught early during argument creation itself.
    """
    GlobalOptions().use_tvm_ffi = use_tvm_ffi

    if use_tvm_ffi:
        args = ElementwiseArguments(**tensors)
        assert not kernel.supports(args), "Unsupported args should be rejected"

        with pytest.raises(Exception, match=error_match_string):
            kernel.run(args, assume_supported_args=True)
    else:
        with pytest.raises(Exception, match=error_match_string):
            ElementwiseArguments(**tensors)


@pytest.mark.parametrize("use_tvm_ffi", [True, False])
def test_underaligned(use_tvm_ffi: bool):
    divisibility = kernel.metadata.operands.A.divisibility
    A, B, out = [
        torch.randn(
            divisibility + divisibility // 2,
            divisibility + divisibility // 4,
            dtype=torch.float16,
            device="cuda",
        )
        for _ in range(3)
    ]
    _check_misaligned_args(use_tvm_ffi, "divisible", A=A, B=B, out=out)


@pytest.mark.parametrize("use_tvm_ffi", [True, False])
def test_ptr_misaligned(use_tvm_ffi: bool):
    rows = kernel.metadata.operands.A.divisibility * 4
    cols = rows
    offset = 117

    A = torch.randn(rows * cols + offset, dtype=torch.float16, device="cuda")
    B = torch.randn(rows, cols, dtype=torch.float16, device="cuda")
    out = torch.randn(rows, cols, dtype=torch.float16, device="cuda")
    A_offset = torch.as_strided(A[offset:], (rows, cols), (cols, 1))

    _check_misaligned_args(use_tvm_ffi, "align", A=A_offset, B=B, out=out)
