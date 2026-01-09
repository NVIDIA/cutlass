# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
Hierarchical Reduction Utilities for CuTe-DSL Kernels
=====================================================

This module provides reusable reduction primitives for GPU kernels that need to
reduce values across warps, thread blocks, and clusters (SM90+).

Overview
--------
GPU reductions typically follow a hierarchical pattern:

1. **Warp Reduction**: Threads within a warp reduce using shuffle instructions.
   Use `cute.arch.warp_reduction()` from the CuTe-DSL library.

2. **Block Reduction**: Multiple warps within a block reduce using shared memory.
   Use `block_reduce()` from this module.

3. **Cluster Reduction** (SM90+): Multiple CTAs in a cluster reduce using
   distributed shared memory and mbarrier synchronization.
   Use `cluster_reduce()` from this module.

4. **Row Reduction**: Orchestrates all levels based on problem configuration.
   Use `row_reduce()` from this module.

Shared Memory Buffer Layout Assumptions
---------------------------------------

For `block_reduce`:
    - Buffer shape: (rows_per_block, warps_per_row)
    - Each warp's lane 0 writes its reduced value to buffer[row_idx, col_idx]
    - Thread mapping: row_idx = warp_idx // warps_per_row
                      col_idx = warp_idx % warps_per_row

    Example for 8 warps, 2 rows, 4 warps per row:
        Warp 0 -> buffer[0, 0]    Warp 4 -> buffer[1, 0]
        Warp 1 -> buffer[0, 1]    Warp 5 -> buffer[1, 1]
        Warp 2 -> buffer[0, 2]    Warp 6 -> buffer[1, 2]
        Warp 3 -> buffer[0, 3]    Warp 7 -> buffer[1, 3]

For `cluster_reduce`:
    - Buffer shape: (rows_per_block, (warps_per_row, cluster_n))
    - The second dimension is hierarchical: (local_warp_slot, cta_rank)
    - Each CTA contributes to its own slot in the cluster dimension

    Example for cluster_n=4, 2 warps per row:
        CTA 0, Warp 0 -> buffer[row, (0, 0)]
        CTA 0, Warp 1 -> buffer[row, (1, 0)]
        CTA 1, Warp 0 -> buffer[row, (0, 1)]
        CTA 1, Warp 1 -> buffer[row, (1, 1)]
        ... etc for CTAs 2, 3

Mbarrier Requirements (Cluster Reduction)
-----------------------------------------
For cluster reduction, the caller must:
1. Allocate an mbarrier in shared memory
2. Initialize it with `cute.arch.mbarrier_init(mbar_ptr, thread_count)`
3. Pass the mbarrier pointer to `cluster_reduce()`

The cluster_reduce function handles:
- Setting up the expected transaction count
- Performing async cross-CTA stores
- Waiting for all stores to complete

Usage Example
-------------

.. code-block:: python

    from reduce import row_reduce, block_reduce, cluster_reduce

    @cute.jit
    def my_kernel(...):
        # Allocate shared memory for reduction
        # Shape depends on warps_per_row and cluster_n
        if cluster_n > 1:
            reduction_buffer = cute.make_smem_tensor(
                cute.make_layout((rows_per_block, (warps_per_row, cluster_n))),
                Float32
            )
        else:
            reduction_buffer = cute.make_smem_tensor(
                cute.make_layout((rows_per_block, warps_per_row)),
                Float32
            )

        # Perform row reduction
        result = row_reduce(
            tensor_ssa,
            cute.ReductionOp.ADD,
            threads_per_row,
            reduction_buffer,
            mbar_ptr,
            cluster_n,
            init_val=Float32(0.0)
        )

