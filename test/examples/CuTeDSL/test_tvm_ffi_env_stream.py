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

import cuda.bindings.driver as cuda
import torch

import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack, make_fake_stream


N = 128


@cute.kernel
def _add_one_kernel(src: cute.Tensor, dst: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    dst[tidx] = src[tidx] + 1.0


@cute.jit
def _add_one_nested(tensors: tuple, stream: cuda.CUstream):
    src, dst = tensors
    _add_one_kernel(src, dst).launch(
        grid=[1, 1, 1], block=[N, 1, 1], stream=stream
    )


def test_env_stream_detected_from_nested_tuple():
    src_torch = torch.arange(N, dtype=torch.float32, device="cuda")
    dst_torch = torch.zeros(N, dtype=torch.float32, device="cuda")
    src = from_dlpack(
        src_torch, assumed_align=16, enable_tvm_ffi=True
    ).mark_layout_dynamic()
    dst = from_dlpack(
        dst_torch, assumed_align=16, enable_tvm_ffi=True
    ).mark_layout_dynamic()
    env_stream = make_fake_stream(use_tvm_ffi_env_stream=True)

    compiled = cute.compile(
        _add_one_nested,
        (src, dst),
        env_stream,
        options="--enable-tvm-ffi",
    )

    torch.cuda.synchronize()
    stream = torch.cuda.Stream()
    with torch.cuda.stream(stream):
        compiled((src_torch, dst_torch))
    stream.synchronize()

    assert torch.equal(dst_torch, src_torch + 1)
