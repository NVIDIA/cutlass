# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""Naive GEMM — one thread per output element, global memory only.

Each thread computes one C[i,j] by walking the K-dimension in a
sequential loop.  No shared memory, no tiling — purely demonstrates
the cutlass ↔ PyTorch data flow (``cutlass.Array``,
grid/block launch configuration, torch result verification).
"""

import cutlass.cute as cute
import torch
import cutlass
from cutlass.experimental import primitives as prims


# Step 1. Define the kernel
@cute.kernel
def gemm_kernel(a: cutlass.Array, b: cutlass.Array, c: cutlass.Array):
    # Step 2. Get thread and block indices
    tx, ty, _ = cute.arch.thread_idx()
    bx, by, _ = cute.arch.block_idx()
    bdimx, bdimy, _ = cute.arch.block_dim()
    idx = tx + bx * bdimx
    idy = ty + by * bdimy

    # Step 4. Check if the thread is within the bounds of the matrix
    if idx < c.shape[0] and idy < c.shape[1]:
        tmp = 0.0
        for k in range(a.shape[1]):
            # Step 5. Load the elements from the matrices
            tmp += a[idx, k] * b[k, idy]
        # Step 6. Store the result to the matrix
        c[idx, idy] = tmp


@cute.jit
def gemm(matrix_a: cutlass.Array, matrix_b: cutlass.Array, matrix_c: cutlass.Array):
    # Step 8. Define the block and grid dimensions
    block = (32, 4, 1)
    m = matrix_a.shape[0]
    n = matrix_b.shape[1]
    grid = (m // 32, n // 4, 1)

    # Step 9. Print the launch configuration
    prims.print_runtime(
        "Launching kernel with grid: <<<({}, {}, {}), block: ({}, {}, {})>>>",
        grid[0],
        grid[1],
        grid[2],
        block[0],
        block[1],
        block[2],
    )

    # Step 10. Launch the kernel
    gemm_kernel(matrix_a, matrix_b, matrix_c).launch(grid=grid, block=block)


# Step 11. Create random matrices
a = torch.randn(1024, 1024).to(torch.float32).cuda()
b = torch.randn(1024, 1024).to(torch.float32).cuda()
c = torch.randn(1024, 1024).to(torch.float32).cuda()

# Step 12. Launch the kernel
gemm(
    cute.runtime.from_dlpack(a),
    cute.runtime.from_dlpack(b),
    cute.runtime.from_dlpack(c),
)

# Step 13. Compute the reference and compare the result
host_c = a @ b
torch.testing.assert_close(c, host_c, atol=1e-03, rtol=1e-03)
print("PASS")

# Expected output:
# Launching kernel with grid: <<<(32, 256, 1), block: (32, 4, 1)>>>
# PASS
