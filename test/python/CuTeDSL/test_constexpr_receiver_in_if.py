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

"""Regression coverage for a Constexpr method receiver in staged control flow."""

import unittest

import cutlass
import cutlass.cute as cute
from cutlass import Float32, Int32
from cutlass.cute.runtime import make_fake_tensor


class _ConstexprReceiver:
    """Plain Python meta object: deliberately not MLIR-decomposable."""

    def __init__(self, value: float) -> None:
        self.value = value

    @cute.jit
    def store(self, output: cute.Tensor) -> None:
        output[0] = Float32(self.value)


@cute.kernel
def _kernel_with_constexpr_receiver(
    receiver: cutlass.Constexpr[_ConstexprReceiver], output: cute.Tensor
):
    tidx, _, _ = cute.arch.thread_idx()
    if tidx == Int32(0):
        receiver.store(output)


@cute.jit
def _compile_constexpr_receiver(
    receiver: cutlass.Constexpr[_ConstexprReceiver], output: cute.Tensor
):
    _kernel_with_constexpr_receiver(receiver, output).launch(
        grid=(1, 1, 1), block=(32, 1, 1)
    )


class TestConstexprReceiverInIf(unittest.TestCase):
    def test_plain_python_receiver_is_not_lowered_as_if_result(self):
        output = make_fake_tensor(Float32, (1,), stride=(1,), assumed_align=4)
        cute.compile(_compile_constexpr_receiver, _ConstexprReceiver(3.0), output)


if __name__ == "__main__":
    unittest.main()
