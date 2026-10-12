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

"""
Softmax Kernels: 8 Implementation Variants

Direct port of Karpathy's llm.c softmax kernels to cutlass DSL, demonstrating
different optimization strategies for computing softmax on GPU.

Kernel implementations:
1. Naive: One thread per row, sequential loop over C
2. Block-level: Shared memory reductions, one block per row
3. Warp-level: Shuffle reductions, one warp per row (block_size=32)
4. Warp + Shared: Warp shuffles + shared memory for inter-warp reduction
5. Online Naive: Online algorithm, one thread per row (2-pass instead of 3)
6. Online Warp: Online algorithm with warp-level parallelism
7. Large C Optimized: Unrolling for memory parallelism on large vocabularies
8. Online Warp + Shared: Online algorithm with warp shuffles + shared memory

cutlass Limitations vs Original CUDA:
- No __device__ functions: Karpathy uses warpReduceMax/Sum helpers; we inline everything
- No early return: Can't use `return` for early exit in kernels, must use if/else
- No custom structs: Karpathy's SumMax struct for (max, sum) pairs; we use separate variables
- No cooperative groups: Kernel 6 approximates cg::reduce pattern manually

Reference: https://github.com/karpathy/llm.c/blob/master/dev/cuda/softmax_forward.cu
Paper (online softmax): http://arxiv.org/abs/1805.02867
"""

from typing import Callable

import cutlass
import cutlass.cute as cute
import torch
from cutlass.experimental import primitives as prims


# =============================================================================
# Constants for different kernels
# =============================================================================

WARP_SIZE = 32

# Kernel 2 constants
KERNEL2_BLOCK_SIZE = 128

# Kernel 4 constants
KERNEL4_BLOCK_SIZE = 128
KERNEL4_WARPS_PER_BLOCK = KERNEL4_BLOCK_SIZE // WARP_SIZE

# Kernel 6 constants
KERNEL6_BLOCK_SIZE = 128

# Kernel 7 constants
KERNEL7_BLOCK_SIZE = 256
KERNEL7_WARPS_PER_BLOCK = KERNEL7_BLOCK_SIZE // WARP_SIZE
KERNEL7_UNROLL_FACTOR = 8

# Kernel 8 constants
KERNEL8_BLOCK_SIZE = 256
KERNEL8_WARPS_PER_BLOCK = KERNEL8_BLOCK_SIZE // WARP_SIZE


# =============================================================================
# Kernel 1: Naive Implementation
# =============================================================================


@cute.kernel
def softmax_forward_kernel1(
    inp_arr: cutlass.Array,
    out_arr: cutlass.Array,
    N: cutlass.Constexpr,
):
    """Naive softmax kernel: one thread processes one row."""
    tx, _, _ = cute.arch.thread_idx()
    bx, _, _ = cute.arch.block_idx()
    bdx, _, _ = cute.arch.block_dim()

    i = bx * bdx + tx

    C = inp_arr.shape[1]  # Runtime value from tensor shape

    if i < N:
        maxval = -3.4028235e38
        for j in range(C):
            val = inp_arr[i, j]
            maxval = cute.math.max(maxval, val)

        sumval = 0.0
        for j in range(C):
            exp_val = cute.math.exp(inp_arr[i, j] - maxval, fastmath=True)
            out_arr[i, j] = exp_val
            sumval = sumval + exp_val

        for j in range(C):
            out_arr[i, j] = out_arr[i, j] / sumval


@cute.jit
def softmax_forward1(
    inp_tensor: cute.Tensor,
    out_tensor: cute.Tensor,
    N: cutlass.Constexpr,
    block_size: cutlass.Constexpr,
):
    grid_size = (N + block_size - 1) // block_size
    softmax_forward_kernel1(inp_tensor, out_tensor, N).launch(
        grid=(grid_size, 1, 1),
        block=(block_size, 1, 1),
    )


# =============================================================================
# Kernel 2: Block-level with Shared Memory Reductions
# =============================================================================


