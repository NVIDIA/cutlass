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

"""Kernel 2 of two-kernel (GMEM) split-K: the partial-accumulator reduction.

Tiled variant: each block reduces one (32, 32) output tile of one batch
slice. Kernel 1 (the GEMM) writes each split's full partial accumulator to
its own L slot of a GMEM workspace viewed as ``(M, N, L * split_k)``; the
reduction kernel here sums the ``split_k`` partials into the user's C,
applying the epilogue and casting to the C dtype at the final store. The
launch shape comes from :func:`get_reduction_grid_block`. Both are generic
over the GEMM kernel that produced the partials -- reach them through the
``TileSchedulerTemplate.get_reduction_grid_block`` / ``reduction_kernel``
stubs rather than importing this module from a kernel.
"""

import cutlass
import cutlass.cute as cute


@cute.jit
def get_reduction_grid_block(problem_shape_mnl):
    """Grid / block for the tiled GMEM split-K reduction kernel (kernel 2).

    One ``(32, 32)`` output tile of one batch (real L) slice per block with
    256 threads (partitioned as an ``(8, 32)`` thread grid in the kernel).
    The three tile counts are folded onto ``grid.x`` -- the kernel recovers
    ``(m_tile, n_tile, l)`` by divmod -- to avoid overflowing the grid
    dimensions; ``grid.x`` is bounded host-side by
    ``SplitKReductionStrategy.can_implement``. Ragged M/N tile edges are
    masked by predication in the kernel.

    :param problem_shape_mnl: output extents (M, N, L) in elements (static).
    :return: ``(grid, block)`` -- both 3-element lists for ``.launch``.
    """
    tile_m = 32
    tile_n = 32

    m_tiles = (problem_shape_mnl[0] + tile_m - 1) // tile_m
    n_tiles = (problem_shape_mnl[1] + tile_n - 1) // tile_n
    grid_x = m_tiles * n_tiles * problem_shape_mnl[2]

    return [grid_x, 1, 1], [256, 1, 1]


@cute.kernel
def reduction_kernel(
    workspace_tensor,
    c,
    split_k: cutlass.Constexpr,
    num_actual_splits: cutlass.Int32,
    epilogue_op: cutlass.Constexpr,
    use_pdl: cutlass.Constexpr = False,
    use_reduction_pdl: cutlass.Constexpr = False,
):
    """Sum the GMEM split-K partial accumulators into C (kernel 2, tiled).

    Each block owns one (32, 32) tile of one batch slice: per split it
    loads the tile's partials from the ``(M, N, L * split_k)`` accumulator
    view with a predicated copy, accumulates in registers, and stores the
    result to C under the same predicate. The accumulation dtype comes from
    the workspace view (the kernel's accumulation precision) and the output
    dtype from ``c``. The launch grid is 1-D (see
    :func:`get_reduction_grid_block`); the block's ``(m_tile, n_tile, l)``
    coordinate is recovered from ``blockIdx.x`` by divmod.

    :param workspace_tensor: accumulator view of shape (M, N, L * split_k)
        over the scheduler workspace (see extract_gmem_splitk_acc_tensor).
    :param c: the user's output tensor C, shape (M, N, L).
    :param split_k: number of partials per output element.
    :param num_actual_splits: number of splits that own at least one K-tile
        (``min(split_k, k_tile_cnt)``); slots past it were never initialized
        by kernel 1 (an empty split's mainloop runs zero K-tiles) and are
        skipped.
    :param epilogue_op: elementwise epilogue applied after the split sum.
    :param use_pdl: inter-operator PDL: signal dependent grids at the end
        so the next operator's kernel can launch early.
    :param use_reduction_pdl: intra-operator PDL: wait for the producer
        GEMM's writes before reading the workspace (mandatory when this
        kernel is launched with the PDL attribute).
    """
    mAcc = workspace_tensor
    mC = c
    acc_dtype = mAcc.element_type
    out_dtype = mC.element_type

    tiler = (32, 32)
    thr_layout = cute.make_layout((8, 32))

    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    m_tiles = cute.ceil_div(mC.shape[0], tiler[0])
    n_tiles = cute.ceil_div(mC.shape[1], tiler[1])
    mn_tiles_fdd = cute.fast_divmod_create_divisor_v2(m_tiles * n_tiles)
    n_tiles_fdd = cute.fast_divmod_create_divisor_v2(n_tiles)
    l_idx, mn_rem = divmod(bidx, mn_tiles_fdd)
    m_idx, n_idx = divmod(mn_rem, n_tiles_fdd)

    # (32, 32, L * split_k) / (32, 32, L) tiles at this block's (m, n).
    gAcc = cute.local_tile(mAcc, tiler, (m_idx, n_idx, None))
    gC = cute.local_tile(mC, tiler, (m_idx, n_idx, None))

    # Per-thread (4, 1) view of this batch's C tile.
    tCgC = cute.local_partition(gC[(None, None, l_idx)], thr_layout, tidx)

    # Predicate masking the ragged M/N tile edges: a coordinate tensor tiled
    # and partitioned exactly like C, tested against the problem extents.
    idC = cute.make_identity_tensor(mC.shape)
    cC = cute.local_tile(idC, tiler, (m_idx, n_idx, None))
    tCcC = cute.local_partition(cC[(None, None, l_idx)], thr_layout, tidx)
    pred = cute.make_rmem_tensor(tCcC.shape, cutlass.Boolean)
    for i in cutlass.range_constexpr(cute.size(pred)):
        pred[i] = cute.elem_less(tCcC[i], mC.shape)

    load_atom = cute.make_copy_atom(cute.nvgpu.CopyG2ROp(), acc_dtype)
    store_atom = cute.make_copy_atom(cute.nvgpu.CopyR2GOp(), out_dtype)

    acc_frag = cute.make_rmem_tensor_like(tCgC, acc_dtype)
    acc_frag.fill(0.0)
    # Masked-off lanes keep the fill value; their stores are masked too.
    staged = cute.make_rmem_tensor_like(tCgC, acc_dtype)
    staged.fill(0.0)
    out_frag = cute.make_rmem_tensor_like(tCgC, out_dtype)

    if cutlass.const_expr(use_reduction_pdl):
        # PDL: the partials are only guaranteed visible after this wait;
        # everything above is address math, safe to run pre-wait.
        cute.arch.griddepcontrol_wait()

    for split_idx in cutlass.range(0, num_actual_splits, 1):
        tCgAcc = cute.local_partition(
            gAcc[(None, None, l_idx * split_k + split_idx)], thr_layout, tidx
        )
        cute.copy(load_atom, tCgAcc, staged, pred=pred)
        acc_frag.store(acc_frag.load() + staged.load())

    # Cast to the user's C dtype, then apply the epilogue -- the same order
    # as the non-split-K epilogue idiom.
    out_frag.store(epilogue_op(acc_frag.load().to(out_dtype)))
    cute.copy(store_atom, out_frag, tCgC, pred=pred)

    if cutlass.const_expr(use_pdl):
        cute.arch.griddepcontrol_launch_dependents()
