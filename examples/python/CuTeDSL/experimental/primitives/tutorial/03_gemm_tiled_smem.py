# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""Tiled GEMM with shared memory — classic shared-memory tile-and-accumulate pattern.

Tiles A and B into shared-memory blocks (TS × TS), synchronises with
``prims.barrier_cta_sync(0)``, and accumulates partial products.  First example
using ``cutlass.Array(..., space=cutlass.AddressSpace.smem)`` and explicit
thread-block (PTX CTA) barriers — the foundation for all pipelined kernels.
"""

import cutlass
import cutlass.cute as cute
import torch
from cutlass.experimental import primitives as prims


# Step 2. Define the kernel
@cute.kernel
def gemm_kernel(
    a: cutlass.Array,
    b: cutlass.Array,
    c: cutlass.Array,
    TS: cutlass.Constexpr[int],
):
    # Step 3. Get thread and block indices
    tx, ty, _ = cute.arch.thread_idx()
    bx, by, _ = cute.arch.block_idx()

    # Step 4. Allocate shared memory tiles
    a_smem = cutlass.Array(cutlass.Float32, (TS, TS), space=cutlass.AddressSpace.smem)
    b_smem = cutlass.Array(cutlass.Float32, (TS, TS), space=cutlass.AddressSpace.smem)

    K = a.shape[1]
    tmp = 0.0
    for bk in range(0, K, TS):
        a_smem[ty, tx] = a[bx * TS + ty, bk + tx]
        b_smem[ty, tx] = b[bk + ty, by * TS + tx]

        prims.barrier_cta_sync(0)

        for j in range(TS):
            tmp += a_smem[ty, j] * b_smem[j, tx]

        prims.barrier_cta_sync(0)

    c[bx * TS + ty, by * TS + tx] = tmp


# Step 18. Define the host function
# TODO: Alternatively, Python can call the `cute.kernel` directly
@cute.jit
def gemm(
    matrix_a: cute.Tensor,
    matrix_b: cute.Tensor,
    matrix_c: cute.Tensor,
    TS: cutlass.Constexpr[int],
):
    # Step 19. Define the block and grid dimensions
    block = (TS, TS, 1)
    m = matrix_a.shape[0]
    n = matrix_b.shape[1]
    grid = (m // TS, n // TS, 1)
    prims.print_runtime(
        "Launching kernel with grid: <<<({}, {}, {}), block: ({}, {}, {})>>>",
        grid[0],
        grid[1],
        grid[2],
        block[0],
        block[1],
        block[2],
    )

    # Step 20. Launch the kernel
    gemm_kernel(matrix_a, matrix_b, matrix_c, TS).launch(grid=grid, block=block)


# Step 21. Create random matrices
sz = 1024
a = torch.randn(sz, sz).to(torch.float32).cuda()
b = torch.randn(sz, sz).to(torch.float32).cuda()
c = torch.zeros(sz, sz).to(torch.float32).cuda()
host_c = a @ b

# Step 22. Launch the kernel
gemm(
    cute.runtime.from_dlpack(a),
    cute.runtime.from_dlpack(b),
    cute.runtime.from_dlpack(c),
    TS=32,
)

# Step 23. Compute the reference and compare the result
torch.testing.assert_close(c, host_c, atol=1e-03, rtol=1e-03)
print("PASS")

# Expected output:
# Launching kernel with grid: <<<(32, 32, 1), block: (32, 32, 1)>>>
# PASS