@cute.kernel
def softmax_forward_kernel2(
    inp_arr: cutlass.Array,
    out_arr: cutlass.Array,
    N: cutlass.Constexpr,
    C: cutlass.Constexpr,
):
    """Block-level softmax with shared memory reductions."""
    shared = cutlass.Array(
        cutlass.Float32, KERNEL2_BLOCK_SIZE, space=cutlass.AddressSpace.smem
    )

    idx, _, _ = cute.arch.block_idx()
    tid, _, _ = cute.arch.thread_idx()

    # Find max
    maxval = -3.4028235e38
    for i in cutlass.range_constexpr(0, C, KERNEL2_BLOCK_SIZE):
        col = i + tid
        if col < C:
            maxval = cute.math.max(maxval, inp_arr[idx, col])

    shared[tid] = maxval

    for stride in [64, 32, 16, 8, 4, 2, 1]:
        prims.barrier_cta_sync(0)
        if stride < KERNEL2_BLOCK_SIZE and tid < stride:
            shared[tid] = cute.math.max(shared[tid], shared[tid + stride])

    prims.barrier_cta_sync(0)
    offset = shared[0]

    # Compute exp
    for i in cutlass.range_constexpr(0, C, KERNEL2_BLOCK_SIZE):
        col = i + tid
        if col < C:
            diff = inp_arr[idx, col] - offset
            exp_val = cute.math.exp(diff, fastmath=True)
            out_arr[idx, col] = exp_val

    prims.barrier_cta_sync(0)

    # Sum
    sumval = 0.0
    for i in cutlass.range_constexpr(0, C, KERNEL2_BLOCK_SIZE):
        col = i + tid
        if col < C:
            sumval = sumval + out_arr[idx, col]

    shared[tid] = sumval

    for stride in [64, 32, 16, 8, 4, 2, 1]:
        prims.barrier_cta_sync(0)
        if stride < KERNEL2_BLOCK_SIZE and tid < stride:
            shared[tid] = shared[tid] + shared[tid + stride]

    prims.barrier_cta_sync(0)
    total_sum = shared[0]

    # Normalize
    for i in cutlass.range_constexpr(0, C, KERNEL2_BLOCK_SIZE):
        col = i + tid
        if col < C:
            out_arr[idx, col] = out_arr[idx, col] / total_sum


# =============================================================================
# Kernel 3: Warp-level with Shuffle Reductions
# =============================================================================


@cute.kernel
def softmax_forward_kernel3(
    inp_arr: cutlass.Array,
    out_arr: cutlass.Array,
    N: cutlass.Constexpr,
):
    """Warp-level softmax with shuffle reductions."""
    idx, _, _ = cute.arch.block_idx()
    tid, _, _ = cute.arch.thread_idx()

    C = inp_arr.shape[1]

    # Find max
    maxval = -3.4028235e38
    for i in range(0, C, WARP_SIZE):
        col = i + tid
        if col < C:
            maxval = cute.math.max(maxval, inp_arr[idx, col])

    for offset in [16, 8, 4, 2, 1]:
        other = cute.arch.shuffle_sync_down(maxval, offset)
        maxval = cute.math.max(maxval, other)

    offset = cute.arch.shuffle_sync(maxval, 0)

    # Compute exp
    for i in range(0, C, WARP_SIZE):
        col = i + tid
        if col < C:
            diff = inp_arr[idx, col] - offset
            exp_val = cute.math.exp(diff, fastmath=True)
            out_arr[idx, col] = exp_val

    # Sum
    sumval = 0.0
    for i in range(0, C, WARP_SIZE):
        col = i + tid
        if col < C:
            sumval = sumval + out_arr[idx, col]

    for offset in [16, 8, 4, 2, 1]:
        other = cute.arch.shuffle_sync_down(sumval, offset)
        sumval = sumval + other

    total_sum = cute.arch.shuffle_sync(sumval, 0)

    # Normalize
    for i in range(0, C, WARP_SIZE):
        col = i + tid
        if col < C:
            out_arr[idx, col] = out_arr[idx, col] / total_sum


@cute.jit
def softmax_forward3(
    inp_tensor: cute.Tensor,
    out_tensor: cute.Tensor,
    N: cutlass.Constexpr,
):
    block_size = WARP_SIZE
    grid_size = N
    softmax_forward_kernel3(inp_tensor, out_tensor, N).launch(
        grid=(grid_size, 1, 1),
        block=(block_size, 1, 1),
    )


# =============================================================================
# Kernel 4: Warp + Shared Memory
# =============================================================================


