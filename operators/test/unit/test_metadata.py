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

from dataclasses import dataclass

import pytest
import torch

import cutlass
from cutlass import cute

import cutlass.operators as ops
from cutlass.operators.arguments.base import Operand
from cutlass.operators.arguments.operand import _operand_or_dense
from cutlass.operators.metadata import (
    DenseTensorConstraints,
    OperandConstraints,
    OperandsMetadata,
)
from cutlass.operators.providers.cutedsl.operator import CuteDslOperator
from cutlass.operators.status import Status
from cutlass.operators.typing import TensorLike


@dataclass
class DummyArguments(ops.RuntimeArguments):
    A: Operand
    B: Operand
    out: Operand

    def __init__(
        self,
        A: TensorLike | Operand,
        B: TensorLike | Operand,
        out: TensorLike | Operand,
    ):
        self.A = _operand_or_dense(A).copy()
        self.B = _operand_or_dense(B).copy()
        self.out = _operand_or_dense(out).copy()
        super().__init__()


@dataclass
class DummyOperandsMetadata(OperandsMetadata):
    A: OperandConstraints
    B: OperandConstraints
    out: OperandConstraints

    def supports(self, other: DummyArguments) -> Status:
        return all(
            [
                self.A.supports(other.A),
                self.B.supports(other.B),
                self.out.supports(other.out),
            ]
        )


class NoopOperatorForTesting(CuteDslOperator):
    supported_args_type = DummyArguments
    designed_for_min_cc = 80

    @cute.jit
    def impl(self, A, B, out, stream):
        cute.printf("Called kernel from host successfully!")
        return

    def _compile(self, args: DummyArguments, target_sm: ops.TargetSm | None = None):
        stream = cute.runtime.make_fake_stream()
        return self.cute_compile(
            self.impl,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            stream,
            target_sm=target_sm,
        )

    def _run(
        self,
        args: DummyArguments,
        compiled_artifact,
        stream,
        workspace=None,
    ):
        self.cute_run(
            compiled_artifact.compiled_obj,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            stream,
        )

    @classmethod
    def _generate_operators(cls, _filter, _epilogue_args, _target_sm, _args):
        attrs = DenseTensorConstraints(
            stride=(0, 1),
            dtype=cutlass.Float16,
            divisibility=8,
        )
        metadata = ops.OperatorMetadata(
            operator_name="NoopOperatorForTesting",
            operator_class=cls,
            supported_targets=[ops.TargetSm("80")],
            operands=DummyOperandsMetadata(
                A=attrs,
                B=attrs,
                out=attrs,
            ),
        )
        return [NoopOperatorForTesting(metadata)]


operator = NoopOperatorForTesting.generate_operators(metadata_filter=None)[0]


def test_perfectly_aligned():
    divisibility = operator.metadata.operands.A.divisibility
    A, B, out = [
        torch.randn(divisibility, divisibility * 2, dtype=torch.float16, device="cuda")
        for _ in range(3)
    ]
    args = DummyArguments(A=A, B=B, out=out)
    operator.run(args)


def test_overaligned():
    A, B, out = [
        torch.randn(1024, 1024, dtype=torch.float16, device="cuda") for _ in range(3)
    ]
    args = DummyArguments(A=A, B=B, out=out)
    operator.run(args)


def _check_misaligned_args(error_match_string: str, **tensors):
    """Helper to test various misalignment errors are properly caught.

    With TVM-FFI:
        args creation may succeed, but operator.supports must fail.
        TVM-FFI should still catch errors if user bypasses supports.
    Without TVM-FFI:
        error must be caught early during argument creation itself.
    """
    if ops.GlobalOptions().use_tvm_ffi:
        args = DummyArguments(**tensors)
        assert not operator.supports(args), "Unsupported args should be rejected"

        with pytest.raises(Exception, match=error_match_string):
            operator.run(args, assume_supported_args=True)
    else:
        with pytest.raises(Exception, match=error_match_string):
            DummyArguments(**tensors)


def test_underaligned(fixture_toggle_tvm_ffi):
    divisibility = operator.metadata.operands.A.divisibility
    A, B, out = [
        torch.randn(
            divisibility + divisibility // 2,
            divisibility + divisibility // 4,
            dtype=torch.float16,
            device="cuda",
        )
        for _ in range(3)
    ]
    _check_misaligned_args("divisible", A=A, B=B, out=out)


def test_ptr_misaligned(fixture_toggle_tvm_ffi):
    rows = operator.metadata.operands.A.divisibility * 4
    cols = rows
    offset = 117

    A = torch.randn(rows * cols + offset, dtype=torch.float16, device="cuda")
    B = torch.randn(rows, cols, dtype=torch.float16, device="cuda")
    out = torch.randn(rows, cols, dtype=torch.float16, device="cuda")
    A_offset = torch.as_strided(A[offset:], (rows, cols), (cols, 1))

    _check_misaligned_args("align", A=A_offset, B=B, out=out)
