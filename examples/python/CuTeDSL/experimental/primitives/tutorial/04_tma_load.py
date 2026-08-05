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

"""TMA async load — single-stage mbarrier-gated global-to-shared transfer.

First TMA example: builds a tiled TMA descriptor, issues one
``cp_async_bulk_tensor_shared_cta_global`` from an elected thread, and
waits on an mbarrier.  Introduces the full mbarrier lifecycle:
``mbarrier_init → fence_mbarrier_init → barrier → arrive_expect_tx →
cp_async → try_wait_parity_timelimit``.
"""

import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute

import torch
from cutlass.experimental import primitives as prims


# Step 1. GPU Kernel
@cute.kernel
def gemm_kernel(tma_desc_a: cutlass.GridConstant[cuda.TensorMap]):
    # Step 2. Get thread index
    tx, _, _ = cute.arch.thread_idx()

    # Step 3. Allocate shared memory for matrix and mbarrier
    smem_matrix_a = cutlass.Array(
        cutlass.Float16, (64, 64), space=cutlass.AddressSpace.smem
    )
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)

    # Step 4. Initialize mbarrier and prefetch TMA Descriptor
    if prims.elect_sync():
        prims.prefetch_tensormap(tma_desc_a.get_ptr())
        prims.mbarrier_init(mbar, 1)

    # Step 5. Fence/Barrier
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # Step 6. Async TMA Load
    if prims.elect_sync():
        # Step 7. Arrive and expect transaction
        sz = tma_desc_a.global_tx_bytes()
        prims.mbarrier_arrive_expect_tx(mbar, sz)

        # Step 8. Async TMA Load
        prims.cp_async_bulk_tensor_shared_cta_global(
            smem_matrix_a, tma_desc_a.get_ptr(), (0, 0), mbar
        )

    # Step 9. All threads wait on mbarrier. Spin on the timelimit variant so
    # we retry on a tick-timeout and use the stronger `.acquire.cta` ordering
    # (TMA writes are guaranteed visible after the wait returns).
    while not prims.mbarrier_try_wait_parity(mbar, 0, time_limit=10000000):
        pass

    # Step 10. Thread 0 prints the memory matrix from shared memory
    if tx == 0:
        smem_matrix_a.print_runtime()


@cute.jit
def gemm(matrix_a: cute.Tensor):
    # Row-major (M, K) with innermost K → TMA order is (K, M) = stride_order (1, 0).
    # Required when the tensor has dynamic strides (mark_layout_dynamic) so the
    # descriptor builder can't infer order from concrete strides.
    tma_desc = cuda.create_tensor_map_tiled_from_view(
        matrix_a,
        box_dims=(64, 64),
        stride_order=(1, 0),
        swizzle=cuda.TensorMapSwizzle.s128b,
    )

    # Launch the kernel
    block = (32, 1, 1)
    grid = (1, 1, 1)
    gemm_kernel(tma_desc).launch(grid=grid, block=block)


rows = 128
cols = 128
step = 100.0  # increment per row
a = torch.arange(cols).unsqueeze(0) + (torch.arange(rows) * step).unsqueeze(1)
a = a.to(torch.float16).cuda()

# Print CUDA device address
print(f"CUDA device address of a: 0x{a.data_ptr():016x} ({a.data_ptr()})")
# Set print options for nicer output
torch.set_printoptions(precision=1, sci_mode=False, linewidth=120)
print(a)

# Case 1: Dynamic layout, generic code is generated, better for re-use the same code for different shapes. But compielr can optimize less
dynamic_layout_a = cute.runtime.from_dlpack(a).mark_layout_dynamic(leading_dim=1)
gemm(dynamic_layout_a)

# Case 2: Static layout, specific code is generated, better for performance. But can not re-use the same code for different shapes.
static_layout_a = cute.runtime.from_dlpack(a)
gemm(cute.runtime.from_dlpack(a))

print("PASS")

# Expected output (transpose=True swaps row/column, so tile[i,j] = original[j,i] = i + j*100):
# PASS
# Array[64x64]:
#   0:[0.0, 100.0, 200.0, ...
#   1:[1.0, 101.0, 201.0, ...
#   2:[2.0, 102.0, 202.0, ...
#   3:[3.0, 103.0, 203.0, ...
#   4:[4.0, 104.0, 204.0, ...
#   5:[5.0, 105.0, 205.0, ...
#   6:[6.0, 106.0, 206.0, ...
#   7:[7.0, 107.0, 207.0, ...
#   8:[8.0, 108.0, 208.0, ...
#   9:[9.0, 109.0, 209.0, ...
#  10:[10.0, 110.0, 210.0, ...
#  11:[11.0, 111.0, 211.0, ...
#  12:[12.0, 112.0, 212.0, ...
#  13:[13.0, 113.0, 213.0, ...
#  14:[14.0, 114.0, 214.0, ...
#  15:[15.0, 115.0, 215.0, ...
#   ...