@cute.kernel
def softmax_forward_kernel4(
    inp_arr: cutlass.Array,
    out_arr: cutlass.Array,
    N: cutlass.Constexpr,
    C: cutlass.Constexpr,
):
    """Warp + shared memory softmax kernel."""
    max_or_sum_storage = cutlass.Array(
        cutlass.Float32, KERNEL4_WARPS_PER_BLOCK, space=cutlass.AddressSpace.smem
    )

    idx, _, _ = cute.arch.block_idx()
    tid, _, _ = cute.arch.thread_idx()

    warp_id = tid // WARP_SIZE
    lane_id = tid % WARP_SIZE

    # Find max
    maxval = -3.4028235e38
    for i in cutlass.range_constexpr(0, C, KERNEL4_BLOCK_SIZE):
        col = i + tid
        if col < C:
            maxval = cute.math.max(maxval, inp_arr[idx, col])

    for offset in [16, 8, 4, 2, 1]:
        other = cute.arch.shuffle_sync_down(maxval, offset)
        maxval = cute.math.max(maxval, other)

    if lane_id == 0:
        max_or_sum_storage[warp_id] = maxval

    prims.barrier_cta_sync(0)

    if tid == 0:
        global_max = max_or_sum_storage[0]
        for w in cutlass.range_constexpr(1, KERNEL4_WARPS_PER_BLOCK):
            global_max = cute.math.max(global_max, max_or_sum_storage[w])
        max_or_sum_storage[0] = global_max

    prims.barrier_cta_sync(0)
    offset = max_or_sum_storage[0]

    # Compute exp
    for i in cutlass.range_constexpr(0, C, KERNEL4_BLOCK_SIZE):
        col = i + tid
        if col < C:
            diff = inp_arr[idx, col] - offset
            exp_val = cute.math.exp(diff, fastmath=True)
            out_arr[idx, col] = exp_val

    # Sum
    sumval = 0.0
    for i in cutlass.range_constexpr(0, C, KERNEL4_BLOCK_SIZE):
        col = i + tid
        if col < C:
            sumval = sumval + out_arr[idx, col]

    for offset in [16, 8, 4, 2, 1]:
        other = cute.arch.shuffle_sync_down(sumval, offset)
        sumval = sumval + other

    if lane_id == 0:
        max_or_sum_storage[warp_id] = sumval

    prims.barrier_cta_sync(0)

    if tid == 0:
        global_sum = max_or_sum_storage[0]
        for w in cutlass.range_constexpr(1, KERNEL4_WARPS_PER_BLOCK):
            global_sum = global_sum + max_or_sum_storage[w]
        max_or_sum_storage[0] = global_sum

    prims.barrier_cta_sync(0)
    total_sum = max_or_sum_storage[0]

    # Normalize
    for i in cutlass.range_constexpr(0, C, KERNEL4_BLOCK_SIZE):
        col = i + tid
        if col < C:
            out_arr[idx, col] = out_arr[idx, col] / total_sum


# =============================================================================
# Kernel 5: Online Naive Implementation
# =============================================================================


@cute.kernel
def softmax_forward_online_kernel1(
    inp_arr: cutlass.Array,
    out_arr: cutlass.Array,
    N: cutlass.Constexpr,
):
    """Online softmax kernel: naive version with one thread per row."""
    tx, _, _ = cute.arch.thread_idx()
    bx, _, _ = cute.arch.block_idx()
    bdx, _, _ = cute.arch.block_dim()

    i = bx * bdx + tx

    C = inp_arr.shape[1]  # Runtime value from tensor shape

    if i < N:
        maxval = -3.4028235e38
        sumval = 0.0

        for j in range(C):
            current_val = inp_arr[i, j]
            maxval_prev = maxval

            if current_val > maxval:
                maxval = current_val
                scale = cute.math.exp(maxval_prev - maxval, fastmath=True)
                sumval = sumval * scale + 1.0
            else:
                diff = current_val - maxval
                exp_val = cute.math.exp(diff, fastmath=True)
                sumval = sumval + exp_val

        for j in range(C):
            diff = inp_arr[i, j] - maxval
            exp_val = cute.math.exp(diff, fastmath=True)
            out_arr[i, j] = exp_val / sumval


@cute.jit
def softmax_forward_online1(
    inp_tensor: cute.Tensor,
    out_tensor: cute.Tensor,
    N: cutlass.Constexpr,
    block_size: cutlass.Constexpr,
):
    grid_size = (N + block_size - 1) // block_size
    softmax_forward_online_kernel1(inp_tensor, out_tensor, N).launch(
        grid=(grid_size, 1, 1),
        block=(block_size, 1, 1),
    )


# =============================================================================
# Kernel 6: Online Warp-level
# =============================================================================


