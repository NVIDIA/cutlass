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

import pytest
import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def _unary_ops_kernel(
    absf_inp: cute.Tensor, absf_out: cute.Tensor,
    floor_inp: cute.Tensor, floor_out: cute.Tensor,
):
    tidx, _, _ = cute.arch.thread_idx()
    absf_out[tidx] = cute.math.absf(absf_inp[tidx])
    floor_out[tidx] = cute.math.floor(floor_inp[tidx])


@cute.jit
def _unary_ops_host(
    absf_inp: cute.Tensor, absf_out: cute.Tensor,
    floor_inp: cute.Tensor, floor_out: cute.Tensor,
):
    _unary_ops_kernel(absf_inp, absf_out, floor_inp, floor_out).launch(
        grid=[1, 1, 1], block=[absf_inp.shape[0], 1, 1]
    )


def test_unary_ops():
    absf_inp = torch.tensor([-3.5, 2.0, 0.0], device="cuda", dtype=torch.float32)
    absf_expected = torch.tensor([3.5, 2.0, 0.0], device="cuda", dtype=torch.float32)
    absf_out = torch.zeros(3, device="cuda", dtype=torch.float32)
    floor_inp = torch.tensor([3.7, -2.3, 5.0], device="cuda", dtype=torch.float32)
    floor_expected = torch.tensor([3.0, -3.0, 5.0], device="cuda", dtype=torch.float32)
    floor_out = torch.zeros(3, device="cuda", dtype=torch.float32)
    absf_inp_cute = from_dlpack(absf_inp)
    absf_out_cute = from_dlpack(absf_out)
    floor_inp_cute = from_dlpack(floor_inp)
    floor_out_cute = from_dlpack(floor_out)

    args = (absf_inp_cute, absf_out_cute, floor_inp_cute, floor_out_cute)

    cute.compile(_unary_ops_host, *args)(*args)
    torch.cuda.synchronize()

    assert torch.equal(absf_out, absf_expected)
    assert torch.equal(floor_out, floor_expected)


@cute.kernel
def _binary_ops_kernel(
    mag_inp: cute.Tensor, sign_inp: cute.Tensor, out: cute.Tensor,
):
    tidx, _, _ = cute.arch.thread_idx()
    out[tidx] = cute.math.copysign(mag_inp[tidx], sign_inp[tidx])


@cute.jit
def _binary_ops_host(
    mag_inp: cute.Tensor, sign_inp: cute.Tensor, out: cute.Tensor,
):
    _binary_ops_kernel(mag_inp, sign_inp, out).launch(
        grid=[1, 1, 1], block=[mag_inp.shape[0], 1, 1]
    )


def test_binary_ops():
    mag_inp = torch.tensor([3.5, -2.0, 0.0, 1.0], device="cuda", dtype=torch.float32)
    sign_inp = torch.tensor([-1.0, 1.0, -1.0, 1.0], device="cuda", dtype=torch.float32)
    expected = torch.tensor([-3.5, 2.0, -0.0, 1.0], device="cuda", dtype=torch.float32)
    out = torch.zeros(4, device="cuda", dtype=torch.float32)
    mag_inp_cute = from_dlpack(mag_inp)
    sign_inp_cute = from_dlpack(sign_inp)
    out_cute = from_dlpack(out)

    args = (mag_inp_cute, sign_inp_cute, out_cute)

    cute.compile(_binary_ops_host, *args)(*args)
    torch.cuda.synchronize()

    assert torch.equal(out, expected)
