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

"""Minimal tensor MMA -- single-tile tcgen05 MMA with warp specialisation.

Simplest warp-specialized tcgen05 kernel: one TMA warp loads A and B,
one MMA warp executes ``tcgen05_mma``, and an epilogue warp-group reads
back from TMEM.  Demonstrates the full Blackwell tcgen05 lifecycle
(alloc → mma → commit → dealloc) with single-stage mbarrier signaling.
"""

import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute

import torch
from typing import List
from cutlass.experimental import primitives as prims


# GPU Kernel
@cute.kernel
def gemm_kernel(
    tma_desc_a: cutlass.GridConstant[cuda.TensorMap],
    tma_desc_b: cutlass.GridConstant[cuda.TensorMap],
    matrix_c_arr: cutlass.Array,
    problem_size: cutlass.Constexpr[List[int]],
) -> None:
    M, K, N = problem_size
    # Step 1. Get thread/warp indices
    tx, _, _ = cute.arch.thread_idx()
    warp_id = cute.arch.warp_idx()

    tmem_num_col = 128

    # Step 2. Allocate shared memory for matrices and mbarriers
    # Note cutlass.Array's shape assumes (major-dim, minor-dim) convention,
    # so (M/N, K) here correponds to (K, M/N) box_dim.
    smem_a = cutlass.Array(cutlass.Float16, (M, K), space=cutlass.AddressSpace.smem)
    smem_b = cutlass.Array(cutlass.Float16, (N, K), space=cutlass.AddressSpace.smem)
    mbar_tma = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)
    mbar_mma = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)
    tmem_ptr_i32 = cutlass.Array(cutlass.Int32, 1, space=cutlass.AddressSpace.smem)

    # Step 3. Initialize mbarriers and prefetch TMA descriptors
    if prims.elect_sync():
        prims.prefetch_tensormap(tma_desc_a.get_ptr())
        prims.prefetch_tensormap(tma_desc_b.get_ptr())
        prims.mbarrier_init(mbar_tma, 1)
        prims.mbarrier_init(mbar_mma, 1)

    # Step 4. Fence/Barrier
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # Step 5. Warp Specialization
    is_tma_warp = warp_id == 0
    is_tc_warp = warp_id == 1
    is_epi_warp = warp_id > 3
    # epilogue warp reads from TMEM, which has access restrictions that
    # warp-0 (1, ..) of a warpgroup can only access 0-31 (32-64, ..) lanes/rows of TMEM.
    # so we want the 4 epilogue warps to be warp 4,5,6,7 by skipping warp 2 & 3,
    # such that they are warp 0,1,2,3 of the 2nd warpgroup.

    # Step 6. Exit the kernel for unneeded warps
    if warp_id == 2 or warp_id == 3:
        prims.exit()

    # Step 7. Allocate TMEM (Tensor Memory)
    if is_tc_warp:
        prims.tcgen05_alloc(tmem_ptr_i32, tmem_num_col)
        prims.tcgen05_relinquish_alloc_permit()

    prims.barrier_cta_sync(0)

    # Retrieve TMEM pointer from the shared memory buffer
    tmem_ptr = prims.make_tmem_ptr(tmem_ptr_i32.load(), cutlass.Int32)

    # =========================================================================
    # TMA Warp - Load data from global to shared memory
    # =========================================================================
    if is_tma_warp:
        prims.setmaxregister(40, prims.SetMaxRegisterAction.DECREASE)
        prims.bar_warp_sync(cute.arch.FULL_MASK)
        if prims.elect_sync():
            sz = tma_desc_a.global_tx_bytes() + tma_desc_b.global_tx_bytes()
            prims.mbarrier_arrive_expect_tx(mbar_tma, sz)

            # Async TMA Load
            prims.cp_async_bulk_tensor_shared_cta_global(
                smem_a, tma_desc_a.get_ptr(), (0, 0), mbar_tma
            )
            prims.cp_async_bulk_tensor_shared_cta_global(
                smem_b, tma_desc_b.get_ptr(), (0, 0), mbar_tma
            )

    # =========================================================================
    # Tensor Core Warp - Execute MMA operations
    # =========================================================================
    elif is_tc_warp:
        prims.bar_warp_sync(cute.arch.FULL_MASK)

        # GEMM using tcgen05
        if prims.elect_sync():
            while not prims.mbarrier_try_wait_parity(mbar_tma, 0, time_limit=10000000):
                pass

            # Create root shared-memory descriptors once; K-block movement uses byte
            # offsets through the public descriptor API below.
            desc_a_root = prims.Tcgen05SmemDesc.build(
                smem_a,
                leading_byte_offset=16,
                stride_byte_offset=1024,
                layout=prims.Tcgen05SmemSwizzle.SWIZZLE_128B,
            )
            desc_b_root = prims.Tcgen05SmemDesc.build(
                smem_b,
                leading_byte_offset=16,
                stride_byte_offset=1024,
                layout=prims.Tcgen05SmemSwizzle.SWIZZLE_128B,
            )
            # Instruction descriptor — enums replace magic ints.
            # Builder takes the logical N/M (multiples of 8/16); the encoded
            # field stores the value with the low bits not included.
            idesc = prims.Tcgen05InstrDesc.build(
                c_dtype=cutlass.Float32, n_dim=128, m_dim=128
            )

            # Overwrite target tensor memory for the first iteration to avoid a memset.
            scale_d = False
            # https://docs.nvidia.com/cuda/parallel-thread-execution/index.html?highlight=tensor%2520core%2520shape#tcgen05-matrix-shape
            # with FP16/BF16 a/b, matrix shape has K=16; so loop 4 times to finish 64.
            for i in cutlass.range_constexpr(4):
                desc_offset_bytes: cutlass.Constexpr[int] = 16 * 2 * i
                prims.tcgen05_mma(
                    prims.Tcgen05MMAKind.F16,
                    prims.CTAGroup.CTA_1,
                    tmem_ptr,
                    desc_a_root.advance_start_address(desc_offset_bytes),
                    desc_b_root.advance_start_address(desc_offset_bytes),
                    idesc,
                    scale_d,
                )
                # Enable accumulation after first iteration
                scale_d = True

            prims.tcgen05_commit(mbar_mma)

    # =========================================================================
    # Epilogue Warp - Store results from TMEM to global memory
    # =========================================================================
    elif is_epi_warp:
        while not prims.mbarrier_try_wait_parity(mbar_mma, 0, time_limit=10000000):
            pass
        # 4 warps / 128 threads each getting one lane/row from TMEM
        warpid_in_epi_wg = warp_id % 4
        # TmemAddr wraps the raw 32-bit address with col_id/row_id fields
        tmem_base = prims.TmemAddr(tmem_ptr_i32.load())
        base_col_id = tmem_base.col_id
        base_row_id = tmem_base.row_id

        # Compute row_id with warp offset
        row_id_with_warp_offset = base_row_id + warpid_in_epi_wg * 32

        for n in range(0, tmem_num_col, 2):
            tmem_addr = prims.TmemAddr.from_row_col(
                row_id_with_warp_offset, base_col_id + n
            )
            tmem = tmem_addr.as_ptr(cutlass.Float32)

            # https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#tcgen05-matrix-fragments-shape-3232b
            # SHAPE_32x32B indicates 32 rows x 32 bits
            shape = "32x32b"
            # loading 2 32-bit elements per row so expecting 2 registers per thread
            tmem_x = 2
            c_rmem = prims.tcgen05_ld(shape, tmem, num=tmem_x)

            m_id = tx % 128  # each thread gets one of the 128 rows
            for i in cutlass.range_constexpr(tmem_x):
                matrix_c_arr[m_id, n + i] = cutlass.Float16(c_rmem[i])

    # =========================================================================
    # Cleanup - Wait all warps to release TMEM
    # =========================================================================
    prims.barrier_cta_sync(0)

    # Step 8. Deallocate TMEM
    if is_tc_warp:
        prims.tcgen05_dealloc(tmem_ptr, tmem_num_col)