@cute.kernel
def softmax_forward_online_kernel2(
    inp_arr: cutlass.Array,
    out_arr: cutlass.Array,
    N: cutlass.Constexpr,
    C: cutlass.Constexpr,
):
    """Online softmax with warp-level parallelism."""
    tx, _, _ = cute.arch.thread_idx()
    bx, _, _ = cute.arch.block_idx()

    warps_per_block = KERNEL6_BLOCK_SIZE // WARP_SIZE
    warp_id_in_block = tx // WARP_SIZE
    lane_id = tx % WARP_SIZE

    row_idx = bx * warps_per_block + warp_id_in_block

    if row_idx < N:
        maxval = -3.4028235e38
        sumval = 0.0

        for i in cutlass.range_constexpr(0, C, WARP_SIZE):
            col = i + lane_id
            if col < C:
                current_val = inp_arr[row_idx, col]

                if current_val > maxval:
                    scale = cute.math.exp(maxval - current_val, fastmath=True)
                    sumval = sumval * scale + 1.0
                    maxval = current_val
                else:
                    diff = current_val - maxval
                    exp_val = cute.math.exp(diff, fastmath=True)
                    sumval = sumval + exp_val

        # Warp reduction of (maxval, sumval) pairs
        for offset in [16, 8, 4, 2, 1]:
            other_max = cute.arch.shuffle_sync_down(maxval, offset)
            other_sum = cute.arch.shuffle_sync_down(sumval, offset)

            if other_max > maxval:
                scale = cute.math.exp(maxval - other_max, fastmath=True)
                sumval = other_sum + sumval * scale
                maxval = other_max
            else:
                scale = cute.math.exp(other_max - maxval, fastmath=True)
                sumval = sumval + other_sum * scale

        maxval = cute.arch.shuffle_sync(maxval, 0)
        sumval = cute.arch.shuffle_sync(sumval, 0)

        for i in cutlass.range_constexpr(0, C, WARP_SIZE):
            col = i + lane_id
            if col < C:
                diff = inp_arr[row_idx, col] - maxval
                exp_val = cute.math.exp(diff, fastmath=True)
                out_arr[row_idx, col] = exp_val / sumval


@cute.jit
def softmax_forward_online2(
    inp_tensor: cute.Tensor,
    out_tensor: cute.Tensor,
    N: cutlass.Constexpr,
    C: cutlass.Constexpr,
):
    warps_per_block = KERNEL6_BLOCK_SIZE // WARP_SIZE
    grid_size = (N + warps_per_block - 1) // warps_per_block
    softmax_forward_online_kernel2(inp_tensor, out_tensor, N, C).launch(
        grid=(grid_size, 1, 1),
        block=(KERNEL6_BLOCK_SIZE, 1, 1),
    )


# =============================================================================
# Kernel 7: Optimized for Large C with Unrolling
# =============================================================================


