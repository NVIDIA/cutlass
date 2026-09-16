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

"""Single-block Blackwell GEMM with warp specialization, multi-stage shared memory, cutlass DSL.

fp16 ``M=128, N=128, K (multiple of 64)`` tile.  Warp-0 is the TMA producer,
warp-1 is the tcgen05.mma consumer, warps 4-7 form the 4-warp epilogue
(SHAPE_32X32B).  Producer / consumer overlap naturally via mbarrier
phase-flip — no software pipelining or modulo scheduling.

The full architectural commentary lives in the comment block below this
docstring — read that as a tutorial; this module docstring is the indexed
RXMP record.

To run::

    python examples/CuTeDSL/experimental/primitives/tutorial/gemm_M128_N128_Kany_TN_warpspec_multistage.py
"""
# ==============================================================================
# Single-block Blackwell GEMM with Warp Specialization (cutlass DSL)
# ==============================================================================
#
# This kernel implements a 128x128xK GEMM (K must be multiple of 64) using
# NVIDIA Blackwell's tcgen05 (5th gen Tensor Cores) written in cutlass DSL.
#
# Architecture: single thread block (PTX CTA) with warp specialization
# -----------------------------------------------------------------------------
#
# WARP SPECIALIZATION (Producer-Consumer Pattern):
#    - Warp 0 (TMA Warp):    PRODUCER - async loads tiles from global memory via TMA
#    - Warp 1 (TC Warp):     CONSUMER - executes tensor core MMA operations
#    - Warps 2-3:            Unused (exit immediately)
#    - Warps 4-7 (Epi Warp): Epilogue - stores results from TMEM to global memory
#
#    Producer and Consumer warps run ASYNCHRONOUSLY and independently.
#    No software pipelining/modulo scheduling is needed - the warps naturally
#    overlap because they execute concurrently and synchronize only when necessary.
#
# MULTI-STAGE BUFFERING:
#    - num_ab_stage shared memory buffers allow producer to stay ahead of consumer
#    - Each stage holds a (TILE_M x TILE_K) tile for A and (TILE_K x TILE_N) for B
#    - Circular buffer indexing: stage = (k // 64) % num_ab_stage
#
# MBARRIER SYNCHRONIZATION (Phase-Based):
#    - ab_full_mbar[stage]:  Producer signals "data ready" after TMA load completes
#    - ab_empty_mbar[stage]: Consumer signals "buffer free" after MMA consumes data
#    - mbar_mma:             Consumer signals "all K iterations done" for epilogue
#
#    Phase bits toggle on each use to distinguish consecutive arrivals on the
#    same mbarrier. Producer waits on empty, Consumer waits on full.
#
# BLACKWELL TENSOR CORE FEATURES:
#    - TMEM (Tensor Memory): On-chip accumulator storage for MMA results
#    - tcgen05_mma: Executes 128x128x16 MMA operations
#    - TMA (Tensor Memory Accelerator): Hardware async global->shared copies
#
# Data Flow:
# ----------
#    Global A (MxK) --[TMA async]--> shared A [num_ab_stage][TILE_M][TILE_K]
#    Global B (KxN) --[TMA async]--> shared B [num_ab_stage][TILE_K][TILE_N]
#    Shared A/B ----[tcgen05_mma]--> TMEM accumulator
#    TMEM ---------[epilogue]------> Global C (MxN)
#
# Reference: this follows the same single-tile tensor-MMA structure as the
# neighboring minimal tensor-MMA tutorials.
# ==============================================================================

import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute
import cuda.bindings.driver as cuda_driver

import torch
from typing import List
import time
from cutlass.experimental import primitives as prims

