#################################################################################################
#
# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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
#
#################################################################################################

import cutlass
import cutlass.cute as cute


"""
Example of using fake tensors in CuTe.

This script demonstrates how to use fake tensors in CuTe to drive compilation without creating actual tensors
from frameworks like PyTorch or TensorFlow.

Run this file directly to see the output type information.
"""


@cute.jit
def print_tensor_type(t: cute.Tensor):
    print(t)


def run():
    from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_tensor

    shape = (3, 4)
    a = make_fake_compact_tensor(cutlass.Float16, (3, 4), stride_order=(1, 0))
    cute.compile(print_tensor_type, a, options="--enable-tvm-ffi")

    # 32-bit symbolic integer with divisibility 8
    shape = (3, cute.sym_int32(divisibility=8))
    a = make_fake_compact_tensor(cutlass.Float16, shape, stride_order=(1, 0))
    cute.compile(print_tensor_type, a, options="--enable-tvm-ffi")

    # with static stride
    a = make_fake_tensor(cutlass.Float16, shape, stride=(4, 1))
    cute.compile(print_tensor_type, a, options="--enable-tvm-ffi")

    # with dynamic stride using 32bit integer
    stride = (cute.sym_int32(divisibility=8), 1)
    a = make_fake_tensor(cutlass.Float16, shape, stride=stride)
    cute.compile(print_tensor_type, a, options="--enable-tvm-ffi")

    # with dynamic stride using 64bit integer
    stride = (cute.sym_int64(divisibility=8), 1)
    a = make_fake_tensor(cutlass.Float16, shape, stride=stride)
    cute.compile(print_tensor_type, a, options="--enable-tvm-ffi")


if __name__ == "__main__":
    run()