@cute.jit
def gemm(
    matrix_a: cute.Tensor,
    matrix_b: cute.Tensor,
    matrix_c: cutlass.Array,
    problem_size: cutlass.Constexpr[List[int]],
) -> None:
    M, K, N = problem_size
    # Create TMA descriptors
    # Both a & b are K-major.
    tma_desc_a = cuda.create_tensor_map_tiled_from_view(
        matrix_a, box_dims=(M, K), swizzle=cuda.TensorMapSwizzle.s128b
    )
    tma_desc_b = cuda.create_tensor_map_tiled_from_view(
        matrix_b, box_dims=(K, N), swizzle=cuda.TensorMapSwizzle.s128b
    )

    # Launch the kernel
    block = (256, 1, 1)
    grid = (1, 1, 1)
    gemm_kernel(tma_desc_a, tma_desc_b, matrix_c, problem_size).launch(
        grid=grid, block=block
    )


# =============================================================================
# Main - Test the kernel
# =============================================================================
M, N, K = (128, 128, 64)
# `.T` on torch.Tensor only flips the convention of shape tuple,
# e.g. from (row, col) to (col, row) without changing the physical layout.
# so a is row-major/K-major and b is column-major/K-major.
a = torch.randn(M, K, dtype=torch.float16, device="cuda")
b = torch.randn(N, K, dtype=torch.float16, device="cuda").T
c = torch.zeros(M, N, dtype=torch.float16, device="cuda")

print(f"Matrix: {M}x{K} @ {K}x{N} = {M}x{N}")

# Kernel transposes matrix_a (transpose=True), so host computation should match
host_c = a @ b

gemm(
    cute.runtime.from_dlpack(a),
    cute.runtime.from_dlpack(b),
    cute.runtime.from_dlpack(c),
    (M, K, N),
)

print("@cutlass result:   ", c)
print("@torch result:  ", host_c)
torch.testing.assert_close(c, host_c, atol=1e-03, rtol=1e-03)

print("PASS")