# =============================================================================
# TCGEN05 DESCRIPTOR PARAMETERS EXPLAINED
# =============================================================================
#
# Shared-memory descriptor: cutlass.Tcgen05SmemDesc.build(ptr, leading_dim, stride_dim, layout)
# -----------------------------------------------------------------------------------------
#   desc_a = cutlass.Tcgen05SmemDesc.build(smem_a, 16, 1024, layout=2)
#   desc_b = cutlass.Tcgen05SmemDesc.build(smem_b, 16, 1024, layout=2)
#
# Layout: A is K-major (row-major), B is N-major (row-major), both use 128-byte swizzling
#
# References:
#   https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-leading-dimension-byte-offset-relative-offset
#   https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-stride-dimension-byte-offset
#
# Leading Dimension Byte Offset (1st param):
#   Matrix A (K-major): stride from 1st to 2nd column of 8x2 tile in 128-bit normalized matrix
#                       = 8 * 2 bytes = 16 -> leading_dim_offset(A) = 16
#   Matrix B (N-major): stride from first (swizzle_size/16) rows to next (swizzle_size/16) rows
#                       = (128/16) * M(128) * 2 bytes = 2048 -> leading_dim_offset(B) = 2048
#
# Stride Dimension Byte Offset (2nd param):
#   Matrix A (K-major): offset from first 8 rows to next 8 rows
#                       = 8 rows * K(64) * 2 bytes = 1024 -> stride_offset(A) = 1024
#   Matrix B (N-major): offset from first 8 cols to next 8 cols
#                       = 8 * 2 bytes = 16 -> stride_offset(B) = 16
#
# Instruction Descriptor: cutlass.Tcgen05InstrDesc.build(c_format, n_dim, m_dim)
# -------------------------------------------------------------------------------
#   idesc = cutlass.Tcgen05InstrDesc.build(c_dtype=cutlass.Float32, n_dim=128, m_dim=128)
#
# Reference: https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-instruction-descriptor
#
#   c_format: Matrix D output type (1 = FP32)
#   n_dim:    N dimension of Matrix B — must be a multiple of 8
#             (the encoded field stores N with the 3 LSBs not included)
#   m_dim:    M dimension of Matrix A — must be a multiple of 16
#             (the encoded field stores M with the 4 LSBs not included)
# =============================================================================


