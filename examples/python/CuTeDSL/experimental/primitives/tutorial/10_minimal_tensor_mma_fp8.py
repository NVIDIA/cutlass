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

"""Minimal FP8 tensor MMA -- single-tile tcgen05 MMA with FP8 inputs.

FP8 variant of 05_minimal_tensor_mma: same warp-specialized structure
(TMA warp + MMA warp + epilogue warp-group) but with Float8E4M3FN
inputs and FP16 accumulator/output.  Demonstrates FP8-specific TMA
descriptor creation and Tcgen05InstrDesc format selection.
"""

import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute
import cuda.bindings.driver as cuda_driver

import torch
from typing import Callable, List
from cutlass.experimental import primitives as prims


def _get_default_stream() -> cuda_driver.CUstream:
    """Get the default CUDA stream from PyTorch."""
    return cuda_driver.CUstream(torch.cuda.current_stream().cuda_stream)


# GPU Kernel
@cute.kernel
def gemm_kernel(
    tma_desc_a: cutlass.GridConstant[cuda.TensorMap],
    tma_desc_b: cutlass.GridConstant[cuda.TensorMap],
    matrix_c_arr: cutlass.Array,
    problem_size: cutlass.Constexpr[List[int]],
) -> None:
    M, K, N = problem_size

    tx, _, _ = cute.arch.thread_idx()
    warp_id = cute.arch.warp_idx()

    tmem_num_col = N

    # both A & B are K-major
    smem_a = cutlass.Array(
        cutlass.Float8E4M3FN, (M, K), space=cutlass.AddressSpace.smem, alignment=64
    )
    smem_b = cutlass.Array(
        cutlass.Float8E4M3FN, (N, K), space=cutlass.AddressSpace.smem, alignment=64
    )

    mbar_tma = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)
    mbar_mma = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)
    tmem_ptr_i32 = cutlass.Array(cutlass.Int32, 1, space=cutlass.AddressSpace.smem)

    if prims.elect_sync():
        prims.prefetch_tensormap(tma_desc_a.get_ptr())
        prims.prefetch_tensormap(tma_desc_b.get_ptr())
        prims.mbarrier_init(mbar_tma, 1)
        prims.mbarrier_init(mbar_mma, 1)

    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # warp specialization
    is_epi_warp = warp_id < 4
    is_tma_warp = warp_id == 4
    is_tc_warp = warp_id == 5

    if is_tc_warp:
        prims.tcgen05_alloc(tmem_ptr_i32, tmem_num_col)
        prims.tcgen05_relinquish_alloc_permit()

    prims.barrier_cta_sync(0)

    # tmem_ptr points to fix-sized 32-bit slots, so using cutlass.Int8 to
    # simplify pointer arithmetic.
    tmem_ptr = prims.make_tmem_ptr(tmem_ptr_i32.load(), cutlass.Int8)

    # =========================================================================
    # TMA Warp - Load data from global to shared memory
    # =========================================================================
    if is_tma_warp:
        prims.setmaxregister(40, prims.SetMaxRegisterAction.DECREASE)
        prims.bar_warp_sync(cute.arch.FULL_MASK)
        if prims.elect_sync():
            sz = tma_desc_a.global_tx_bytes() + tma_desc_b.global_tx_bytes()
            prims.mbarrier_arrive_expect_tx(mbar_tma, sz)

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

            # Create the descriptors
            # https://docs.nvidia.com/cuda/parallel-thread-execution/index.html?#tcgen05-shared-memory-descriptor
            # 1. leading_byte_offset: for K-major with swizzled layout, it is not used.
            # 2. stride_byte_offset: for K-major, it is the offset from the first 8 rows
            #    to the next 8 rows; (8 rows * 64 columns * 1 byte) = 512 bytes for FP8.
            # 3. layout:
            #   0 - No swizzling
            #   1 - 128-Byte with 32B atomic swizzling
            #   2 - 128-Byte swizzling
            #   4 - 64-Byte swizzling
            #   6 - 32-Byte swizzling
            desc_a = prims.Tcgen05SmemDesc.build(
                smem_a, leading_byte_offset=0, stride_byte_offset=512, layout=4
            )
            desc_b = prims.Tcgen05SmemDesc.build(
                smem_b, leading_byte_offset=0, stride_byte_offset=512, layout=4
            )
            # https://docs.nvidia.com/cuda/parallel-thread-execution/index.html?#tcgen05-instruction-descriptor
            # c_format: F16=0, F32=1, S32=2 for .kind::f8f6f4
            # a/b_format: E4M3=0, E5M2=1, E2M3=3, E3M2=4, E2M1=5 for .kind::f8f6f4
            # n_dim is the logical N (multiple of 8); the encoded field stores
            # N with the 3 LSBs not included. Same idea for m_dim with 4 LSBs.
            idesc = prims.Tcgen05InstrDesc.build(
                c_dtype=cutlass.Float16,
                a_dtype=cutlass.Float16,
                b_dtype=cutlass.Float16,
                n_dim=128,
                m_dim=128,
            )

            # Overwrite target tensor memory for the first iteration to avoid a memset.
            scale_d = False
            # https://docs.nvidia.com/cuda/parallel-thread-execution/index.html?highlight=tensor%2520core%2520shape#tcgen05-matrix-shape
            # with FP8 a/b, matrix shape has K=32; so loop 2 times to finish 64.
            for i in cutlass.range_constexpr(K // 32):
                prims.tcgen05_mma(
                    prims.Tcgen05MMAKind.F8F6F4,
                    prims.CTAGroup.CTA_1,
                    tmem_ptr,
                    desc_a,
                    desc_b,
                    idesc,
                    scale_d,
                )
                # Enable accumulation after first iteration
                scale_d = True
                # Update the existing shared-memory descriptors by 32 bytes (K=32, FP8 = 1B).
                # advance_start_address takes a byte offset; the encoded field
                # stores it with the low 4 bits not included.
                desc_a = desc_a.advance_start_address(32 * 1)
                desc_b = desc_b.advance_start_address(32 * 1)

            prims.tcgen05_commit(mbar_mma)

    # =========================================================================
    # Epilogue Warp - Store results from TMEM to global memory
    # =========================================================================
    elif is_epi_warp:
        while not prims.mbarrier_try_wait_parity(mbar_mma, 0, time_limit=10000000):
            pass
        # 4 warps / 128 threads each getting one lane/row from TMEM
        tid_in_epi_wg = tx % 128
        warpid_in_epi_wg = warp_id % 4
        tmem_raw_addr = tmem_ptr_i32.load()

        # [15:0] for column index and [31:16] for lane/row index
        base_col_id = tmem_raw_addr & 0xFFFF
        base_row_id = tmem_raw_addr >> 16

        # Compute row_id with warpgroup offset
        row_id = base_row_id + warpid_in_epi_wg * 32

        tmem_x = 32
        for n in range(0, tmem_num_col, tmem_x):
            # the row in C this thread will wirte
            c_row = matrix_c_arr[tid_in_epi_wg, :]

            col_id = base_col_id + n
            tmem_offset = (row_id << 16) | col_id

            # https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#tcgen05-matrix-fragments-shape-3232b
            # SHAPE_32x32B indicates 32 rows x 32 bits
            shape = "32x32b"
            # https://docs.nvidia.com/cuda/parallel-thread-execution/index.html?#tcgen05-tensor-memory-ld-st-packing-unpacking
            # pack 16-bit chunks from two TMEM slots into one 32-bit register

            # load from TMEM as Vector
            tmem_addr_ptr = cutlass.inttoptr(
                tmem_offset, mem_space=6, dtype=cutlass.Float16
            )
            # pack=True: two 16-bit values per i32 register, so num = tmem_x // 2
            c_rmem_fp16 = prims.tcgen05_ld(
                shape, tmem_addr_ptr, num=tmem_x // 2, pack=True
            )
            c_row[n:tmem_x] = c_rmem_fp16

    # =========================================================================
    # Cleanup - Wait all warps to release TMEM
    # =========================================================================
    prims.barrier_cta_sync(0)

    # Step 9. Deallocate TMEM
    if is_tc_warp:
        prims.tcgen05_dealloc(tmem_ptr, tmem_num_col)


@cute.jit
def gemm(
    matrix_a: cute.Tensor,
    matrix_b: cute.Tensor,
    matrix_c: cutlass.Array,
    problem_size: cutlass.Constexpr[List[int]],
    stream: cuda_driver.CUstream,
) -> None:
    M, K, N = problem_size
    # Create TMA descriptors
    tma_desc_a = cuda.create_tensor_map_tiled_from_view(
        matrix_a, box_dims=(M, K), swizzle=cuda.TensorMapSwizzle.s64b
    )
    tma_desc_b = cuda.create_tensor_map_tiled_from_view(
        matrix_b, box_dims=(N, K), swizzle=cuda.TensorMapSwizzle.s64b
    )

    # Launch the kernel
    block = (256, 1, 1)
    grid = (1, 1, 1)
    gemm_kernel(tma_desc_a, tma_desc_b, matrix_c, problem_size).launch(
        grid=grid, block=block, stream=stream
    )


def get_compiled_gemm(M: int, K: int, N: int) -> Callable:
    """Compile the GEMM kernel using fake FP8 tensors."""
    cutlass.cuda.initialize_cuda_context()

    # Create fake tensors for compilation - use FP8 E4M3 type
    A_fake = cute.runtime.make_fake_compact_tensor(
        cutlass.Float8E4M3FN,
        (M, K),
        stride_order=(1, 0),
        assumed_align=16,
    )
    B_fake = cute.runtime.make_fake_compact_tensor(
        cutlass.Float8E4M3FN,
        (N, K),
        stride_order=(1, 0),
        assumed_align=16,
    )
    C_fake = cute.runtime.make_fake_compact_tensor(
        cutlass.Float16,
        (M, N),
        stride_order=(1, 0),
        assumed_align=16,
    )
    fake_stream = cute.runtime.make_fake_stream(use_tvm_ffi_env_stream=False)

    # Compile with fake tensors
    compiled_fn = cute.compile(
        gemm,
        A_fake,
        B_fake,
        C_fake,
        (M, K, N),
        fake_stream,
        options="--enable-tvm-ffi",
    )

    return compiled_fn


# =============================================================================
# Main - Test the kernel
# =============================================================================
if __name__ == "__main__":
    M, N, K = (128, 128, 64)
    a = torch.randn(M, K, dtype=torch.float16, device="cuda").to(torch.float8_e4m3fn)
    b = torch.randn(N, K, dtype=torch.float16, device="cuda").to(torch.float8_e4m3fn)
    c = torch.zeros(M, N, dtype=torch.float16, device="cuda")

    print(f"Matrix: {M}x{K} @ {K}x{N} = {M}x{N}")

    # Compile kernel with fake FP8 tensors
    print("Compiling kernel...")
    compiled_gemm = get_compiled_gemm(M, K, N)

    # Kernel transposes matrix_a (transpose=True), so host computation should match
    host_c = a.to(torch.float16) @ b.to(torch.float16).T
    print("@torch result:  ", host_c)

    # Get CUDA stream
    stream = _get_default_stream()

    print("\nRunning kernel...")
    compiled_gemm(a, b, c, stream)
    torch.cuda.synchronize()

    print("@cutlass result:   ", c)
    torch.testing.assert_close(c, host_c, atol=1e-01, rtol=1e-01)

    print("PASS")
