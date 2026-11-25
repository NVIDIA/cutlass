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

import cutlass
import cutlass.cute as cute
import cutlass.pipeline as pipeline
import cutlass.utils as utils
from cutlass._mlir import ir
from cutlass.cute.arch.smem import map_dsmem_ptr
from cutlass.cute.nvgpu.cpasync import CopyDsmemStoreOp
from cutlass.cutlass_dsl import (
    dsl_user_op,
    extract_mlir_values,
    new_from_mlir_values,
)
from cutlass.kernels.utils.tile_scheduler.base import BaseReductionStrategy
from cutlass.kernels.utils.tile_scheduler.params import (
    TileSchedulerRuntimeParams,
    TileSchedulerTemplateParams,
)
from cutlass.kernels.utils.tile_scheduler.tile_scheduler import WorkTileInfo


class ClusterSplitKReductionStrategy(BaseReductionStrategy):
    """Split-K reduction via a DSMEM (distributed-shared-memory) mailbox.

    When an output tile is split across ``split_k`` clusters along K, each
    split produces only a partial accumulator. This strategy reduces those
    partials in the epilogue using a peer-to-peer DSMEM scatter-reduce: every
    split owns one shard of the tile's epilogue elements, scatters its
    contribution to that shard into each peer's mailbox, then sums the shards it
    received from peers and writes only its own shard back to C.

    The mailbox is a small SMEM region (see :meth:`get_smem_workspace_size`)
    laid out as two ``Int64`` mbarriers followed by the 32-bit data buffer:

    - ``dsmem_mailbox_full_mbar`` -- arrived/expect-tx by the receiver; signals
      that all ``split_k - 1`` peers have finished writing their shards.
    - ``dsmem_mailbox_empty_mbar`` -- arrived by peers once they have consumed
      this CTA's shard, so the slot can be reused for the next tile.
    - ``dsmem_mailbox_ptr`` -- the ``Float32`` scatter buffer, indexed
      ``(epi_tid, elem_in_shard, sender_slot)`` with ``epi_tid`` innermost for
      coalesced cross-CTA stores. ``st.async`` only moves 32-bit words, so the
      accumulator must be ``Float32`` (enforced by
      ``TileSchedulerTemplate.check_cluster_splitk_constraints``).

    Peers are addressed by cluster rank via :func:`map_dsmem_ptr`. The three
    mailbox pointers and the ``k_start`` / ``k_end`` split range are the
    strategy's per-CTA state (serialized by the extract/new dunders);
    ``template_params`` is compile-time config.
    """

    @dsl_user_op
    def __init__(
        self,
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
        dsmem_mailbox_full_mbar: cute.Pointer,
        dsmem_mailbox_empty_mbar: cute.Pointer,
        dsmem_mailbox_ptr: cute.Pointer,
        k_start: cutlass.Int32,
        k_end: cutlass.Int32,
        *,
        loc=None,
        ip=None,
    ):
        self.template_params = template_params
        self.runtime_params = runtime_params

        self.dsmem_mailbox_full_mbar = dsmem_mailbox_full_mbar
        self.dsmem_mailbox_empty_mbar = dsmem_mailbox_empty_mbar
        self.dsmem_mailbox_ptr = dsmem_mailbox_ptr

        self.k_start = k_start
        self.k_end = k_end

        self._loc = loc

    @staticmethod
    @cute.jit
    def create(
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
        *,
        loc=None,
        ip=None,
    ) -> "ClusterSplitKReductionStrategy":
        """Build a strategy for the calling CTA, carving the mailbox out of SMEM.

        Recasts ``runtime_params.reduction_smem_workspace_ptr`` into the two
        Int64 mbarriers plus the Float32 scatter buffer, initializes the
        mbarriers (when ``split_k > 1``) from the first warp, and computes
        this split's ``[k_start, k_end)`` K-tile range from its rank along the
        cluster's split (Z) dimension.

        :param template_params: scheduler template parameters (split_k, tile/cluster shape)
        :param runtime_params: runtime parameters (k_tile_cnt, reduction SMEM workspace ptr)
        :return: a strategy bound to this CTA's mailbox and K-range
        :rtype: ClusterSplitKReductionStrategy
        """
        k_tile_cnt = runtime_params.k_tile_cnt
        split_k = template_params.split_k
        split_rank = cute.arch.block_in_cluster_idx()[2]
        smem_workspace_ptr = runtime_params.reduction_smem_workspace_ptr

        dsmem_mailbox_full_mbar = cute.recast_ptr(
            smem_workspace_ptr, dtype=cutlass.Int64
        )
        dsmem_mailbox_empty_mbar = (
            cute.recast_ptr(smem_workspace_ptr, dtype=cutlass.Int64) + 1
        )
        dsmem_mailbox_ptr = cute.recast_ptr(
            cute.recast_ptr(smem_workspace_ptr, dtype=cutlass.Int64) + 2,
            dtype=cutlass.Float32,
        )

        # SIM102 intentionally not collapsed: cutlass.const_expr(...) must be the
        # sole condition of its `if` for compile-time branch elision (see the CLC
        # sched-warp block in the kernel); folding into an `and` traces the body.
        if cutlass.const_expr(template_params.split_k > 1):  # noqa: SIM102
            if cutlass.Boolean(cute.arch.thread_idx()[0] // 32 == 0):
                with cute.arch.elect_one():
                    cute.arch.mbarrier_init(dsmem_mailbox_full_mbar, 1)
                    cute.arch.mbarrier_init(
                        dsmem_mailbox_empty_mbar, template_params.split_k - 1
                    )

        # Every rank gets base = k_tile_cnt // split_k tiles, and the first
        # rem = k_tile_cnt % split_k ranks take one extra, so ranks are only
        # empty when split_k exceeds the K-tile count (then k_start == k_end
        # == k_tile_cnt); fixup_and_epilogue zero-fills such ranks' contributions.
        # min(rank, rem) is how many extras were handed out before this rank,
        # so a rank starts at rank * base + min(rank, rem) and ends where the
        # next rank starts.
        # E.g. 6 tiles, split_k=4: base=1, rem=2 -> starts 0,2,4,5 -> sizes 2,2,1,1.
        k_tiles_base = k_tile_cnt // split_k
        k_tiles_rem = k_tile_cnt % split_k
        next_rank = split_rank + 1
        k_start = split_rank * k_tiles_base + min(split_rank, k_tiles_rem)
        k_end = next_rank * k_tiles_base + min(next_rank, k_tiles_rem)

        return ClusterSplitKReductionStrategy(
            template_params,
            runtime_params,
            dsmem_mailbox_full_mbar,
            dsmem_mailbox_empty_mbar,
            dsmem_mailbox_ptr,
            k_start,
            k_end,
        )

    @dsl_user_op
    def pre_fixup(
        self, kernel, tCgC, tCcC, tCtAcc_base, tidx, epi_tile, *, loc=None, ip=None
    ):
        """Compute the loop-invariant epilogue state, once before the persistent loop.

        Builds the TMEM->reg copy partitioning, the partitioned C and C
        coordinate tensors, and the epilogue sync barrier so the per-tile
        :meth:`fixup_and_epilogue` only does per-tile work. ``kernel`` is the
        dense-GEMM kernel object, which the CUTLASS epilogue helpers require;
        the scalar config it carries (``use_2cta_instrs`` /
        ``epilog_sync_bar_id`` / ``epilogue_warp_id``) is read off it.

        :param kernel: dense-GEMM kernel object (source of epilogue scalar config)
        :param tCgC: MMA-partitioned global C tensor
        :param tCcC: MMA-partitioned identity tensor over C's shape, partitioned
            like ``tCgC``; its coordinates predicate the store to C's bounds
        :param tCtAcc_base: MMA-partitioned TMEM accumulator (all pipeline stages)
        :param tidx: linear thread index within the CTA
        :param epi_tile: epilogue subtile shape
        :return: the 8 loop-invariant values consumed by :meth:`fixup_and_epilogue`:
            ``(tTR_tAcc_base, tTR_gC_partitioned, tTR_cC_partitioned,
            tiled_copy_t2r, epilog_sync_barrier, dsmem_full_phase,
            dsmem_empty_phase, num_tiles_done)``. The three phase/counter
            scalars are returned (not stored on ``self``) so they need not be
            maintained as instance state.
        :rtype: tuple
        """
        tCgC_xf = utils.gemm.sm100.transform_partitioned_tensor_layout(tCgC)
        tCcC_xf = utils.gemm.sm100.transform_partitioned_tensor_layout(tCcC)
        tCtAcc_xf = utils.gemm.sm100.transform_partitioned_tensor_layout(tCtAcc_base)

        tiled_copy_t2r, tTR_tAcc_base, _ = (
            utils.gemm.sm100.epilogue_tmem_copy_and_partition(
                kernel, tidx, tCtAcc_xf, tCgC_xf, epi_tile, kernel.use_2cta_instrs
            )
        )
        thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
        tTR_gC_partitioned = thr_copy_t2r.partition_D(
            cute.flat_divide(tCgC_xf, epi_tile)
        )
        tTR_cC_partitioned = thr_copy_t2r.partition_D(
            cute.flat_divide(tCcC_xf, epi_tile)
        )

        epilog_sync_barrier = pipeline.NamedBarrier(
            barrier_id=kernel.epilog_sync_bar_id,
            num_threads=32 * len(kernel.epilogue_warp_id),
        )
        dsmem_full_phase = cutlass.Int32(0)
        dsmem_empty_phase = cutlass.Int32(0)
        num_tiles_done = cutlass.Int32(0)

        return (
            tTR_tAcc_base,
            tTR_gC_partitioned,
            tTR_cC_partitioned,
            tiled_copy_t2r,
            epilog_sync_barrier,
            dsmem_full_phase,
            dsmem_empty_phase,
            num_tiles_done,
        )

    @dsl_user_op
    @cute.jit
    def fixup_and_epilogue(
        self,
        tTR_tAcc_base,
        tTR_gC_partitioned,
        tTR_cC_partitioned,
        tiled_copy_t2r,
        epilog_sync_barrier,
        dsmem_full_phase,
        dsmem_empty_phase,
        num_tiles_done,
        acc_consumer_state,
        acc_pipeline,
        mma_tile_coord_mnl,
        epilogue_op,
        tidx,
        split_rank,
        block_in_cluster_x,
        block_in_cluster_y,
        acc_dtype,
        c_dtype,
        cluster_shape_mn,
        *,
        loc=None,
        ip=None,
    ):
        """Reduce one output tile's per-split partials and run the epilogue.

        For each epilogue subtile, this performs the DSMEM mailbox round-trip:

        1. Wait on ``dsmem_mailbox_empty_mbar`` so peers have drained the slots
           this CTA reused.
        2. Copy this split's accumulator from TMEM to registers; release the acc
           pipeline once the final subtile is fetched.
        3. Arm ``dsmem_mailbox_full_mbar`` (expecting TX from ``split_k - 1``
           peers) and scatter this CTA's contribution to each peer's shard slot,
           writing to the slot indexed by sender rank with the receiver's own
           rank compressed out.
        4. Wait on ``dsmem_mailbox_full_mbar``, sum the received shards into this
           split's shard, signal each peer's ``dsmem_mailbox_empty_mbar``.
        5. Apply ``epilogue_op`` and predicated-store only this split's shard to
           global C, skipping tiles outside C. The scheduler rounds the tile
           grid up to whole clusters, so a partial cluster's CTAs own tiles
           past C's extent.

        :param tTR_tAcc_base: per-stage TMEM accumulator partition from pre_fixup
        :param tTR_gC_partitioned: partitioned global C tensor from pre_fixup
        :param tTR_cC_partitioned: partitioned C coordinate tensor from pre_fixup
        :param tiled_copy_t2r: TMEM->reg tiled copy from pre_fixup
        :param epilog_sync_barrier: intra-CTA epilogue NamedBarrier from pre_fixup
        :param dsmem_full_phase: mailbox FULL mbarrier phase bit (carried across tiles)
        :param dsmem_empty_phase: mailbox EMPTY mbarrier phase bit (carried across tiles)
        :param num_tiles_done: count of tiles already reduced (gates the first empty-wait)
        :param acc_consumer_state: acc pipeline consumer state for this tile
        :param acc_pipeline: accumulator pipeline
        :param mma_tile_coord_mnl: (M, N, L) tile coordinate for indexing global C
        :param epilogue_op: elementwise epilogue applied to the reduced accumulator
        :param tidx: linear thread index within the CTA
        :param split_rank: this CTA's rank along the split (K) dimension
        :param block_in_cluster_x: this CTA's X coordinate within its cluster
        :param block_in_cluster_y: this CTA's Y coordinate within its cluster
        :param acc_dtype: accumulator element type
        :param c_dtype: output C element type
        :param cluster_shape_mn: cluster shape (M, N)
        :return: ``(acc_consumer_state, dsmem_full_phase, dsmem_empty_phase)``
            with the phase bits advanced for the next tile
        :rtype: tuple
        """
        # Static config derived from the template params (cheap, compile-time).
        split_k = self.template_params.split_k
        cluster_shape_m = cluster_shape_mn[0]
        mn_cluster_size = cluster_shape_mn[0] * cluster_shape_mn[1]
        mailbox_elems_per_thread = (
            self.template_params.cta_tile_shape_mnk[0]
            * self.template_params.cta_tile_shape_mnk[1]
        ) // 128
        shard_ept_static = mailbox_elems_per_thread // split_k

        # (epi_tid, elem_in_shard, sender_slot) -> flat mailbox offset.
        # epi_tid is innermost (stride 1) for coalesced DSMEM stores. The
        # default compact (column-major) stride is exactly
        # (1, 128, 128 * shard_ept_static), so it is left implicit.
        mailbox_layout = cute.make_layout((128, shard_ept_static, max(split_k - 1, 1)))
        mailbox = cute.make_tensor(self.dsmem_mailbox_ptr, mailbox_layout)
        dsmem_store_atom = cute.make_copy_atom(CopyDsmemStoreOp(), cutlass.Float32)

        tTR_tAcc = tTR_tAcc_base[
            (None, None, None, None, None, acc_consumer_state.index)
        ]
        tTR_gC = tTR_gC_partitioned[(None, None, None, None, None, *mma_tile_coord_mnl)]
        tTR_cC = tTR_cC_partitioned[(None, None, None, None, None, *mma_tile_coord_mnl)]
        tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
        tTR_gC = cute.group_modes(tTR_gC, 3, cute.rank(tTR_gC))
        tTR_cC = cute.group_modes(tTR_cC, 3, cute.rank(tTR_cC))
        subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])

        assert cutlass.const_expr(subtile_cnt == 1), (
            "split-K DSMEM mailbox requires epi_tile == cta_tile "
            "(subtile_cnt == 1) so shard_ept == shard_ept_static"
        )

        acc_pipeline.consumer_wait(acc_consumer_state)

        for subtile_idx in range(subtile_cnt):
            # Block until every peer has read our previous sender slot.
            if cutlass.Boolean(num_tiles_done > 0 or subtile_idx > 0):
                cute.arch.mbarrier_wait(
                    self.dsmem_mailbox_empty_mbar, dsmem_empty_phase
                )
                dsmem_empty_phase = dsmem_empty_phase ^ 1

            tTR_gC_subtile = tTR_gC[(None, None, None, subtile_idx)]
            tTR_cC_subtile = tTR_cC[(None, None, None, subtile_idx)]
            tTR_rAcc = cute.make_rmem_tensor(tTR_gC_subtile.shape, acc_dtype)
            cute.copy(
                tiled_copy_t2r,
                tTR_tAcc[(None, None, None, subtile_idx)],
                tTR_rAcc,
            )

            # Zero-out empty rank
            if cutlass.Boolean(self.k_start == self.k_end):
                tTR_rAcc.fill(0.0)

            # Release acc pipeline once the final subtile is fetched from TMEM.
            if subtile_idx == subtile_cnt - 1:
                cute.arch.fence_view_async_tmem_load()
                with cute.arch.elect_one():
                    acc_pipeline.consumer_release(acc_consumer_state)
                acc_consumer_state.advance()

            # Derive shard size from the actual rmem tensor (avoids baking in
            # a per-subtile constant that may differ if epi_tile < cta_tile).
            shard_ept = cute.size(tTR_rAcc) // split_k
            my_shard_start = split_rank * shard_ept
            shards = cute.composition(tTR_rAcc, cute.make_layout((shard_ept, split_k)))
            # Expected bytes from (split_k - 1) peers: each peer's 128
            # epilogue threads (4 warps * 32) send shard_ept elements
            # of 4 B (Float32) into our mailbox.
            mailbox_tx_total = (split_k - 1) * 128 * shard_ept * 4

            # Arm mailbox FULL (expecting TX from split_k-1 peers) then scatter.
            if cutlass.Boolean(tidx == 0):
                cute.arch.mbarrier_arrive_and_expect_tx(
                    self.dsmem_mailbox_full_mbar, mailbox_tx_total
                )
            epilog_sync_barrier.arrive_and_wait()

            # Each peer writes to a slot in our mailbox indexed by the sender
            # rank with self-rank compressed out (slot = split_rank if
            # split_rank < peer else split_rank - 1).
            for peer in range(split_k):
                if peer != split_rank:
                    sender_idx = split_rank - (
                        1 if split_rank > cutlass.Int32(peer) else 0
                    )
                    peer_rank = (
                        block_in_cluster_x
                        + cutlass.Int32(cluster_shape_m) * block_in_cluster_y
                        + cutlass.Int32(peer * mn_cluster_size)
                    )
                    remote_mbar = map_dsmem_ptr(self.dsmem_mailbox_full_mbar, peer_rank)
                    # Scatter our whole contiguous shard for `peer` into that
                    # peer's mailbox slot `sender_idx`, remapped to peer DSMEM.
                    local_slot = mailbox[(tidx, None, sender_idx)]
                    remote_slot = cute.make_tensor(
                        map_dsmem_ptr(local_slot.iterator, peer_rank),
                        local_slot.layout,
                    )
                    cute.copy(
                        dsmem_store_atom,
                        shards[(None, peer)],
                        remote_slot,
                        mbar_ptr=remote_mbar,
                    )

            # Do not let local FULL waits move ahead of this CTA's
            # remote DSMEM stores to peer mailboxes.
            cute.arch.fence_acq_rel_cta()
            cute.arch.mbarrier_wait(self.dsmem_mailbox_full_mbar, dsmem_full_phase)
            dsmem_full_phase = dsmem_full_phase ^ 1

            # Reduce received shards into our own partial.
            my_shard = shards[(None, split_rank)]
            for s in range(split_k - 1):
                recv = mailbox[(tidx, None, s)]
                for i in range(shard_ept):
                    my_shard[i] = my_shard[i] + recv[i]

            # Intra-CTA sync: tidx=0 must not signal peer empty barriers
            # until every thread in our CTA has finished reading the mailbox,
            # otherwise the peer's next-tile scatter may overwrite slots we
            # are still reading.
            epilog_sync_barrier.arrive_and_wait()

            # Signal each peer that we've read their shard.
            if tidx == 0:
                for peer in range(split_k):
                    if peer != split_rank:
                        peer_rank = (
                            block_in_cluster_x
                            + cutlass.Int32(cluster_shape_m) * block_in_cluster_y
                            + cutlass.Int32(peer * mn_cluster_size)
                        )
                        cute.arch.mbarrier_arrive(
                            self.dsmem_mailbox_empty_mbar,
                            peer_cta_rank_in_cluster=peer_rank,
                        )

            # Predicated GMEM store: only write our shard's in-bounds elements.
            # (Two-pass predicate setup avoids Python chained comparisons
            # and `or` on runtime Int32, which don't short-circuit correctly.)
            tTR_rC = cute.make_rmem_tensor(tTR_gC_subtile.shape, c_dtype)
            tTR_rC.store(epilogue_op(tTR_rAcc.load().to(c_dtype)))
            # Callers require M and N to be multiples of the CTA tile, so a tile
            # lies wholly inside or wholly outside C, and one element's
            # coordinate bounds-checks the whole tile.
            tile_in_bounds = cute.elem_less(
                tTR_cC_subtile[0], self.runtime_params.problem_shape_mnl
            )
            if tile_in_bounds:
                pred = cute.make_rmem_tensor(tTR_gC_subtile.shape, cutlass.Boolean)
                pred.fill(True)
                for i in range(cute.size(tTR_rC)):
                    if i < my_shard_start or i >= my_shard_start + shard_ept:
                        pred[i] = cutlass.Boolean(False)
                cute.basic_copy_if(pred, tTR_rC, tTR_gC_subtile)

        return acc_consumer_state, dsmem_full_phase, dsmem_empty_phase

    @dsl_user_op
    def split_work_tile(self, next_work_tile_info: WorkTileInfo, *, loc=None, ip=None):
        """Map a split-expanded work tile back to its real output tile + K-range.

        The scheduler expands the L dimension by ``split_k`` (see
        :func:`get_problem_shape_ntile`), so the incoming L index addresses a
        (tile, split) pair. This divides it out to recover the real L tile index
        and attaches this split's ``[k_start, k_end)`` K-range.

        :param next_work_tile_info: work tile with the split-expanded tile index
        :return: a work tile with the de-expanded ``(M, N, L)`` index and this
            split's ``k_start`` / ``k_end``
        :rtype: WorkTileInfo
        """
        tile_idx = next_work_tile_info.tile_idx
        new_tile_idx = (
            tile_idx[0],
            tile_idx[1],
            tile_idx[2] // self.template_params.split_k,
        )

        return WorkTileInfo(
            new_tile_idx,
            next_work_tile_info.is_valid_tile,
            k_start=self.k_start,
            k_end=self.k_end,
        )

    @dsl_user_op
    def finalize(self, *, loc=None, ip=None):
        """Hold the cluster together until every peer finishes its mailbox traffic.

        Keeps the DSMEM mailbox barriers alive until all peer CTAs in the
        physical cluster complete the final scatter/read/ack sequence;
        releasing a CTA early races its SMEM against in-flight peer accesses.
        """
        cute.arch.cluster_arrive_relaxed()
        cute.arch.cluster_wait()

    @staticmethod
    def get_smem_workspace_size(template_params: TileSchedulerTemplateParams) -> int:
        """SMEM mailbox size required, in bytes.

        Sized for the Float32 scatter buffer plus the two Int64 mbarriers
        (16 bytes total): each of the ``split_k - 1`` peers contributes one
        shard (``shard_ept`` elements) for each of the 128 epilogue threads.
        Returns 0 when ``split_k <= 1`` (no reduction needed).

        :param template_params: scheduler template parameters (CTA tile shape, split_k)
        :return: SMEM workspace size in bytes
        :rtype: int
        """
        cta_m = template_params.cta_tile_shape_mnk[0]
        cta_n = template_params.cta_tile_shape_mnk[1]
        split_k = template_params.split_k

        mailbox_elems_per_thread = (cta_m * cta_n) // 128
        shard_ept = mailbox_elems_per_thread // max(split_k, 1)
        mailbox_total_elems = max(split_k - 1, 0) * 128 * shard_ept

        dsmem_mailbox_bytes = 0
        if split_k > 1:
            dsmem_mailbox_bytes = mailbox_total_elems * 4 + 16  # data + 2 barriers

        return dsmem_mailbox_bytes

    @staticmethod
    def can_implement(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnkl,
        swizzle_size,
        raster_along,
    ) -> bool:
        """Reject oversized physical clusters.

        Cluster split-K co-locates the ``split_k`` splits along cluster-Z, so the
        physically launched cluster is ``cluster_shape_mn[0] * cluster_shape_mn[1]
        * split_k``. The fallback cluster is no larger than the preferred one, so
        bounding the preferred cluster suffices. Splits beyond the K-tile count
        are allowed: :meth:`fixup_and_epilogue` contributes zeros for empty ranks.
        """
        cluster_m, cluster_n, cluster_z = template_params.cluster_shape
        return cluster_m * cluster_n * cluster_z <= 16

    @staticmethod
    def get_gmem_workspace_size(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnl: cute.Shape,
    ) -> int:
        """GMEM workspace required, in bytes: 0.

        The reduction is performed entirely peer-to-peer through DSMEM, so no
        global scratch is needed.

        :param template_params: scheduler template parameters
        :param problem_shape_mnl: problem extents (M, N, L) in elements
        :return: GMEM workspace size in bytes (always 0)
        :rtype: int
        """
        return 0

    @staticmethod
    def initialize_workspace(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnl: cute.Shape,
        host_workspace,
    ) -> None:
        """No-op host-side workspace initialization (runs before upload).

        The split-K reduction runs peer-to-peer through DSMEM, so it owns a
        0-byte GMEM workspace with nothing to populate.

        :param template_params: scheduler template parameters
        :param problem_shape_mnl: problem extents (M, N, L) in elements
        :param host_workspace: 1-D int8 host staging buffer (unused)
        """

    def __extract_mlir_values__(self) -> list[ir.Value]:
        values, self._values_pos = [], []
        for obj in [
            self.dsmem_mailbox_full_mbar,
            self.dsmem_mailbox_empty_mbar,
            self.dsmem_mailbox_ptr,
            self.k_start,
            self.k_end,
        ]:
            obj_values = extract_mlir_values(obj)
            values += obj_values
            self._values_pos.append(len(obj_values))
        return values

    def __new_from_mlir_values__(
        self, values: list[ir.Value]
    ) -> "ClusterSplitKReductionStrategy":
        # template_params is compile-time config, re-supplied as-is.
        obj_list, values_copy = [], list(values)
        for obj, n_items in zip(
            [
                self.dsmem_mailbox_full_mbar,
                self.dsmem_mailbox_empty_mbar,
                self.dsmem_mailbox_ptr,
                self.k_start,
                self.k_end,
            ],
            self._values_pos,
        ):
            obj_list.append(new_from_mlir_values(obj, values_copy[:n_items]))
            values_copy = values_copy[n_items:]
        return ClusterSplitKReductionStrategy(
            self.template_params, self.runtime_params, *(tuple(obj_list)), loc=self._loc
        )