@cute.kernel
def gemm_kernel(
    tma_desc_a: cutlass.GridConstant[cuda.TensorMap],
    tma_desc_b: cutlass.GridConstant[cuda.TensorMap],
    matrix_c_arr: cutlass.Array,
    problem_size: cutlass.Constexpr[List[int]],
    num_ab_stage: cutlass.Constexpr[int],
    TILE_M: cutlass.Constexpr[int],
    TILE_K: cutlass.Constexpr[int],
    TILE_N: cutlass.Constexpr[int],
):
    M, N, K = problem_size
    tx, _, _ = cute.arch.thread_idx()
    warp_idx = cute.arch.warp_idx()

    tmem_num_col = 128

    # =========================================================================
    # Allocate num_ab_stage worth of shared memory for pipelining
    # =========================================================================
    # Each stage has a (128, 64) tile for A and (64, 128) tile for B
    # We allocate as (num_ab_stage * 128, 64) and (num_ab_stage * 64, 128)
    # Then use pointer arithmetic to access each stage

    # Allocate multi-stage buffers
    smem_a = cutlass.Array(
        cutlass.Float16,
        (num_ab_stage * TILE_M, TILE_K),
        space=cutlass.AddressSpace.smem,
    )
    smem_b = cutlass.Array(
        cutlass.Float16,
        (num_ab_stage * TILE_K, TILE_N),
        space=cutlass.AddressSpace.smem,
    )

    # Allocate per-stage mbarriers for TMA synchronization
    ab_full_mbar = cutlass.Array(
        cutlass.Int64, num_ab_stage, space=cutlass.AddressSpace.smem
    )
    ab_empty_mbar = cutlass.Array(
        cutlass.Int64, num_ab_stage, space=cutlass.AddressSpace.smem
    )
    tma_ab_empty_phase_bit = cutlass.Array(
        cutlass.Int64, num_ab_stage, space=cutlass.AddressSpace.smem
    )
    tma_ab_full_phase_bit = cutlass.Array(
        cutlass.Int64, num_ab_stage, space=cutlass.AddressSpace.smem
    )

    mbar_mma = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)
    tmem_ptr_i32 = cutlass.Array(cutlass.Int32, 1, space=cutlass.AddressSpace.smem)

    if prims.elect_sync():
        prims.prefetch_tensormap(tma_desc_a.get_ptr())
        prims.prefetch_tensormap(tma_desc_b.get_ptr())
        # Initialize mbarrier for each stage
        for s in range(num_ab_stage):
            prims.mbarrier_init(ab_full_mbar.subview(s), 1)
            prims.mbarrier_init(ab_empty_mbar.subview(s), 1)
        prims.mbarrier_init(mbar_mma, 1)

    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # Warp Specialization
    is_tma_warp = warp_idx == 0
    is_tc_warp = warp_idx == 1
    is_epi_warp = warp_idx > 3

    # Exit the kernel for unneeded warps
    if warp_idx == 2 or warp_idx == 3:
        prims.exit()

    # Allocate TMEM
    if is_tc_warp:
        prims.tcgen05_alloc(tmem_ptr_i32, tmem_num_col)
        prims.tcgen05_relinquish_alloc_permit()

    # Retrieve TMEM pointer from the shared memory buffer
    tmem_ptr = prims.make_tmem_ptr(tmem_ptr_i32.load(), cutlass.Int32)

    tma_empty_phase = [1] * num_ab_stage
    tma_empty_phase[0] = 1
    if tx == 0:
        for s in range(num_ab_stage):
            tma_ab_empty_phase_bit[s] = 1
            tma_ab_full_phase_bit[s] = 0
    prims.barrier_cta_sync(0)

    for k in range(0, K, TILE_K):
        # Compute which stage to use (cycles through 0, 1, ..., num_ab_stage-1)
        stage = (k // TILE_K) % num_ab_stage

        # =====================================================================
        # Get pointers to this stage's shared-memory buffers
        # =====================================================================
        # smem_a_stage points to row (stage * TILE_M) of the full buffer
        # Using pointer arithmetic: offset = stage * TILE_M * TILE_K elements
        smem_a_stage = smem_a.subview(stage * TILE_M * TILE_K)
        smem_b_stage = smem_b.subview(stage * TILE_K * TILE_N)

        # TMA Warp
        if is_tma_warp:
            prims.setmaxregister(40, prims.SetMaxRegisterAction.DECREASE)
            prims.bar_warp_sync(cute.arch.FULL_MASK)

            while not prims.mbarrier_try_wait_parity(
                ab_empty_mbar.subview(stage),
                tma_ab_empty_phase_bit[stage],
                time_limit=10000000,
            ):
                pass
            tma_ab_empty_phase_bit[stage] = tma_ab_empty_phase_bit[stage] ^ 1
            if prims.elect_sync():
                # TMA async load: copies boxDim elements starting at tensorCoords
                # tensorCoords=(k, 0) means: start at row k, column 0
                # This loads a (TILE_K x TILE_M) tile for A and (TILE_K x TILE_N) for B
                sz = tma_desc_a.global_tx_bytes() + tma_desc_b.global_tx_bytes()
                prims.mbarrier_arrive_expect_tx(ab_full_mbar.subview(stage), sz)
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem_a_stage,
                    tma_desc_a.get_ptr(),
                    (k, 0),
                    ab_full_mbar.subview(stage),
                )
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem_b_stage,
                    tma_desc_b.get_ptr(),
                    (k, 0),
                    ab_full_mbar.subview(stage),
                )
        elif is_tc_warp:
            prims.bar_warp_sync(cute.arch.FULL_MASK)
            #  GEMM
            if prims.elect_sync():
                # GEMM - wait for TMA to complete, then compute
                while not prims.mbarrier_try_wait_parity(
                    ab_full_mbar.subview(stage),
                    tma_ab_full_phase_bit[stage],
                    time_limit=10000000,
                ):
                    pass
                # Create the descriptors for this stage's shared-memory buffers
                tma_ab_full_phase_bit[stage] = tma_ab_full_phase_bit[stage] ^ 1
                desc_a = prims.Tcgen05SmemDesc.build(
                    smem_a_stage,
                    16,
                    1024,
                    layout=prims.Tcgen05SmemSwizzle.SWIZZLE_128B,
                )
                desc_b = prims.Tcgen05SmemDesc.build(
                    smem_b_stage,
                    16,
                    1024,
                    layout=prims.Tcgen05SmemSwizzle.SWIZZLE_128B,
                )
                idesc = prims.Tcgen05InstrDesc.build(
                    c_dtype=cutlass.Float32, n_dim=128, m_dim=128
                )
                scale_d = True
                if k == 0:
                    scale_d = False
                else:
                    scale_d = True
                for i in cutlass.range_constexpr(4):
                    prims.tcgen05_mma(
                        prims.Tcgen05MMAKind.F16,
                        prims.CTAGroup.CTA_1,
                        tmem_ptr,
                        desc_a,
                        desc_b,
                        idesc,
                        scale_d,
                    )
                    # Enable accumulation after here
                    scale_d = True
                    # Advance start_address for next K iteration
                    desc_a = desc_a.advance_start_address(32)
                    desc_b = desc_b.advance_start_address(32)
                # Keep this commit in the already-elected TC warp path. Nesting
                # another elect_sync around it can hang on control-dependent
                # elect.sync.
                prims.tcgen05_commit(ab_empty_mbar.subview(stage))

    # Signal that the accumulator is fully computed
    if is_tc_warp:
        if prims.elect_sync():
            prims.tcgen05_commit(mbar_mma)

    # Epilogue Warp
    if is_epi_warp:
        # Wait for the accumulator buffer to be full
        while not prims.mbarrier_try_wait_parity(mbar_mma, 0, time_limit=10000000):
            pass
        warpid_in_epi_wg = warp_idx % 4
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

            tmem_x = 2
            shape = "32x32b"
            c_rmem = prims.tcgen05_ld(shape, tmem, num=tmem_x)

            m_id = tx % tmem_num_col
            for i in cutlass.range_constexpr(tmem_x):
                matrix_c_arr[m_id, n + i] = cutlass.Float16(c_rmem[i])

    #  Wait all warps to release TMEM
    prims.barrier_cta_sync(0)

    # Deallocate TMEM
    if is_tc_warp:
        prims.tcgen05_dealloc(tmem_ptr, tmem_num_col)


