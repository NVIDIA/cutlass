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

"""Arch-neutral parts of the dense-GEMM EFC operation.

This module holds the device-side (Kernel-companion) methods that
are shaped by the GEMM pipeline (tiled MMA + read/write tensor
iteration) but do not depend on any specific GPU architecture's
intrinsics — they use only generic CuTe DSL primitives.

Arch-specific subpackages (e.g. ``dense_gemm.sm100``) provide the
concrete operation class with a ``Kernel`` subclass that inherits
from ``_DenseGemmEFCKernelBase`` and adds the arch-specific
methods (TMA descriptor management, sm100 SMEM allocator usage,
tcgen05 epilogue copy/partition helpers, ...).
"""

from __future__ import annotations

import cutlass
import cutlass.cute as cute  # noqa: F401 — used inside method bodies.

import cutlass.operators.providers.cutedsl.evt.efc as common_efc
from cutlass.operators.providers.cutedsl.evt.efc import log, trace_in_mlir  # noqa: F401


class _DenseGemmEFCKernelBase(common_efc.EFC.Kernel):
    """Arch-neutral methods shared across all dense-GEMM EFC kernel
    companions.

    Pulls together the GEMM-pipeline-shaped methods that use only
    generic CuTe DSL primitives (``cute.local_tile``, ``cute.copy``,
    etc.).  Concrete arch-specific subclasses (e.g. the sm100 kernel
    in ``dense_gemm.sm100._operation``) inherit from this and add
    arch-specific methods.
    """

    @trace_in_mlir
    def partition_global_tensors_for_tiled_mma(self):
        """Partition the global supplemental tensors for TiledMMA_C/D."""
        self.tCgC_read = {}
        self.tCgD_written = {}

        def f(tensor_name, attributes):
            # TMA tensors read through the ``_tma_tensor_*`` parameter
            # (the GMEM tensor wrapped with descriptor metadata); all
            # other modes (sync/async direct GMEM) read through the raw
            # ``_gmem_tensor_*`` parameter.  Both forms are
            # partitionable the same way by ``thr_mma.partition_C``.
            is_tma = attributes.transport is common_efc.Transport.TMA
            if attributes.is_read:
                read_source_arg = (
                    f"{tensor_name}_tma_tensor_read"
                    if is_tma
                    else f"{tensor_name}_gmem_tensor_read"
                )
                # (bM, bN, loopM, loopN, loopL)
                gC_mnl = cutlass.cute.local_tile(
                    self.parameter[read_source_arg],
                    cutlass.cute.slice_(self.operation.mma_tiler, (None, None, 0)),
                    (None, None, None),
                )
                log(
                    f"Kernel.partition_global_tensors_for_tiled_mma: gC_mnl[{tensor_name}] = {gC_mnl!s}"
                )
                # (MMA, MMA_M, MMA_N, loopM, loopN, loopL)
                self.tCgC_read[tensor_name] = self.operation.thr_mma.partition_C(gC_mnl)
                log(
                    f"Kernel.partition_global_tensors_for_tiled_mma: self.tCgC_read[{tensor_name}] = {self.tCgC_read[tensor_name]!s}"
                )

            if attributes.is_written:
                written_source_arg = (
                    f"{tensor_name}_tma_tensor_written"
                    if is_tma
                    else f"{tensor_name}_gmem_tensor_written"
                )
                # (bM, bN, loopM, loopN, loopL)
                gD_mnl = cutlass.cute.local_tile(
                    self.parameter[written_source_arg],
                    cutlass.cute.slice_(self.operation.mma_tiler, (None, None, 0)),
                    (None, None, None),
                )
                log(
                    f"Kernel.partition_global_tensors_for_tiled_mma: gD_mnl[{tensor_name}] = {gD_mnl!s}"
                )
                # (MMA, MMA_M, MMA_N, loopM, loopN, loopL)
                self.tCgD_written[tensor_name] = self.operation.thr_mma.partition_C(
                    gD_mnl
                )
                log(
                    f"Kernel.partition_global_tensors_for_tiled_mma: self.tCgD_written[{tensor_name}] = {self.tCgD_written[tensor_name]!s}"
                )

        self.foreach_tensor(f)

    # The following functions are executed by the specialized warps for
    # epilogue computation.

    @trace_in_mlir
    def slice_written_tensors_per_mma_tile_index(self, mma_tile_coord_mnl):
        """Slice the supplemental written tensors per MMA tile index."""
        self.bSG_gD = {}  # ((ATOM_V, REST_V), (EPI_M, EPI_N))

        def f(tensor_name, attributes):
            if attributes.is_direct:
                # No staged-store machinery to slice for direct tensors.
                return
            # ((ATOM_V, REST_V), EPI_M, EPI_N)
            bSG_gD = self.bSG_gD_partitioned[tensor_name][
                (
                    None,
                    None,
                    None,
                    *mma_tile_coord_mnl,
                )
            ]
            log(
                f"Kernel.slice_written_tensors_per_mma_tile_index: bSG_gD[{tensor_name}] = {bSG_gD!s}"
            )
            # Group the 2 last modes so the subtile_idx loop can iterate
            # through it using 1-D indexing.
            # ((ATOM_V, REST_V), (EPI_M, EPI_N))
            self.bSG_gD[tensor_name] = cutlass.cute.group_modes(
                bSG_gD, 1, cutlass.cute.rank(bSG_gD)
            )
            log(
                f"Kernel.slice_written_tensors_per_mma_tile_index: self.bSG_gD[{tensor_name}] = {self.bSG_gD[tensor_name]!s}"
            )

        self.foreach_written_tensor(f)

    @trace_in_mlir
    def load_tensors_from_smem_to_register(self, index):
        """Load supplemental tensors from shared memory to register."""

        def f(tensor_name, attributes):
            if attributes.is_direct:
                # Direct-read tensors are not staged in SMEM, so there
                # is no SMEM-to-register copy to perform here.
                return
            cutlass.cute.copy(
                self.tiled_copy_s2r[tensor_name],
                self.tSR_sC[tensor_name][
                    (
                        None,
                        None,
                        None,
                        index,
                    )
                ],
                self.tSR_rC[tensor_name],
            )
            log(
                f"Kernel.load_tensors_from_smem_to_register cutlass.cute.copy: self.tiled_copy_s2r[{tensor_name}] = {self.tiled_copy_s2r[tensor_name]!s}"
            )
            log(
                f"Kernel.load_tensors_from_smem_to_register cutlass.cute.copy: self.tSR_sC[{tensor_name}] = {self.tSR_sC[tensor_name]!s}"
            )
            log(
                f"Kernel.load_tensors_from_smem_to_register cutlass.cute.copy: self.tSR_rC[{tensor_name}] = {self.tSR_rC[tensor_name]!s}"
            )

        self.foreach_read_tensor(f)

    @trace_in_mlir
    def epilogue_computation(self, epilogue_context):
        """Execute the EFC epilogue."""

        epilogue_context.load = {}
        epilogue_context.store = {}
        # Destination cute.Tensor objects for reduce targets, keyed
        # by the remapped tensor name (e.g.
        # ``amax__remapped__True__True__True``).  Populated below
        # for every degenerate-scalar destination with a non-``None``
        # ``reduce_op``; consumed by ``Tensor.reduce`` in the
        # ``ThreadOperation`` phase to emit the cross-CTA atomic.
        epilogue_context.reduce = {}
        # Per-reduce-destination SMEM scratch (one slot per epi
        # warp, in the epi dtype), allocated up-front by the
        # kernel-side ``allocate_smem`` step.  Used by
        # ``Tensor.reduce`` for the cross-warp fold step before
        # one warp emits the global atomic.
        epilogue_context.reduce_smem = {}
        # SMEM-staged kept-axis fold companions: the per-thread per-subtile
        # SMEM mirror fragment, the flat SMEM fold buffer, and the kept
        # extent.  Consumed by ``_emit_axis_reduce_smem`` to fold
        # cross-thread duplicates in SMEM; the per-CTA GMEM base is
        # resolved later, in ``reduce_smem_flush``, by slicing the stored
        # ``local_tile`` with the current ``mma_tile_coord_mnl``.
        epilogue_context.reduce_smem_frag = {}
        epilogue_context.reduce_smem_buf = {}
        epilogue_context.reduce_kept_extent = {}
        # Per-target SMEM-staging selector (computed before the subtile
        # loop in ``copy_and_partition``); the dispatch reads it to choose
        # the SMEM fold vs the direct scatter.
        epilogue_context.reduce_use_smem = {}

        def reduce_destination_setup(tensor_name, attributes):
            """Expose each reduce destination so ``Tensor.reduce`` can
            emit its atomic in the ``ThreadOperation`` phase.

            Scalar (all-``:``) destinations expose the single-element
            buffer (atomic into ``tensor.iterator``) plus the SMEM
            scratch for the warpgroup fold.  Non-scalar (kept-axis)
            destinations expose *both* per-subtile fragments the dispatch
            selector chooses between: the GMEM fragment (direct scatter,
            ``_emit_axis_reduce``) and the SMEM mirror fragment plus flush
            handles (SMEM-staged fold, ``_emit_axis_reduce_smem``).  Skips
            non-reduce tensors.
            """
            if attributes.reduce_op is None:
                return
            if attributes.degenerate_to_scalar:
                epilogue_context.reduce[tensor_name] = self.parameter[tensor_name]
                epilogue_context.reduce_smem[tensor_name] = self.smem_reduce[
                    tensor_name
                ]
                log(
                    f"Kernel.epilogue_computation reduce_destination_setup scalar: "
                    f"{tensor_name} = {self.parameter[tensor_name]!s}"
                )
            else:
                # Both non-scalar emit paths need their per-subtile
                # fragment; the dispatch selector picks one.  Direct GMEM
                # scatter (``_emit_axis_reduce``) uses the GMEM fragment;
                # the SMEM-staged fold (``_emit_axis_reduce_smem``) uses
                # the SMEM mirror fragment plus the flush handles.
                #
                # GMEM fragment: slice this CTA's (RestM,RestN,RestL) tile
                # then group EPI_M/EPI_N for ``subtile_idx``.
                part = self.tTR_gReduce_partitioned[tensor_name]
                part = part[
                    (None, None, None, None, None, *epilogue_context.mma_tile_coord_mnl)
                ]
                part = cutlass.cute.group_modes(part, 3, cutlass.cute.rank(part))
                epilogue_context.reduce[tensor_name] = part[
                    (None, None, None, epilogue_context.subtile_idx)
                ]
                # SMEM mirror fragment + flush handles.  The mirror has no
                # Rest dims (the buffer already holds this CTA's tile), so
                # only EPI_M/EPI_N are grouped and sliced by ``subtile_idx``.
                smem_part = self.tTR_sReduce_partitioned[tensor_name]
                smem_part = cutlass.cute.group_modes(
                    smem_part, 3, cutlass.cute.rank(smem_part)
                )
                epilogue_context.reduce_smem_frag[tensor_name] = smem_part[
                    (None, None, None, epilogue_context.subtile_idx)
                ]
                epilogue_context.reduce_smem_buf[tensor_name] = self.smem_reduce[
                    tensor_name
                ]
                epilogue_context.reduce_kept_extent[tensor_name] = (
                    self.reduce_kept_extent[tensor_name]
                )
                epilogue_context.reduce_use_smem[tensor_name] = self.reduce_use_smem[
                    tensor_name
                ]
                log(
                    f"Kernel.epilogue_computation reduce_destination_setup "
                    f"non-scalar SMEM: {tensor_name} = "
                    f"{epilogue_context.reduce_smem_frag[tensor_name]!s}, "
                    f"use_smem={epilogue_context.reduce_use_smem[tensor_name]}"
                )

        self.efc.foreach_remapped_tensor(reduce_destination_setup)

        def broadcast_degenerate_tensor_load(tensor_name, attributes):
            """Create the SSA Tensor for the degenerate tensor broadcast
            read.  A degenerate-scalar tensor used as a reduce
            destination (``reduce_op is not None``) is write-only and
            must not be materialized as a read fragment here -- its
            data flow is the dual: a cross-CTA atomic emitted by
            ``Tensor.reduce`` in the user epilogue, not a broadcast
            ``full_like``.
            """
            if attributes.degenerate_to_scalar and attributes.reduce_op is None:
                log(
                    f"Kernel.epilogue_computation broadcast_degenerate_tensor_load: broadcast scalar from {tensor_name} = {self.parameter[tensor_name]!s}"
                )
                # If the broadcast tensor degenerates to a scalar, just
                # dereference the scalar at index 0 and broadcast it to a
                # TensorSSA similar to the accumulator.
                epilogue_context.load[tensor_name] = cutlass.cute.full_like(
                    epilogue_context.acc_vec,
                    self.parameter[tensor_name][0],
                    self.efc.operation.epi_dtype,
                )

        self.efc.foreach_remapped_tensor(broadcast_degenerate_tensor_load)

        def load_setup(tensor_name, attributes):
            # ``self.subtile_retile`` (set in
            # ``copy_and_partition_supplemental_rmem_tensors``) brings
            # any per-thread register fragment into the per-subtile
            # register layout the store path expects -- R2S when there
            # is a TMA D, T2R otherwise.  ``retile`` is a layout-only
            # re-view; for direct-read fragments the retile is
            # effectively a no-op, but we keep the call uniform so both
            # branches read alike.
            if attributes.is_direct:
                # The per-subtile direct load already fired in
                # ``load_direct_read_tensors_per_subtile``;
                # ``tTR_rC_direct[name]`` holds the loaded data.
                epilogue_context.load[tensor_name] = self.subtile_retile(
                    self.tTR_rC_direct[tensor_name]
                ).load()
                return
            # TMA-loaded read.  ``tSR_rC`` is the S2R-shape view of a
            # T2R-shape register; ``subtile_retile`` converts it to
            # whichever shape the store path expects.
            epilogue_context.load[tensor_name] = self.subtile_retile(
                self.tSR_rC[tensor_name]
            ).load()
            log(f"Kernel.epilogue_computation load_setup: {self.subtile_retile = !s}")
            log(
                f"Kernel.epilogue_computation load_setup: self.tSR_rC[{tensor_name}] = {self.tSR_rC[tensor_name]!s}"
            )
            log(
                f"Kernel.epilogue_computation load_setup: self.subtile_retile(self.tSR_rC[{tensor_name}]) = {self.subtile_retile(self.tSR_rC[tensor_name])!s}"
            )
            log(
                f"Kernel.epilogue_computation load_setup: epilogue_context.load[{tensor_name}] = {epilogue_context.load[tensor_name]!s}"
            )

        self.foreach_read_tensor(load_setup)

        def store_setup(tensor_name, attributes):
            if attributes.is_direct:
                # Symmetric to ``load_setup``: expose a subtile-layout
                # view of the T2R-shape ``tTR_rD_direct[name]`` so the
                # body's ``tRS_rD.store(value)`` finds matching shapes.
                # The later ``cute.copy(direct_store_atom, tTR_rD_direct, gmem)``
                # in ``store_direct_written_tensors_per_subtile`` reads
                # back through the T2R-shape name and writes the same
                # underlying registers straight to global memory.
                epilogue_context.store[tensor_name] = self.subtile_retile(
                    self.tTR_rD_direct[tensor_name]
                )
                return
            epilogue_context.store[tensor_name] = self.tRS_rD[tensor_name]
            log(
                f"Kernel.epilogue_computation store_setup: epilogue_context.store[{tensor_name}] = {epilogue_context.store[tensor_name]!s}"
            )

        self.foreach_written_tensor(store_setup)

        self.efc.specialized_epilogue(
            common_efc.EFC.Phase.ThreadOperation, epilogue_context
        )()

    @trace_in_mlir
    def reduce_smem_init(self, barrier):
        """Before the subtile loop: zero each SMEM-staged kept-axis reduce
        target's per-CTA fold buffer to the op identity.

        Paired with ``reduce_smem_flush`` after the loop, this lets the
        per-subtile folds (emitted from ``Tensor.reduce``) accumulate in
        one buffer and flush once -- cutting both the global-atomic count
        and the warpgroup barriers by ``subtile_cnt`` versus folding and
        flushing per subtile.  Only targets the selector marked
        ``reduce_use_smem`` (column-style); row-style folds use the direct
        per-subtile scatter and need no buffer.
        """
        epi_warp_id = self.operation.epilogue_warp_id

        def f(tensor_name, attributes):
            if attributes.reduce_op is None or attributes.degenerate_to_scalar:
                return
            if not self.reduce_use_smem[tensor_name]:
                return
            common_efc._tensor._emit_axis_reduce_smem_init(
                attributes.reduce_op,
                self.operation.epi_dtype,
                self.smem_reduce[tensor_name],
                self.reduce_kept_extent[tensor_name],
                barrier,
                len(epi_warp_id),
                epi_warp_id[0],
            )

        self.efc.foreach_remapped_tensor(f)

    @trace_in_mlir
    def reduce_smem_flush(self, barrier, mma_tile_coord_mnl):
        """After the subtile loop: flush each SMEM-staged reduce target's
        accumulated fold buffer to global memory -- one global atomic per
        kept coordinate, combined onto the destination -- fenced before
        (all folds done) and after (a persistent CTA can re-init for its
        next tile).

        ``mma_tile_coord_mnl`` selects this CTA's current output tile.
        Slicing the stored per-CTA ``local_tile`` by it offsets the
        iterator to the tile's kept-axis base (folded axes carry stride
        0), so a persistent CTA flushes each visited tile to its own
        slice of the destination vector rather than always to ``[0,
        kept_extent)``.
        """
        epi_warp_id = self.operation.epilogue_warp_id

        def f(tensor_name, attributes):
            if attributes.reduce_op is None or attributes.degenerate_to_scalar:
                return
            if not self.reduce_use_smem[tensor_name]:
                return
            # This CTA's kept-axis base for the current tile.
            gmem_base = self.reduce_gReduce_mnl[tensor_name][
                (None, None, *mma_tile_coord_mnl)
            ].iterator
            common_efc._tensor._emit_axis_reduce_smem_flush(
                attributes.reduce_op,
                self.operation.epi_dtype,
                self.smem_reduce[tensor_name],
                gmem_base,
                self.reduce_kept_extent[tensor_name],
                barrier,
                len(epi_warp_id),
                epi_warp_id[0],
            )

        self.efc.foreach_remapped_tensor(f)

    @trace_in_mlir
    def store_written_tensors_to_smem(self, d_buffer):
        """Store the EFC written tensors to shared memory."""

        def f(tensor_name, attributes):
            if attributes.is_direct:
                # Direct-write tensors do not stage through SMEM; the
                # consumer warp drains them in
                # ``store_direct_written_tensors_per_subtile`` instead.
                return
            cutlass.cute.copy(
                self.tiled_copy_r2s[tensor_name],
                self.tRS_rD[tensor_name],
                self.tRS_sD[tensor_name][(None, None, None, d_buffer)],
            )
            log(
                f"Kernel.store_written_tensors_to_smem cutlass.cute.copy: self.tiled_copy_r2s[{tensor_name}] = {self.tiled_copy_r2s[tensor_name]!s}"
            )
            log(
                f"Kernel.store_written_tensors_to_smem cutlass.cute.copy: self.tRS_rD[{tensor_name}] = {self.tRS_rD[tensor_name]!s}"
            )
            log(
                f"Kernel.store_written_tensors_to_smem cutlass.cute.copy: self.tRS_sD[{tensor_name}] = {self.tRS_sD[tensor_name]!s}"
            )
            log(
                f"Kernel.store_written_tensors_to_smem cutlass.cute.copy: self.tRS_sD[{tensor_name}][(None, None, None, d_buffer)] = {self.tRS_sD[tensor_name][(None, None, None, d_buffer)]!s}"
            )

        self.foreach_written_tensor(f)

    @trace_in_mlir
    def load_direct_read_tensors_per_subtile(self, mma_tile_coord_mnl, subtile_idx):
        """Fire one synchronous direct global-memory load per direct-read
        tensor for the current subtile, filling the per-thread register
        fragment that ``epilogue_computation``'s ``load_setup`` will hand
        to the body via ``epilogue_context.load[name]``.

        Called from the kernel main loop on every epilogue warp -- each
        thread reads its own slice; no warp gating, no pipeline.
        """

        def f(tensor_name, attributes):
            if not attributes.is_direct or not attributes.is_read:
                return
            # tTR_gC_direct_partitioned shape:
            # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL).
            # First slice (RestM, RestN, RestL) by the current MMA tile,
            # then group the (EPI_M, EPI_N) modes for 1-D subtile
            # indexing, then slice for the current subtile.
            tTR_gC = self.tTR_gC_direct_partitioned[tensor_name][
                (None, None, None, None, None, *mma_tile_coord_mnl)
            ]
            tTR_gC = cutlass.cute.group_modes(tTR_gC, 3, cutlass.cute.rank(tTR_gC))
            tTR_gC_subtile = tTR_gC[(None, None, None, subtile_idx)]
            cutlass.cute.copy(
                self.direct_load_atom[tensor_name],
                tTR_gC_subtile,
                self.tTR_rC_direct[tensor_name],
            )

        self.foreach_read_tensor(f)

    @trace_in_mlir
    def store_direct_written_tensors_per_subtile(self, mma_tile_coord_mnl, subtile_idx):
        """Symmetric direct global-memory store for direct-write tensors:
        drain the per-thread register fragment the body just wrote into,
        straight to global memory.

        Called from the kernel main loop on every epilogue warp -- each
        thread writes its own slice, independently of the TMA-store
        warp gate that handles the staged-store path.
        """

        def f(tensor_name, attributes):
            if not attributes.is_direct or not attributes.is_written:
                return
            tTR_gD = self.tTR_gD_direct_partitioned[tensor_name][
                (None, None, None, None, None, *mma_tile_coord_mnl)
            ]
            tTR_gD = cutlass.cute.group_modes(tTR_gD, 3, cutlass.cute.rank(tTR_gD))
            tTR_gD_subtile = tTR_gD[(None, None, None, subtile_idx)]
            cutlass.cute.copy(
                self.direct_store_atom[tensor_name],
                self.tTR_rD_direct[tensor_name],
                tTR_gD_subtile,
            )

        self.foreach_written_tensor(f)

    @trace_in_mlir
    def prepare_tensor_load_for_subtiles(
        self,
        mma_tile_coord_mnl,
    ):
        """Prepare the EFC tensors to be loaded by the subtiles and return the number of subtiles to compute."""
        self.bGS_gC = {}
        # In the case there is no supplemental tensor to load in the
        # epilogue:
        self._subtile_cnt = 0

        def f(tensor_name, attributes):
            if attributes.is_direct:
                # Direct reads bypass the staged-load pipeline; they
                # are emitted per-subtile by the consumer warp in
                # ``load_direct_read_tensors_per_subtile``.
                # ``self._subtile_cnt`` here counts only TMA-loaded
                # reads, so when every read is direct (or no read
                # tensor is declared) it stays 0 and the epilogue load
                # warp's subtile loop becomes a no-op -- the consumer
                # warp's loop is driven by the accumulator's subtile
                # shape and runs independently.
                return
            self.bGS_gC[tensor_name] = self.bGS_gC_partitioned[tensor_name][
                (
                    None,
                    None,
                    None,
                    *mma_tile_coord_mnl,
                )
            ]
            self.bGS_gC[tensor_name] = cutlass.cute.group_modes(
                self.bGS_gC[tensor_name],
                1,
                cutlass.cute.rank(self.bGS_gC[tensor_name]),
            )
            st_cnt = cutlass.cute.size(self.bGS_gC[tensor_name].shape, mode=[1])
            if self._subtile_cnt == 0:
                # Keep the first loaded tensor as a reference.
                self._subtile_cnt = st_cnt
            if st_cnt != self._subtile_cnt:
                raise NotImplementedError(
                    f"Subtile count mismatch: tensor '{self.efc.read_tensor_names[0]}' has {self._subtile_cnt} subtiles, "
                    f"but tensor '{tensor_name}' has {st_cnt} subtiles. All tensors must have the same subtile count."
                )

        self.foreach_read_tensor(f)

        return self._subtile_cnt