@cute.kernel
def softmax_forward_kernel7(
    inp_arr: cutlass.Array,
    out_arr: cutlass.Array,
    N: cutlass.Constexpr,
    C: cutlass.Constexpr,
):
    """Optimized softmax kernel for large C with advanced unrolling."""
    maxvals = cutlass.Array(
        cutlass.Float32, KERNEL7_WARPS_PER_BLOCK, space=cutlass.AddressSpace.smem
    )
    sumvals = cutlass.Array(
        cutlass.Float32, KERNEL7_WARPS_PER_BLOCK, space=cutlass.AddressSpace.smem
    )

    idx, _, _ = cute.arch.block_idx()
    tid, _, _ = cute.arch.thread_idx()

    warp_id = tid // WARP_SIZE
    lane_id = tid % WARP_SIZE

    # Find max with unrolling
    maxval = -3.4028235e38

    for i in cutlass.range_constexpr(0, C, KERNEL7_BLOCK_SIZE * KERNEL7_UNROLL_FACTOR):
        for u in cutlass.range_constexpr(KERNEL7_UNROLL_FACTOR):
            col = i + u * KERNEL7_BLOCK_SIZE + tid
            if col < C:
                val = inp_arr[idx, col]
                maxval = cute.math.max(maxval, val)

    for offset in [16, 8, 4, 2, 1]:
        other = cute.arch.shuffle_sync_down(maxval, offset)
        maxval = cute.math.max(maxval, other)

    if lane_id == 0:
        maxvals[warp_id] = maxval

    prims.barrier_cta_sync(0)

    if tid == 0:
        global_max = maxvals[0]
        for w in cutlass.range_constexpr(1, KERNEL7_WARPS_PER_BLOCK):
            global_max = cute.math.max(global_max, maxvals[w])
        maxvals[0] = global_max

    prims.barrier_cta_sync(0)
    offset = maxvals[0]

    # Compute exp and sum with unrolling
    sumval = 0.0

    for i in cutlass.range_constexpr(0, C, KERNEL7_BLOCK_SIZE * KERNEL7_UNROLL_FACTOR):
        for u in cutlass.range_constexpr(KERNEL7_UNROLL_FACTOR):
            col = i + u * KERNEL7_BLOCK_SIZE + tid
            safe_col = col if col < C else C - 1
            val = inp_arr[idx, safe_col]
            if col < C:
                diff = val - offset
                exp_val = cute.math.exp(diff, fastmath=True)
                out_arr[idx, col] = exp_val
                sumval = sumval + exp_val

    for offset_val in [16, 8, 4, 2, 1]:
        other = cute.arch.shuffle_sync_down(sumval, offset_val)
        sumval = sumval + other

    if lane_id == 0:
        sumvals[warp_id] = sumval

    prims.barrier_cta_sync(0)

    if tid == 0:
        global_sum = sumvals[0]
        for w in cutlass.range_constexpr(1, KERNEL7_WARPS_PER_BLOCK):
            global_sum = global_sum + sumvals[w]
        sumvals[0] = global_sum

    prims.barrier_cta_sync(0)
    total_sum = sumvals[0]

    # Normalize with unrolling
    for i in cutlass.range_constexpr(0, C, KERNEL7_BLOCK_SIZE * KERNEL7_UNROLL_FACTOR):
        for u in cutlass.range_constexpr(KERNEL7_UNROLL_FACTOR):
            col = i + u * KERNEL7_BLOCK_SIZE + tid
            if col < C:
                out_arr[idx, col] = out_arr[idx, col] / total_sum


# =============================================================================
# Kernel 8: Online Warp + Shared Memory
# =============================================================================


@cute.kernel
def softmax_forward_online_kernel8(
    inp_arr: cutlass.Array,
    out_arr: cutlass.Array,
    N: cutlass.Constexpr,
    C: cutlass.Constexpr,
):
    """Online softmax with warp shuffles + shared memory for arbitrary block sizes."""
    shared_maxvals = cutlass.Array(
        cutlass.Float32, KERNEL8_WARPS_PER_BLOCK, space=cutlass.AddressSpace.smem
    )
    shared_sumvals = cutlass.Array(
        cutlass.Float32, KERNEL8_WARPS_PER_BLOCK, space=cutlass.AddressSpace.smem
    )

    idx, _, _ = cute.arch.block_idx()
    tid, _, _ = cute.arch.thread_idx()

    warp_id = tid // WARP_SIZE
    lane_id = tid % WARP_SIZE

    # Online algorithm
    maxval = -3.4028235e38
    sumval = 0.0

    for i in cutlass.range_constexpr(0, C, KERNEL8_BLOCK_SIZE):
        col = i + tid
        if col < C:
            current_val = inp_arr[idx, col]

            if current_val > maxval:
                scale = cute.math.exp(maxval - current_val, fastmath=True)
                sumval = sumval * scale + 1.0
                maxval = current_val
            else:
                diff = current_val - maxval
                exp_val = cute.math.exp(diff, fastmath=True)
                sumval = sumval + exp_val

    # Intra-warp reduction
    for offset in [16, 8, 4, 2, 1]:
        other_max = cute.arch.shuffle_sync_down(maxval, offset)
        other_sum = cute.arch.shuffle_sync_down(sumval, offset)

        if other_max > maxval:
            scale = cute.math.exp(maxval - other_max, fastmath=True)
            sumval = other_sum + sumval * scale
            maxval = other_max
        else:
            scale = cute.math.exp(other_max - maxval, fastmath=True)
            sumval = sumval + other_sum * scale

    # Inter-warp reduction
    if lane_id == 0:
        shared_maxvals[warp_id] = maxval
        shared_sumvals[warp_id] = sumval

    prims.barrier_cta_sync(0)

    if tid == 0:
        global_max = shared_maxvals[0]
        global_sum = shared_sumvals[0]

        for w in cutlass.range_constexpr(1, KERNEL8_WARPS_PER_BLOCK):
            other_max = shared_maxvals[w]
            other_sum = shared_sumvals[w]

            if other_max > global_max:
                scale = cute.math.exp(global_max - other_max, fastmath=True)
                global_sum = other_sum + global_sum * scale
                global_max = other_max
            else:
                scale = cute.math.exp(other_max - global_max, fastmath=True)
                global_sum = global_sum + other_sum * scale

        shared_maxvals[0] = global_max
        shared_sumvals[0] = global_sum

    prims.barrier_cta_sync(0)

    final_max = shared_maxvals[0]
    final_sum = shared_sumvals[0]

    # Compute final output
    for i in cutlass.range_constexpr(0, C, KERNEL8_BLOCK_SIZE):
        col = i + tid
        if col < C:
            diff = inp_arr[idx, col] - final_max
            exp_val = cute.math.exp(diff, fastmath=True)
            out_arr[idx, col] = exp_val / final_sum


