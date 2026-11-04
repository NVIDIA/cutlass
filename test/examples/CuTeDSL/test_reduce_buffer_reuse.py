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

"""A shared reduction buffer can be reused by consecutive block reductions."""

import operator

import cuda.bindings.driver as cuda
import cutlass
import pytest
import torch
from blackwell.kernel.reduce.reduce import block_reduce
from cutlass import cute
from cutlass.cute.runtime import from_dlpack
from cutlass.memory import SmemAllocator


@cute.kernel
def _reduce_twice_kernel(out: cute.Tensor):
    tid, _, _ = cute.arch.thread_idx()
    warp = tid // 32
    smem = SmemAllocator()
    buf = smem.allocate_tensor(
        cutlass.Float32, cute.make_layout((2, 4)), byte_alignment=16
    )
    for i in range(8):
        a = block_reduce(
            cutlass.Float32(warp + 1), operator.add, buf, cutlass.Float32(0)
        )
        b = block_reduce(
            cutlass.Float32((warp + 1) * 10), operator.add, buf, cutlass.Float32(0)
        )
        out[tid, 2 * i] = a
        out[tid, 2 * i + 1] = b


@cute.jit
def _launch_reduce_twice(out: cute.Tensor, stream: cuda.CUstream):
    _reduce_twice_kernel(out).launch(grid=(1, 1, 1), block=(256, 1, 1), stream=stream)


@pytest.mark.skipif(not torch.cuda.is_available(), reason="requires a CUDA GPU")
def test_block_reduce_reuses_buffer():
    out = torch.empty((256, 16), device="cuda", dtype=torch.float32)
    t_out = from_dlpack(out, assumed_align=16).mark_layout_dynamic()
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled = cute.compile(_launch_reduce_twice, t_out, stream)
    compiled(t_out, stream)
    torch.cuda.synchronize()
    expected = torch.tensor([[10.0, 100.0] * 8, [26.0, 260.0] * 8], device="cuda")
    expected = expected.repeat_interleave(128, dim=0)
    torch.testing.assert_close(out, expected, rtol=0, atol=0)