@cute.jit
def gemm(
    matrix_a: cute.Tensor,
    matrix_b: cute.Tensor,
    matrix_c: cutlass.Array,
    problem_size: cutlass.Constexpr[List[int]],
    num_ab_stage: cutlass.Constexpr[int],
    TILE_M: cutlass.Constexpr[int],
    TILE_K: cutlass.Constexpr[int],
    TILE_N: cutlass.Constexpr[int],
    stream: cuda_driver.CUstream,
):
    # Validate K dimension - must be multiple of TILE_K (64)
    _, _, problem_k = problem_size
    assert problem_k % TILE_K == 0, (
        f"K dimension ({problem_k}) must be a multiple of {TILE_K} (TILE_K)"
    )

    # =========================================================================
    # TMA TENSOR MAP AND BOUNDING BOX
    # =========================================================================
    tma_desc_a = cuda.create_tensor_map_tiled_from_view(
        matrix_a,
        box_dims=(TILE_M, TILE_K),
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    tma_desc_b = cuda.create_tensor_map_tiled_from_view(
        matrix_b, box_dims=(TILE_K, TILE_N), swizzle=cuda.TensorMapSwizzle.s128b
    )

    # Launch the kernel
    block = (256, 1, 1)
    grid = (1, 1, 1)
    gemm_kernel(
        tma_desc_a,
        tma_desc_b,
        matrix_c,
        problem_size,
        num_ab_stage,
        TILE_M,
        TILE_K,
        TILE_N,
    ).launch(grid=grid, block=block, stream=stream)


if __name__ == "__main__":
    M = 128
    N = 128
    K = 4096

    TILE_M = 128
    TILE_K = 64
    TILE_N = 128

    max_smem_capacity_in_bytes = cutlass.memory.get_smem_capacity_in_bytes("sm_100")
    print("Shared memory capacity in bytes: ", max_smem_capacity_in_bytes)
    extra = 4096
    num_ab_stage = (max_smem_capacity_in_bytes - extra) // (
        2 * TILE_M * TILE_K + 2 * TILE_K * TILE_N
    )

    a = torch.randn(M, K, dtype=torch.float16, device="cuda")
    b = torch.randn(N, K, dtype=torch.float16, device="cuda").T
    c = torch.zeros(M, N, dtype=torch.float16, device="cuda")

    a_tensor = cute.runtime.from_dlpack(a)
    b_tensor = cute.runtime.from_dlpack(b)
    c_tensor = cute.runtime.from_dlpack(c)

    print(f"Matrix: {M}x{K} @ {K}x{N} = {M}x{N}")
    print(
        f"num_ab_stage={num_ab_stage}, TILE_M={TILE_M}, TILE_K={TILE_K}, TILE_N={TILE_N}"
    )

    stream = cuda_driver.CUstream(torch.cuda.Stream().cuda_stream)

    # Compile
    keep_ptx_and_sass = ""  # "--keep-ptx --keep-sass"
    print("Compiling...")
    t0 = time.time()
    compiled_fn = cute.compile(
        gemm,
        a_tensor,
        b_tensor,
        c_tensor,
        (M, N, K),
        num_ab_stage,
        TILE_M,
        TILE_K,
        TILE_N,
        stream,
        options=keep_ptx_and_sass,
    )
    print(f"Compile time: {time.time() - t0:.3f}s")

    # Verify correctness
    host_c = torch.zeros(M, N, dtype=torch.float16, device="cuda")
    host_c[:TILE_M, :TILE_N] = a[:TILE_M, :] @ b[:, :TILE_N]
    compiled_fn(a_tensor, b_tensor, c_tensor, stream)
    torch.cuda.synchronize()
    torch.testing.assert_close(c, host_c, atol=1e-03, rtol=1e-03)
    print("Correctness: PASS")

    # gemm(a_tensor, b_tensor, c_tensor, (M, N, K), num_ab_stage, TILE_M, TILE_K, TILE_N, stream)

    # Benchmark
    WARMUP_ITERS, BENCH_ITERS = 10, 100
    args = cutlass.testing.JitArguments(a_tensor, b_tensor, c_tensor, stream)
    avg_us = cutlass.testing.benchmark(
        compiled_fn,
        kernel_arguments=args,
        warmup_iterations=WARMUP_ITERS,
        iterations=BENCH_ITERS,
        use_cuda_graphs=True,
        stream=stream,
        nvtx_tag="gemm_M128_N128_Kany_TN_warpspec_multistage",
    )

    tflops = (2 * M * N * K) / (avg_us * 1e-6) / 1e12

    # Blackwell SM peak: ~15 TFLOPS for FP16 tensor core (single SM)
    peak_tflops_per_sm = 15.0
    utilization_pct = (tflops / peak_tflops_per_sm) * 100

    print(
        f"Time: {avg_us:.2f} us | {tflops:.2f} TFLOPS | Utilization: {utilization_pct:.1f}%"
    )
