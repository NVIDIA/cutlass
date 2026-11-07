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

"""Cluster reductions safely reuse their mbarrier and distributed buffer."""

import operator

import cuda.bindings.driver as cuda
import cutlass
import pytest
import torch
from blackwell.kernel.reduce.reduce import cluster_reduce, row_reduce
from cutlass import cute
from cutlass.cute.runtime import from_dlpack
from cutlass.memory import SmemAllocator


@cute.jit
def _reduce_value(
    value,
    buf,
    mbar,
    cluster_n: cutlass.Constexpr[int],
    phase,
    via_row: cutlass.Constexpr[bool],
):
    if cutlass.const_expr(via_row):
        reg = cute.make_rmem_tensor((1,), cutlass.Float32)
        reg[0] = value / cutlass.Float32(32)
        return row_reduce(
            reg.load(),
            cute.ReductionOp.ADD,
            128,
            buf,
            mbar,
            cluster_n,
            cutlass.Float32(0),
            phase=phase,
        )
    else:
        return cluster_reduce(
            value, operator.add, buf, mbar, cluster_n, cutlass.Float32(0), phase=phase
        )


@cute.kernel
def _cluster_reuse_kernel(
    out: cute.Tensor,
    cluster_n: cutlass.Constexpr[int],
    delayed: cutlass.Constexpr[bool],
    via_row: cutlass.Constexpr[bool],
):
    tid, _, _ = cute.arch.thread_idx()
    cta = cute.arch.block_idx_in_cluster()
    warp = tid // 32
    smem = SmemAllocator()
    buf = smem.allocate_tensor(
        cutlass.Float32, cute.make_layout((1, (4, cluster_n))), byte_alignment=16
    )
    mbar = smem.allocate_array(cutlass.Int64, num_elems=1)
    if tid == 0:
        cute.arch.mbarrier_init(mbar, 1)
    cute.arch.mbarrier_init_fence()
    cute.arch.cluster_arrive_relaxed()
    cute.arch.cluster_wait()
    for i in range(32):
        first = _reduce_value(
            cutlass.Float32((cta + 1) * 10 + warp + 1 + i * 100),
            buf,
            mbar,
            cluster_n,
            0,
            via_row,
        )
        if cutlass.const_expr(delayed):
            if cta == 1:
                start = cute.arch.clock64()
                while cute.arch.clock64() - start < 100000:
                    pass
        second = _reduce_value(
            cutlass.Float32(((cta + 1) * 10 + warp + 1) * 10 + i * 1000),
            buf,
            mbar,
            cluster_n,
            1,
            via_row,
        )
        out[cta, tid, i * 2] = first
        out[cta, tid, i * 2 + 1] = second


@cute.jit
def _launch_cluster_reuse(
    out: cute.Tensor,
    cluster_n: cutlass.Constexpr[int],
    delayed: cutlass.Constexpr[bool],
    via_row: cutlass.Constexpr[bool],
    stream: cuda.CUstream,
):
    _cluster_reuse_kernel(out, cluster_n, delayed, via_row).launch(
        grid=(cluster_n, 1, 1),
        block=(128, 1, 1),
        cluster=(cluster_n, 1, 1),
        stream=stream,
    )


@pytest.mark.skipif(not torch.cuda.is_available(), reason="requires a CUDA GPU")
@pytest.mark.parametrize("cluster_n", [2, 4])
@pytest.mark.parametrize("delayed", [False, True])
@pytest.mark.parametrize("via_row", [False, True])
def test_cluster_reduce_reuses_buffer(cluster_n, delayed, via_row):
    if torch.cuda.get_device_capability() < (9, 0):
        pytest.skip("requires thread block clusters")
    out = torch.empty((cluster_n, 128, 64), device="cuda", dtype=torch.float32)
    tensor = from_dlpack(out, assumed_align=16).mark_layout_dynamic()
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled = cute.compile(
        _launch_cluster_reuse, tensor, cluster_n, delayed, via_row, stream
    )
    compiled(tensor, stream)
    torch.cuda.synchronize()
    base = cluster_n * 10 + 20 * cluster_n * (cluster_n + 1)
    values = [
        value
        for i in range(32)
        for value in (base + i * 400 * cluster_n, (base + i * 400 * cluster_n) * 10)
    ]
    expected = torch.tensor(values, device="cuda", dtype=torch.float32).expand_as(out)
    torch.testing.assert_close(out, expected, rtol=0, atol=0)


@cute.kernel
def _dynamic_phase_kernel(out: cute.Tensor):
    tid, _, _ = cute.arch.thread_idx()
    cta = cute.arch.block_idx_in_cluster()
    warp = tid // 32
    smem = SmemAllocator()
    buf = smem.allocate_tensor(
        cutlass.Float32, cute.make_layout((1, (4, 2))), byte_alignment=16
    )
    mbar = smem.allocate_array(cutlass.Int64, num_elems=1)
    if tid == 0:
        cute.arch.mbarrier_init(mbar, 1)
    cute.arch.mbarrier_init_fence()
    cute.arch.cluster_arrive_relaxed()
    cute.arch.cluster_wait()
    for i in range(64):
        out[cta, tid, i] = cluster_reduce(
            cutlass.Float32((cta + 1) * 10 + warp + 1 + i * 100),
            operator.add,
            buf,
            mbar,
            2,
            cutlass.Float32(0),
            phase=i % 2,
        )


@cute.jit
def _launch_dynamic_phase(out: cute.Tensor, stream: cuda.CUstream):
    _dynamic_phase_kernel(out).launch(
        grid=(2, 1, 1), block=(128, 1, 1), cluster=(2, 1, 1), stream=stream
    )


@pytest.mark.skipif(not torch.cuda.is_available(), reason="requires a CUDA GPU")
def test_cluster_reduce_dynamic_phase():
    if torch.cuda.get_device_capability() < (9, 0):
        pytest.skip("requires thread block clusters")
    out = torch.empty((2, 128, 64), device="cuda", dtype=torch.float32)
    tensor = from_dlpack(out, assumed_align=16).mark_layout_dynamic()
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled = cute.compile(_launch_dynamic_phase, tensor, stream)
    compiled(tensor, stream)
    torch.cuda.synchronize()
    expected = torch.arange(64, device="cuda", dtype=torch.float32) * 800 + 140
    torch.testing.assert_close(out, expected.expand_as(out), rtol=0, atol=0)
