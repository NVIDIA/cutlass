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

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def _for_loop_carried_reused_target_kernel(out: cute.Tensor, n: cutlass.Int32):
    acc = cutlass.Int32(0)
    i = cutlass.Int32(-1)

    for i in cutlass.range(0, n):
        acc = cutlass.Int32(1)

    out[0] = acc
    out[1] = i


@cute.jit
def _for_loop_carried_reused_target_host(out: cute.Tensor, n: cutlass.Int32):
    _for_loop_carried_reused_target_kernel(out, n).launch(
        grid=[1, 1, 1],
        block=[1, 1, 1],
    )


def test_for_loop_carried_var_with_reused_loop_target():
    n = 5
    out = torch.zeros(2, device="cuda", dtype=torch.int32)
    out_cute = from_dlpack(out).mark_layout_dynamic()
    n_cute = cutlass.Int32(n)

    compiled = cute.compile(_for_loop_carried_reused_target_host, out_cute, n_cute)
    compiled(out_cute, n_cute)
    torch.cuda.synchronize()

    actual = out.cpu().tolist()
    expected = [1, n - 1]
    print(f"for loop carried reused target actual={actual}, expected={expected}")
    assert actual == expected