References
----------
The cluster synchronization primitives (set_block_rank, store_shared_remote)
are inspired by Quack: https://github.com/Dao-AILab/quack
"""

import operator
from collections.abc import Callable

import cutlass
import cutlass.cute as cute
from cutlass import Float32, Int32
from cutlass._mlir.dialects import llvm
from cutlass.cutlass_dsl import T, dsl_user_op


# =============================================================================
# Inline PTX Operations for Cluster Communication
# =============================================================================
#
# These operations enable cross-CTA communication within a cluster (SM90+).
# They use inline PTX assembly for functionality not yet exposed in MLIR.
# =============================================================================


@dsl_user_op
def set_block_rank(
    smem_ptr: cute.Pointer, peer_cta_rank_in_cluster: Int32, *, loc=None, ip=None
) -> Int32:
    """
    Map a shared memory pointer to the equivalent address in another CTA's
    shared memory within the same cluster.

    This uses the PTX `mapa.shared::cluster` instruction to translate a local
    shared memory address to the corresponding address in a peer CTA's shared
    memory space.

    Args:
        smem_ptr: Pointer to local shared memory
        peer_cta_rank_in_cluster: Target CTA's rank within the cluster (0 to cluster_size-1)

    Returns:
        Int32 representing the mapped address in the peer CTA's shared memory

    Note:
        This operation requires SM90+ with cluster support enabled.
        The cluster must be launched with the appropriate cluster dimensions.
    """
    smem_ptr_i32 = smem_ptr.toint(loc=loc, ip=ip).ir_value()
    return Int32(
        llvm.inline_asm(
            T.i32(),
            [smem_ptr_i32, peer_cta_rank_in_cluster.ir_value()],
            "mapa.shared::cluster.u32 $0, $1, $2;",
            "=r,r,r",
            has_side_effects=False,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )
    )


@dsl_user_op
def store_shared_remote(
    val: Float32,
    smem_ptr: cute.Pointer,
    mbar_ptr: cute.Pointer,
    peer_cta_rank_in_cluster: Int32,
    *,
    loc=None,
    ip=None,
) -> None:
    """
    Asynchronously store a Float32 value to shared memory on a remote CTA
    within the cluster, with mbarrier completion tracking.

    This uses the PTX `st.async.shared::cluster` instruction which:
    1. Translates the local smem address to the peer CTA's address space
    2. Performs an asynchronous store to the remote shared memory
    3. Signals the mbarrier when the store completes

    Args:
        val: The Float32 value to store
        smem_ptr: Pointer to the destination in local shared memory coordinates
        mbar_ptr: Pointer to the mbarrier that tracks completion
        peer_cta_rank_in_cluster: Target CTA's rank within the cluster

    Note:
        - The mbarrier must be initialized with the expected transaction byte count
        - Use `cute.arch.mbarrier_arrive_and_expect_tx()` to set up the transaction
        - Use `cute.arch.mbarrier_wait()` to wait for all stores to complete
        - This operation requires SM90+ with cluster support enabled
    """
    remote_smem_ptr_i32 = set_block_rank(
        smem_ptr, peer_cta_rank_in_cluster, loc=loc, ip=ip
    ).ir_value()
    remote_mbar_ptr_i32 = set_block_rank(
        mbar_ptr, peer_cta_rank_in_cluster, loc=loc, ip=ip
    ).ir_value()
    llvm.inline_asm(
        None,
        [remote_smem_ptr_i32, val.ir_value(loc=loc, ip=ip), remote_mbar_ptr_i32],
        "st.async.shared::cluster.mbarrier::complete_tx::bytes.f32 [$0], $1, [$2];",
        "r,f,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )


@dsl_user_op
def elem_pointer(x: cute.Tensor, coord, *, loc=None, ip=None) -> cute.Pointer:
    """
    Get a pointer to an element at the specified coordinate in a tensor.

    This is useful for getting the shared memory address of a specific element
    when performing cross-CTA stores in cluster reduction.

    Args:
        x: The tensor (typically a shared memory tensor)
        coord: The coordinate tuple, can be hierarchical like (row, (col, cluster_idx))

    Returns:
        Pointer to the element at the specified coordinate
    """
    return x.iterator + cute.crd2idx(coord, x.layout, loc=loc, ip=ip)


# =============================================================================
# Block-Level Reduction
# =============================================================================


@cute.jit
def block_reduce(
    val: Float32,
    op: Callable,
    reduction_buffer: cute.Tensor,
    init_val: Float32,
) -> Float32:
    """
    Reduce values across all warps within a thread block using shared memory.

    This function assumes each warp has already performed a warp-level reduction
    and is contributing a single value (from lane 0). The function then:
    1. Writes each warp's value to shared memory
    2. Synchronizes the block
    3. Performs a final warp reduction across the collected values

    Args:
        val: The warp-reduced value (only lane 0's value is used)
        op: Binary reduction operator, e.g., `operator.add` or `cute.arch.fmax`
        reduction_buffer: Shared memory tensor with shape (rows_per_block, warps_per_row)
        init_val: Identity element for the reduction (0 for sum, -inf for max)

    Returns:
        The block-reduced result (same value across all threads)

    Buffer Layout:
        - Shape: (rows_per_block, warps_per_row)
        - warps_per_row is inferred from reduction_buffer.shape[1]
        - Thread mapping:
            row_idx = warp_idx // warps_per_row
            col_idx = warp_idx % warps_per_row

    Example:
        For a block with 8 warps processing 2 rows (4 warps per row):

        .. code-block:: python

            reduction_buffer = cute.make_smem_tensor(
                cute.make_layout((2, 4)),  # 2 rows, 4 warps per row
                Float32
            )
            result = block_reduce(warp_val, operator.add, reduction_buffer, Float32(0.0))
    """
    lane_idx = cute.arch.lane_idx()
    warp_idx = cute.arch.warp_idx()
    warps_per_row = cute.size(reduction_buffer.shape[1])
    row_idx = warp_idx // warps_per_row
    col_idx = warp_idx % warps_per_row

    # Lane 0 of each warp writes its value to shared memory
    if lane_idx == 0:
        reduction_buffer[row_idx, col_idx] = val
    cute.arch.barrier()

    # All lanes participate in reading and reducing
    # Only lanes < warps_per_row have valid data
    block_reduce_val = init_val
    if lane_idx < warps_per_row:
        block_reduce_val = reduction_buffer[row_idx, lane_idx]
    return cute.arch.warp_reduction(block_reduce_val, op)


# =============================================================================
# Cluster-Level Reduction (SM90+)
# =============================================================================


@cute.jit
def cluster_reduce(
    val: Float32,
    op: Callable,
    reduction_buffer: cute.Tensor,
    mbar_ptr: cute.Pointer,
    cluster_n: cutlass.Constexpr[int],
    init_val: Float32,
) -> Float32:
    """
    Reduce values across all CTAs within a cluster using distributed shared memory.

    This function extends block reduction to work across multiple CTAs in a cluster
    using asynchronous cross-CTA stores and mbarrier synchronization. It:
    1. Sets up the mbarrier with expected transaction count
    2. Asynchronously stores each warp's value to all peer CTAs
    3. Waits for all stores to complete
    4. Reduces across all collected values

    Args:
        val: The warp-reduced value (only lane 0's value is used for stores)
        op: Binary reduction operator, e.g., `operator.add` or `cute.arch.fmax`
        reduction_buffer: Shared memory tensor with hierarchical shape
                          (rows_per_block, (warps_per_row, cluster_n))
        mbar_ptr: Pointer to an initialized mbarrier in shared memory
        cluster_n: Number of CTAs in the cluster (compile-time constant)
        init_val: Identity element for the reduction (0 for sum, -inf for max)

    Returns:
        The cluster-reduced result (same value across all threads in all CTAs)

    Buffer Layout:
        - Shape: (rows_per_block, (warps_per_row, cluster_n))
        - The second dimension is hierarchical:
          - First level: warps_per_row (local warp slots)
          - Second level: cluster_n (one slot per CTA in cluster)
        - Access pattern: buffer[row_idx, (col_idx, cta_rank)]

    Requirements:
        - SM90+ with cluster support
        - Mbarrier must be initialized before calling
        - Kernel must be launched with appropriate cluster dimensions

    Example:
        For a cluster of 4 CTAs, each with 2 warps per row:

        .. code-block:: python

            # Allocate buffer with cluster dimension
            reduction_buffer = cute.make_smem_tensor(
                cute.make_layout((rows_per_block, (2, 4))),  # 2 warps, 4 CTAs
                Float32
            )

            # Initialize mbarrier (once per kernel)
            mbar = cute.make_smem_tensor(cute.make_layout((1,)), cute.arch.Mbarrier)
            cute.arch.mbarrier_init(mbar.iterator, thread_count)

            # Perform cluster reduction
            result = cluster_reduce(
                warp_val, operator.add, reduction_buffer,
                mbar.iterator, cluster_n=4, init_val=Float32(0.0)
            )
    """
    cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
    lane_idx = cute.arch.lane_idx()
    warp_idx = cute.arch.warp_idx()

    rows_per_block = reduction_buffer.shape[0]
    warps_per_row = reduction_buffer.shape[1][0]

    row_idx = warp_idx // warps_per_row
    col_idx = warp_idx % warps_per_row

    # Warp 0, lane 0 sets up mbarrier with expected transaction count
    # Each warp sends cluster_n stores (one to each CTA), each store is 4 bytes
    if warp_idx == 0:
        with cute.arch.elect_one():
            num_warps = rows_per_block * warps_per_row
            expected_bytes = num_warps * cluster_n * 4  # 4 bytes per Float32
            cute.arch.mbarrier_arrive_and_expect_tx(mbar_ptr, expected_bytes)

    # Each lane < cluster_n writes to a different CTA's shared memory
    # This distributes the warp's value to all CTAs in the cluster
    if lane_idx < cluster_n:
        store_shared_remote(
            val,
            elem_pointer(reduction_buffer, (row_idx, (col_idx, cta_rank_in_cluster))),
            mbar_ptr,
            peer_cta_rank_in_cluster=lane_idx,
        )

    # Wait for all cross-CTA stores to complete
    cute.arch.mbarrier_wait(mbar_ptr, phase=0)

    # Now each CTA has all values from all CTAs in the cluster
    # Reduce across all collected values
    num_total = warps_per_row * cluster_n
    num_iter = cute.ceil_div(num_total, 32)

    block_reduce_val = init_val
    for i in cutlass.range_constexpr(num_iter):
        idx = lane_idx + i * 32
        if idx < num_total:
            block_reduce_val = op(block_reduce_val, reduction_buffer[row_idx, idx])

    return cute.arch.warp_reduction(block_reduce_val, op)


# =============================================================================
# Row Reduction (Orchestration Function)
# =============================================================================


@cute.jit
def row_reduce(
    x: cute.TensorSSA,
    op: cute.ReductionOp,
    threads_per_row: cutlass.Constexpr[int],
    reduction_buffer: cute.Tensor,
    mbar_ptr,
    cluster_n: cutlass.Constexpr[int],
    init_val: Float32,
):
    """
    Perform hierarchical row reduction with automatic selection of reduction strategy.

    This function orchestrates the full reduction pipeline:
    1. Local reduction: Each thread reduces its portion of the row
    2. Warp reduction: Threads within a warp reduce using shuffles
    3. Block reduction: If needed, warps reduce using shared memory
    4. Cluster reduction: If needed, CTAs reduce using distributed shared memory

    The function automatically selects the appropriate reduction level based on
    `threads_per_row` and `cluster_n`.

    Args:
        x: TensorSSA containing the values to reduce (in registers)
        op: Reduction operation (cute.ReductionOp.ADD or cute.ReductionOp.MAX)
        threads_per_row: Number of threads cooperating on each row (compile-time)
        reduction_buffer: Shared memory tensor for block/cluster reduction
        mbar_ptr: Mbarrier pointer (only used if cluster_n > 1)
        cluster_n: Number of CTAs in cluster (1 for single-CTA reduction)
        init_val: Identity element for the reduction

    Returns:
        The fully reduced result for each row

    Reduction Strategy Selection:
        - threads_per_row <= 32, cluster_n == 1: Warp reduction only
        - threads_per_row > 32, cluster_n == 1: Warp + block reduction
        - cluster_n > 1: Warp + cluster reduction (handles all cases)

    Example:
        .. code-block:: python

            # Sum reduction across 128 threads per row, single CTA
            result = row_reduce(
                tensor_ssa,
                cute.ReductionOp.ADD,
                threads_per_row=128,
                reduction_buffer=smem_buffer,
                mbar_ptr=None,
                cluster_n=1,
                init_val=Float32(0.0)
            )

            # Max reduction across 256 threads per row, 4 CTAs in cluster
            result = row_reduce(
                tensor_ssa,
                cute.ReductionOp.MAX,
                threads_per_row=256,
                reduction_buffer=smem_buffer,
                mbar_ptr=mbar.iterator,
                cluster_n=4,
                init_val=Float32.neg_inf
            )
    """
    # Step 1: Local reduction - each thread reduces its register values
    local_val = x.reduce(op, init_val=init_val, reduction_profile=0)

    # Map ReductionOp enum to binary operator for warp/block reductions
    warp_op = {
        cute.ReductionOp.ADD: operator.add,
        cute.ReductionOp.MAX: cute.arch.fmax,
    }[op]

    # Step 2: Warp reduction
    # If threads_per_row < 32, only use that many threads in the reduction
    warp_width = min(threads_per_row, 32)
    warp_val = cute.arch.warp_reduction(local_val, warp_op, threads_in_group=warp_width)

    # Determine if we need additional reduction levels
    warps_per_row = max(threads_per_row // 32, 1)

    # Step 3 & 4: Block or cluster reduction (if needed)
    if cutlass.const_expr(warps_per_row > 1 or cluster_n > 1):
        if cutlass.const_expr(cluster_n == 1):
            # Single CTA: use block reduction
            return block_reduce(warp_val, warp_op, reduction_buffer, init_val)
        else:
            # Multiple CTAs: use cluster reduction
            return cluster_reduce(
                warp_val, warp_op, reduction_buffer, mbar_ptr, cluster_n, init_val
            )
    else:
        # Single warp handles entire row: warp reduction is sufficient
        return warp_val