# =============================================================================
# Unified Launcher for Block-per-Row Kernels (Metaprogramming Pattern)
# =============================================================================
#
# Kernels 2, 4, 7, and 8 share the same launch pattern:
# - One block per row (grid = N)
# - Same kernel signature: (inp, out, N, C)
# - Only differ in block size
#
# Instead of 4 separate @cute.jit launchers, we use a single generic launcher
# that accepts the kernel as a compile-time constant (Constexpr[Callable]).
# This demonstrates cutlass's metaprogramming capabilities and reduces code duplication.


@cute.jit
def softmax_block_per_row(
    inp_tensor: cute.Tensor,
    out_tensor: cute.Tensor,
    N: cutlass.Constexpr,
    C: cutlass.Constexpr,
    Kernel: cutlass.Constexpr[Callable],
    BlockSize: cutlass.Constexpr,
):
    """Generic launcher for block-per-row softmax kernels.

    This unified launcher works with any kernel that:
    - Takes (inp, out, N, C) as arguments
    - Uses one block per row (grid = N)

    The kernel and block size are compile-time constants, so the compiler
    generates specialized code for each (Kernel, BlockSize) combination.
    """
    Kernel(inp_tensor, out_tensor, N, C).launch(
        grid=(N, 1, 1),
        block=(BlockSize, 1, 1),
    )


# =============================================================================
# Unified Test Function
# =============================================================================


def run_kernel(kernel_name, launch_func, inp, N, C, block_size=None):
    """Run a single kernel and return the output."""
    out = torch.zeros_like(inp)
    inp_tensor = cute.runtime.from_dlpack(inp, assumed_align=16)
    out_tensor = cute.runtime.from_dlpack(out, assumed_align=16)

    if block_size is not None:
        launch_func(inp_tensor, out_tensor, N, C, block_size)
    else:
        launch_func(inp_tensor, out_tensor, N, C)

    return out


