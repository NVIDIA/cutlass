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

"""TMA 4-D to 2-D — multi-dimensional TMA descriptor with block-indexed slicing.

Loads a 2-D shared-memory tile from a 4-D global tensor using a 4-D TMA
descriptor with per-thread-block coordinate selection.  Block 0 copies
``a[0, :, 0, :]`` and block 1 copies ``a[0, :, 1, :]``, showing how
higher-dimensional TMA coordinates map to shared-memory tiles.
"""

import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute

import torch
from cutlass.experimental import primitives as prims

ELEMENTS_TO_DUMP = 16


@cute.kernel
def kernel(tma_desc_a: cutlass.GridConstant[cuda.TensorMap]) -> None:
    # The a tensor has shape (1, 64, 2, 64)
    # Block 0 should copy a[0, :, 0, :]
    # Block 1 should copy a[0, :, 1, :]
    bx, _, _ = cute.arch.block_idx()
    tx, _, _ = cute.arch.thread_idx()

    smem_matrix_a = cutlass.Array(
        cutlass.Float16, (64, 64), space=cutlass.AddressSpace.smem
    )
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)

    # prefetch descriptor and init barrier
    if prims.elect_sync():
        prims.prefetch_tensormap(tma_desc_a.get_ptr())
        prims.mbarrier_init(mbar, 1)

    # fence and sync
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # set expected bytes and launch TMA load
    if prims.elect_sync():
        sz = tma_desc_a.global_tx_bytes()
        prims.mbarrier_arrive_expect_tx(mbar, sz)
        prims.print_runtime("Block {}: copying {} bytes\n", bx, sz)

        prims.cp_async_bulk_tensor_shared_cta_global(
            smem_matrix_a, tma_desc_a.get_ptr(), (0, 0, 0, bx), mbar
        )

    # wait for TMA to finish — spin on the timelimit variant (stronger
    # `.acquire.cta` ordering; the non-timelimit form is deprecated).
    while not prims.mbarrier_try_wait_parity(mbar, 0, time_limit=10000000):
        pass

    # dump the memory
    if tx == 0 and bx == 1:
        prims.print_runtime("Printing smem_matrix_a from block {}", bx)
        smem_matrix_a.print_runtime(max_elements=ELEMENTS_TO_DUMP)


@cute.jit
def host(matrix_a: cute.Tensor) -> None:
    tma_desc = cuda.create_tensor_map_tiled_from_view(
        matrix_a,
        box_dims=(1, 64, 1, 64),
        swizzle=cuda.TensorMapSwizzle.s128b,
    )

    # Launch the kernel
    block = (32, 1, 1)
    grid = (2, 1, 1)
    kernel(tma_desc).launch(grid=grid, block=block)


shape = (1, 64, 2, 64)
step = 100
a = (
    torch.arange(shape[1]).view(1, shape[1], 1, 1) * 1000
    + torch.arange(shape[2]).view(1, 1, shape[2], 1) * 100
    + torch.arange(shape[3]).view(1, 1, 1, shape[3])
)
a = a.to(torch.float16).cuda()

# Print the expected output
torch.set_printoptions(
    precision=1, sci_mode=False, linewidth=120, threshold=float("inf")
)
print("Expected output:")
for i in range(ELEMENTS_TO_DUMP):
    v = a[0, i, 1, :].cpu().numpy().tolist()
    print(f" [{i}]: {v[:ELEMENTS_TO_DUMP]}")

host(cute.runtime.from_dlpack(a))
torch.cuda.synchronize()

print("PASS")