def run_softmax_tests():
    """Test all 8 softmax kernel variants for correctness against PyTorch reference."""
    print("=" * 80)
    print("SOFTMAX KERNELS - CORRECTNESS VERIFICATION")
    print("=" * 80)
    print()

    # Define kernels with their launch functions and descriptions
    # Kernels 2, 4, 7, 8 use the unified softmax_block_per_row launcher (metaprogramming pattern)
    # Kernels 1, 3, 5, 6 have unique launch patterns and keep dedicated launchers
    kernels = [
        (
            "Kernel 1",
            "Naive (1 thread/row)",
            lambda i, o, N, C: softmax_forward1(i, o, N, 128),
            True,
        ),
        (
            "Kernel 2",
            "Block + Shared Memory",
            lambda i, o, N, C: softmax_block_per_row(
                i, o, N, C, softmax_forward_kernel2, KERNEL2_BLOCK_SIZE
            ),
            False,
        ),
        (
            "Kernel 3",
            "Warp + Shuffle (block=32)",
            lambda i, o, N, C: softmax_forward3(i, o, N),
            False,
        ),
        (
            "Kernel 4",
            "Warp + Shared Memory",
            lambda i, o, N, C: softmax_block_per_row(
                i, o, N, C, softmax_forward_kernel4, KERNEL4_BLOCK_SIZE
            ),
            False,
        ),
        (
            "Kernel 5",
            "Online Naive",
            lambda i, o, N, C: softmax_forward_online1(i, o, N, 128),
            True,
        ),
        (
            "Kernel 6",
            "Online Warp",
            lambda i, o, N, C: softmax_forward_online2(i, o, N, C),
            False,
        ),
        (
            "Kernel 7",
            "Large C Optimized",
            lambda i, o, N, C: softmax_block_per_row(
                i, o, N, C, softmax_forward_kernel7, KERNEL7_BLOCK_SIZE
            ),
            False,
        ),
        (
            "Kernel 8",
            "Online Warp + Shared",
            lambda i, o, N, C: softmax_block_per_row(
                i, o, N, C, softmax_forward_online_kernel8, KERNEL8_BLOCK_SIZE
            ),
            False,
        ),
    ]

    # Problem sizes for testing. Karpathy's llm.c uses B=8, T=1024, C=50257 (GPT-2 vocab)
    # which gives N=B*T=8192 rows. We use smaller sizes here for quick verification.
    test_configs = [
        (32, 256),  # Default: 32 rows, 256 columns
        # (8192, 50257),  # Karpathy's llm.c: B=8, T=1024, C=50257 (GPT-2 vocab)
    ]

    # Results tracking
    all_passed = True
    results_table = []

    for N, C in test_configs:
        print(f"\n{'=' * 80}")
        print(f"Testing Problem Size: N={N}, C={C}")
        print(f"{'=' * 80}")

        # Create input tensor (same for all kernels)
        torch.manual_seed(42)
        inp = torch.randn(N, C, dtype=torch.float32, device="cuda")

        # Compute PyTorch reference
        reference = torch.nn.functional.softmax(inp, dim=-1)

        config_results = {"config": (N, C), "results": {}}

        for kernel_name, description, launch_func, _ in kernels:
            try:
                # Create output tensor
                out = torch.zeros_like(inp)
                inp_tensor = cute.runtime.from_dlpack(inp, assumed_align=16)
                out_tensor = cute.runtime.from_dlpack(out, assumed_align=16)

                # Run the kernel
                launch_func(inp_tensor, out_tensor, N, C)

                # Verify results
                # Use slightly looser tolerance for large C and kernel 7
                atol = 1e-4 if C >= 1024 or kernel_name == "Kernel 7" else 1e-5
                rtol = 1e-4 if C >= 1024 or kernel_name == "Kernel 7" else 1e-5

                torch.testing.assert_close(out, reference, atol=atol, rtol=rtol)

                # Compute max absolute error for reporting
                max_error = (out - reference).abs().max().item()

                print(
                    f"  {kernel_name:10s} ({description:25s}): PASSED (max_err={max_error:.2e})"
                )
                config_results["results"][kernel_name] = ("PASSED", max_error)

            except AssertionError as e:
                max_error = (out - reference).abs().max().item()
                print(
                    f"  {kernel_name:10s} ({description:25s}): FAILED (max_err={max_error:.2e})"
                )
                config_results["results"][kernel_name] = ("FAILED", max_error)
                all_passed = False

            except Exception as e:
                print(f"  {kernel_name:10s} ({description:25s}): ERROR ({str(e)[:50]})")
                config_results["results"][kernel_name] = ("ERROR", str(e))
                all_passed = False

        results_table.append(config_results)

    # Print summary
    print(f"\n{'=' * 80}")
    print("SUMMARY")
    print(f"{'=' * 80}")

    # Print header
    header = f"{'Config':>15s}"
    for kernel_name, _, _, _ in kernels:
        header += f" | {kernel_name:>10s}"
    print(header)
    print("-" * len(header))

    # Print results
    for config_result in results_table:
        N, C = config_result["config"]
        row = f"{'N=' + str(N) + ',C=' + str(C):>15s}"
        for kernel_name, _, _, _ in kernels:
            result = config_result["results"].get(kernel_name, ("N/A", 0))
            if result[0] == "PASSED":
                row += f" | {'PASS':>10s}"
            elif result[0] == "FAILED":
                row += f" | {'FAIL':>10s}"
            else:
                row += f" | {'ERR':>10s}"
        print(row)

    print()
    if all_passed:
        print("ALL KERNELS PASSED ALL TESTS!")
    else:
        print("SOME TESTS FAILED - See details above")

    return all_passed


# =============================================================================
# Profiling with nsight-python
# =============================================================================

try:
    import nsight

    NSIGHT_AVAILABLE = True
except ImportError:
    NSIGHT_AVAILABLE = False


def compute_bandwidth_gbs(time_ns: float, n: int, c: int) -> float:
    """
    Compute memory bandwidth in GB/s for softmax.

    Softmax reads input (N*C floats) and writes output (N*C floats).
    Total memory: 2 * N * C * 4 bytes (float32).
    """
    total_bytes = 2 * n * c * 4  # read + write, float32
    bandwidth_gbs = total_bytes / (time_ns / 1e9) / 1e9
    return bandwidth_gbs


def profile_softmax():
    """
    Profile all softmax kernels using nsight-python.

    This function uses Nsight Compute to collect detailed GPU metrics.
    Run with: python softmax.py --profile

    Requires nsight-python: pip install nsight-python
    Or clone from: https://github.com/NVIDIA/nsight-python
    """
    if not NSIGHT_AVAILABLE:
        print("ERROR: nsight-python not available.")
        print("Install with: pip install nsight-python")
        print("Or add the nsight-python checkout to PYTHONPATH.")
        return None

    # Multiple problem sizes for comparison
    configs = [
        (32, 256),  # Small
        (64, 512),  # Medium
        (128, 1024),  # Larger
    ]

    @nsight.analyze.plot(
        "softmax_bandwidth.png",
        metric="compute_bandwidth_gbs",
        ylabel="Memory Bandwidth (GB/s)",
    )
    @nsight.analyze.kernel(configs=configs, runs=5, derive_metric=compute_bandwidth_gbs)
    def benchmark_all_kernels(n: int, c: int):
        """Benchmark all softmax implementations."""
        torch.manual_seed(42)
        inp = torch.randn(n, c, dtype=torch.float32, device="cuda")
        out = torch.zeros_like(inp)

        inp_tensor = cute.runtime.from_dlpack(inp, assumed_align=16)
        out_tensor = cute.runtime.from_dlpack(out, assumed_align=16)

        # PyTorch baseline
        with nsight.annotate("PyTorch"):
            out.copy_(torch.nn.functional.softmax(inp, dim=-1))

        # Kernel 1: Naive (1 thread/row)
        with nsight.annotate("K1-Naive"):
            softmax_forward1(inp_tensor, out_tensor, n, 128)

        # Kernel 2: Block + Shared Memory (via unified launcher)
        with nsight.annotate("K2-Block"):
            softmax_block_per_row(
                inp_tensor,
                out_tensor,
                n,
                c,
                softmax_forward_kernel2,
                KERNEL2_BLOCK_SIZE,
            )

        # Kernel 3: Warp + Shuffle
        with nsight.annotate("K3-Warp"):
            softmax_forward3(inp_tensor, out_tensor, n)

        # Kernel 4: Warp + Shared Memory (via unified launcher)
        with nsight.annotate("K4-WarpShared"):
            softmax_block_per_row(
                inp_tensor,
                out_tensor,
                n,
                c,
                softmax_forward_kernel4,
                KERNEL4_BLOCK_SIZE,
            )

        # Kernel 5: Online Naive
        with nsight.annotate("K5-OnlineNaive"):
            softmax_forward_online1(inp_tensor, out_tensor, n, 128)

        # Kernel 6: Online Warp
        with nsight.annotate("K6-OnlineWarp"):
            softmax_forward_online2(inp_tensor, out_tensor, n, c)

        # Kernel 7: Large C Optimized (via unified launcher)
        with nsight.annotate("K7-LargeC"):
            softmax_block_per_row(
                inp_tensor,
                out_tensor,
                n,
                c,
                softmax_forward_kernel7,
                KERNEL7_BLOCK_SIZE,
            )

        # Kernel 8: Online Warp + Shared (via unified launcher)
        with nsight.annotate("K8-OnlineWarpShared"):
            softmax_block_per_row(
                inp_tensor,
                out_tensor,
                n,
                c,
                softmax_forward_online_kernel8,
                KERNEL8_BLOCK_SIZE,
            )

    print("=" * 80)
    print("SOFTMAX KERNELS - NSIGHT PROFILING")
    print("=" * 80)
    print(f"Problem sizes: {configs}")
    print()

    result = benchmark_all_kernels()

    # Print results with bandwidth
    df = result.to_dataframe()
    print(df[["Annotation", "n", "c", "Metric", "AvgValue"]].to_string(index=False))
    print()
    print("Plot saved to: softmax_bandwidth.png")

    return result


if __name__ == "__main__":
    import sys

    if not torch.cuda.is_available():
        raise RuntimeError("CUDA is required to run this example")

    if "--profile" in sys.argv:
        # Run profiling mode with nsight-python
        profile_softmax()
    else:
        # Run correctness tests
        success = run_softmax_tests()
        print()
        print("PASS" if success else "FAIL")
