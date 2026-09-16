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

"""Internal copy/partition helpers for DenseGemmEFC.

These functions are imported by `_operation.py` and bound as class
attributes of DenseGemmEFC, so they remain callable as instance
methods (e.g. `self.epilogue_tmem_copy_and_partition(...)`) but
live in their own module for cohesion.  Each function takes
`self` (a DenseGemmEFC instance) as its first argument and reads
the kernel's MMA / layout / dtype attributes from it.
"""

from __future__ import annotations

import contextlib
import io
import os

import cutlass
import cutlass.cute as cute
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.nvgpu import cpasync, tcgen05
from cutlass.cute.viz import print_latex_tv


def maybe_dump_tv_latex(
    tiled_copy: cute.TiledCopy, name: str, *, tile_mn=None, context: str = None
) -> None:
    """When ``CUTE_DSL_EFC_DUMP_TV_LATEX`` names a directory, write the
    thread-value layout of ``tiled_copy`` there as a standalone TikZ
    ``<name>.tex`` (render with ``pdflatex``).

    The TV map shows, per ``(m, n)`` element of the tile, which thread
    ``T#`` and per-thread value ``V#`` owns it.  ``tile_mn`` defaults to
    the copy's ``tiler_mn``; ``context`` is the figure title (one line
    per ``\\n`` segment).  ``CUTE_DSL_EFC_DUMP_TV_PALETTE=rainbow``
    selects the two-band tid/vid hue coloring.

    A no-op unless the env var is set.  Any failure is captured into
    ``<name>.tex.error`` rather than aborting the compile -- this is a
    diagnostic aid, never load-bearing.
    """
    dump_dir = os.environ.get("CUTE_DSL_EFC_DUMP_TV_LATEX")
    if not dump_dir:
        return
    path = os.path.join(dump_dir, f"{name}.tex")
    rainbow = os.environ.get("CUTE_DSL_EFC_DUMP_TV_PALETTE") == "rainbow"
    try:
        os.makedirs(dump_dir, exist_ok=True)
        if tile_mn is None:
            tiler = tiled_copy.tiler_mn
            # ``tiler_mn`` modes may be layouts; reduce each to its size
            # so ``print_latex_tv`` gets a plain (M, N) int tuple.
            tile_mn = (cute.size(tiler[0]), cute.size(tiler[1]))
        # ``print_latex_tv`` emits the document via ``print``; capture
        # its stdout to a buffer so a mid-emission failure leaves no
        # half-written ``.tex``.
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            print_latex_tv(
                tiled_copy.layout_tv_tiled,
                tile_mn,
                palette="rainbow_dual" if rainbow else None,
                title=context or name,
                axis_labels=True,
            )
        with open(path, "w") as out:
            out.write(buf.getvalue())
    except Exception as exc:  # noqa: BLE001 -- diagnostic, must not abort.
        with contextlib.suppress(Exception), open(path + ".error", "w") as err:
            err.write(f"{type(exc).__name__}: {exc}\n")


def epilogue_tmem_copy_and_partition(
    self,
    tidx: cutlass.Int32,
    tAcc: cute.Tensor,
    tCgC: cute.Tensor,
    epi_tile: cute.Tile,
) -> tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
    """
    Make tiledCopy for tensor memory load, then use it to partition tensor memory (source) and register array (destination).
    """
    # Make tiledCopy for tensor memory load
    copy_atom_t2r = sm100_utils.get_tmem_load_op(
        self.cta_tile_shape_mnk,
        self.d_layout,  # Take this as the reference layout for the epilogue tile.
        self.epi_dtype,  # But we get the accumulator as epi_dtype in the epilogue.
        self.acc_dtype,
        epi_tile,
        self.use_2cta_instrs,
    )

    # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, STAGE)
    tAcc_epi = cute.flat_divide(
        tAcc[((None, None), 0, 0, None)],
        epi_tile,
    )
    # (EPI_TILE_M, EPI_TILE_N)
    tiled_copy_t2r = tcgen05.make_tmem_copy(
        copy_atom_t2r, tAcc_epi[(None, None, 0, 0, 0)]
    )
    # TV map of the accumulator's TMEM->register copy.
    maybe_dump_tv_latex(
        tiled_copy_t2r,
        f"t2r_acc_{self.epi_dtype.__name__}",
        context=(
            f"{type(self).__module__}.{type(self).__qualname__}\n"
            "epilogue_tmem_copy_and_partition\n"
            f"T2R: accumulator TMEM->reg (MMA output), epi={self.epi_dtype.__name__}"
        ),
    )
    thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
    # (T2R, T2R_M, T2R_N, EPI_M, EPI_M, STAGE)
    tTR_tAcc = thr_copy_t2r.partition_S(tAcc_epi)

    # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, RestM, RestN, RestL)
    tCgC_epi = cute.flat_divide(tCgC[((None, None), 0, 0, None, None, None)], epi_tile)
    # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL)
    tTR_gC = thr_copy_t2r.partition_D(tCgC_epi)
    # (T2R, T2R_M, T2R_N)
    tTR_rAcc = cute.make_rmem_tensor(
        tTR_gC[(None, None, None, 0, 0, 0, 0, 0)].shape, self.acc_dtype
    )
    return tiled_copy_t2r, tTR_tAcc, tTR_rAcc


def epilogue_smem_copy_and_partition_load(
    self,
    tiled_copy_t2r: cute.TiledCopy,
    tTR_rC: cute.Tensor,
    tidx: cutlass.Int32,
    sC: cute.Tensor,
) -> tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
    """
    Make tiledCopy for shared memory load, then use it to partition register array (destination) and shared memory (source).

    :param tiled_copy_t2r: The tiled copy operation for tmem to register copy(t2r)
    :type tiled_copy_t2r: cute.TiledCopy
    :param tTR_rC: The partitioned accumulator tensor
    :type tTR_rC: cute.Tensor
    :param tidx: The thread index in epilogue warp groups
    :type tidx: cutlass.Int32
    :param sC: The shared memory tensor to be copied and partitioned
    :type sC: cute.Tensor

    :return: A tuple containing (tiled_copy_s2r, tSR_rC, tSR_sC) where:
        - tiled_copy_s2r: The tiled copy operation for smem to register copy(s2r)
        - tSR_rC: The partitioned tensor C (register destination)
        - tSR_sC: The partitioned tensor C (smem source)
    :rtype: tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]
    """
    copy_atom_s2r = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), self.c_dtype)
    tiled_copy_s2r = cute.make_tiled_copy_D(copy_atom_s2r, tiled_copy_t2r)
    # TV map of the staged-read SMEM->register copy.
    maybe_dump_tv_latex(
        tiled_copy_s2r,
        f"s2r_read_{self.c_dtype.__name__}",
        context=(
            f"{type(self).__module__}.{type(self).__qualname__}\n"
            "epilogue_smem_copy_and_partition_load\n"
            f"S2R: staged-read SMEM->reg (TMA + cp.async consume), c={self.c_dtype.__name__}"
        ),
    )
    # (S2R, S2R_M, S2R_N, PIPE_C)
    thr_copy_s2r = tiled_copy_s2r.get_slice(tidx)
    tSR_sC = thr_copy_s2r.partition_D(sC)
    # (S2R, S2R_M, S2R_N)
    tSR_rC = tiled_copy_s2r.retile(tTR_rC)
    return tiled_copy_s2r, tSR_rC, tSR_sC


def epilogue_gmem_copy_and_partition(
    self,
    tidx: cutlass.Int32,
    atom: cute.CopyAtom,
    gC_mnl: cute.Tensor,
    epi_tile: cute.Tile,
    sC: cute.Tensor,
) -> tuple[cute.CopyAtom, cute.Tensor, cute.Tensor]:
    """Make a tiled copy for the SMEM → GMEM TMA store and partition
    shared memory (source) and global memory (destination) for it.

    :param tidx: The thread index in epilogue warp groups.
    :type tidx: cutlass.Int32
    :param atom: The TMA copy atom to be used for the SMEM → GMEM store.
    :type atom: cute.CopyAtom
    :param gC_mnl: The global tensor C.
    :type gC_mnl: cute.Tensor
    :param epi_tile: The epilogue tiler.
    :type epi_tile: cute.Tile
    :param sC: The shared memory tensor to be copied and partitioned.
    :type sC: cute.Tensor

    :return: ``(tma_atom_c, bSG_sC, bSG_gC)`` where ``tma_atom_c`` is the
        TMA copy atom, ``bSG_sC`` is the partitioned shared memory
        tensor C, and ``bSG_gC`` is the partitioned global tensor C.
    :rtype: tuple[cute.CopyAtom, cute.Tensor, cute.Tensor]
    """
    # No TV dump: TMA is descriptor-driven and has no CuTe thread-value
    # layout for ``print_latex_tv`` to render.
    # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, tiles_m, tiles_n, tiles_l)
    gC_epi = cute.flat_divide(gC_mnl[((None, None), 0, 0, None, None, None)], epi_tile)

    tma_atom_c = atom
    sC_for_tma_partition = cute.group_modes(sC, 0, 2)
    gC_for_tma_partition = cute.group_modes(gC_epi, 0, 2)
    # ((ATOM_V, REST_V), EPI_M, EPI_N)
    # ((ATOM_V, REST_V), EPI_M, EPI_N, tiles_m, tiles_n, tiles_l)
    bSG_sC, bSG_gC = cpasync.tma_partition(
        tma_atom_c,
        0,
        cute.make_layout(1),
        sC_for_tma_partition,
        gC_for_tma_partition,
    )
    return tma_atom_c, bSG_sC, bSG_gC


def epilogue_gmem_copy_and_partition_async(
    self,
    lane_idx: cutlass.Int32,
    atom: cute.CopyAtom,
    raw_gmem_tensor: cute.Tensor,
    epi_tile: cute.Tile,
    sC: cute.Tensor,
    dtype: type[cutlass.Numeric],
    num_bits_per_copy: int,
    num_load_warp_threads: int,
) -> tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
    """Build a per-thread ``cp.async`` (G2S) partition for an
    ``ASYNC_GMEM_LOAD``-mode supplemental read tensor.

    Partitions the RAW ``(M, N, L)`` gmem tensor rather than a
    ``thr_mma.partition_C`` output: the cp.async alignment proof needs
    the M stride visible as a plain layout stride, which ``partition_C``
    would bury inside a nested-tuple mode.  Stride divisibility is
    injected with ``cute.assume`` and pointer alignment with
    ``make_ptr(assumed_align=...)`` before ``local_tile`` /
    ``flat_divide`` / partition.

    :param lane_idx: warp-local thread index, in
        ``[0, num_load_warp_threads)``.
    :param atom: ``CopyG2SOp`` atom built at JIT time with its
        ``num_bits_per_copy`` fixed.
    :param raw_gmem_tensor: the user-provided GMEM tensor, shape
        ``(M, N, L)``, before any ``local_tile`` / ``partition_C`` step.
        Its contiguous (stride-1) axis is N for an N-major C/D and M for
        an M-major one; the cp.async vector runs along that axis.
    :param epi_tile: one epilogue sub-tile shape
        ``(EPI_TILE_M, EPI_TILE_N)``.
    :param sC: the staged SMEM tensor, shape
        ``(EPI_TILE_M, EPI_TILE_N, STAGES)``.
    :param dtype: element type of the GMEM/SMEM tensor.
    :param num_load_warp_threads: thread count in the load warp.
    :returns: ``(tiled_copy_g2s, bGS_sC, bGS_gC)`` shaped to match the
        6-mode ``(copy_unit, EPI_M, EPI_N, tiles_m, tiles_n, tiles_l)``
        contract that ``prepare_tensor_load_for_subtiles`` /
        ``load_tensor_subtiles`` consume (the same shape the TMA path's
        ``tma_partition`` produces).
    """
    # Each cp.async transfers ``num_bits_per_copy`` bits, which is
    # ``copy_elems`` elements of ``dtype``.  This is the per-thread
    # value count along the contig axis.  Require an exact fit: a
    # non-multiple would silently truncate here and build an invalid
    # tiling shape (it bites sub-byte widths such as fp6, where 128 is
    # not a multiple of 6).
    assert num_bits_per_copy % dtype.width == 0, (
        f"num_bits_per_copy ({num_bits_per_copy}) must be a multiple of "
        f"{dtype.__name__}.width ({dtype.width})"
    )
    copy_elems = num_bits_per_copy // dtype.width
    # cp.async vectorizes ``copy_elems`` *consecutive* elements, so the
    # copy must run along the contiguous (stride-1) C/D axis -- N for an
    # N-major tensor, M for an M-major one.  Size the TiledCopy so its
    # tiler == one EPI_TILE: the load warp's threads x values cover a
    # whole sub-tile in one shot (across-sub-tile iteration is the
    # pipeline loop over EPI_M x EPI_N).
    epi_m = cute.size(epi_tile[0])
    epi_n = cute.size(epi_tile[1])

    def build_tiled_copy(contig_mode):
        """Tile one EPI_TILE with the ``copy_elems``-element cp.async
        vector along ``contig_mode`` (0 = M, 1 = N).  The thread/value
        layouts keep (M, N) mode order with the contiguous axis
        innermost; the other axis carries one cp.async atom per thread
        step.  Returns the TiledCopy and the strided (non-contiguous)
        mode whose stride the alignment proof must constrain."""
        extents = (epi_m, epi_n)
        strided_mode = 1 - contig_mode
        assert extents[contig_mode] % copy_elems == 0, (
            f"EPI_TILE contiguous dim ({extents[contig_mode]}) must be a "
            f"multiple of copy_elems ({copy_elems})"
        )
        t_contig = extents[contig_mode] // copy_elems
        t_strided = num_load_warp_threads // t_contig
        assert t_contig > 0 and t_contig * t_strided == num_load_warp_threads, (
            f"load warp ({num_load_warp_threads} threads) does not split "
            f"evenly over EPI_TILE {extents} with copy_elems {copy_elems}"
        )
        assert extents[strided_mode] % t_strided == 0, (
            f"EPI_TILE strided dim ({extents[strided_mode]}) must be a "
            f"multiple of T ({t_strided})"
        )
        v_strided = extents[strided_mode] // t_strided

        # Place a (contiguous, strided) pair onto physical (M, N) modes.
        def mn(contig, strided):
            return (contig, strided) if contig_mode == 0 else (strided, contig)

        thread_layout = cute.make_layout(
            mn(t_contig, t_strided), stride=mn(1, t_contig)
        )
        value_layout = cute.make_layout(
            mn(copy_elems, v_strided), stride=mn(1, copy_elems)
        )
        return cute.make_tiled_copy_tv(atom, thread_layout, value_layout), strided_mode

    # The cp.async vector follows the read tensor's own contiguous axis
    # (its sC is staged from this tensor's layout).
    read_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(raw_gmem_tensor)
    tiled_copy_g2s, strided_mode = build_tiled_copy(
        1 if read_layout.is_n_major_c() else 0
    )

    # Render this cp.async copy's TV map.
    maybe_dump_tv_latex(
        tiled_copy_g2s,
        f"g2s_cpasync_{dtype.__name__}_{num_bits_per_copy}b",
        context=(
            f"{type(self).__module__}.{type(self).__qualname__}\n"
            "epilogue_gmem_copy_and_partition_async\n"
            f"G2S: cp.async GMEM->SMEM (async-staged load), "
            f"{dtype.__name__} {num_bits_per_copy}b, "
            f"{num_load_warp_threads}-thread load warp"
        ),
    )

    # Rebuild the source tensor carrying two alignment facts the
    # cp.async copy needs, on the flat ``(M, N, L)`` layout (before
    # ``local_tile``, so the strides are plain scalars):
    #   1. the strided (non-contiguous) axis stride is divisible by
    #      ``copy_elems`` elements (``cute.assume`` on it), so every
    #      contiguous run stays atom-aligned -- the M stride for an
    #      N-major tensor, the N stride for an M-major one;
    #   2. the base pointer is ``copy_elems * element_size`` byte
    #      aligned (``make_ptr(assumed_align=...)``).
    bytes_per_atom = copy_elems * dtype.width // 8
    old_layout = raw_gmem_tensor.layout
    s0, s1, s2 = old_layout.stride[0], old_layout.stride[1], old_layout.stride[2]
    if strided_mode == 0:
        s0 = cute.assume(s0, copy_elems)
    else:
        s1 = cute.assume(s1, copy_elems)
    new_layout = cute.make_layout(old_layout.shape, stride=(s0, s1, s2))
    old_iter = raw_gmem_tensor.iterator
    aligned_iter = cute.make_ptr(
        old_iter.dtype,
        old_iter.toint(),
        old_iter.memspace,
        assumed_align=bytes_per_atom,
    )
    mC_mnl = cute.make_tensor(aligned_iter, new_layout)

    # ``local_tile`` by the MMA tiler gives the 2-CTA tile
    # ``(bM, bN, tiles_m, tiles_n, tiles_l)``.
    gC_mnl = cute.local_tile(
        mC_mnl,
        cute.slice_(self.mma_tiler, (None, None, 0)),
        (None, None, None),
    )
    # Select this CTA's M-slice of the 2-CTA tile (a no-op for a 1-CTA
    # MMA), matching the per-CTA accumulator the consumer iterates.
    # ``zipped_divide`` by the per-CTA bM splits ``gC_mnl``'s leading mode
    # into ``(cta_bM, cta_group_size)``; the coord keeps every "rest" mode
    # (the remaining ``cta_group_size, bN, tiles_m, tiles_n, tiles_l``) and
    # selects this CTA's chunk via its V-coord.
    cta_group_size = cute.size(self._tiled_mma.thr_id.shape)
    gC_mnl = cute.local_tile(
        gC_mnl,
        (self.mma_tiler[0] // cta_group_size,),
        (cute.arch.block_idx()[0] % cta_group_size, None, None, None, None),
    )
    # ``flat_divide`` by ``epi_tile`` splits the per-CTA ``(bM, bN)`` into
    # the per-sub-tile extent and the sub-tile grid:
    #   (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, tiles_m, tiles_n, tiles_l)
    gC_epi = cute.flat_divide(gC_mnl, epi_tile)
    thr_copy_g2s = tiled_copy_g2s.get_slice(lane_idx)
    # The TiledCopy tiler == one EPI_TILE, so ``partition_S`` adds no
    # per-thread iteration: the ``M_iter`` / ``N_iter`` modes it would
    # otherwise insert between the copy unit and the sub-tile grid are
    # both 1.  partition_S yields, for gmem,
    #   ((atom_v, rest_v), 1, 1, EPI_M, EPI_N, tiles_m, tiles_n, tiles_l)
    # and for smem, ((atom_v, rest_v), 1, 1, STAGES).  Index the two
    # size-1 modes out to land on ``(copy_unit, EPI_M, EPI_N, tiles...)``
    # and ``(copy_unit, STAGES)`` -- the shapes
    # ``prepare_tensor_load_for_subtiles`` / ``load_tensor_subtiles``
    # consume, identical to the TMA path's ``tma_partition`` output.
    bGS_gC = thr_copy_g2s.partition_S(gC_epi)[
        (None, 0, 0, None, None, None, None, None)
    ]
    bGS_sC = thr_copy_g2s.partition_D(sC)[(None, 0, 0, None)]
    return tiled_copy_g2s, bGS_sC, bGS_gC


def epilogue_gmem_copy_and_partition_non_tma(
    self,
    tidx: cutlass.Int32,
    tiled_copy_t2r: cute.TiledCopy,
    tCgC: cute.Tensor,
    epi_tile: cute.Tile,
    dtype: type[cutlass.Numeric],
    num_bits_per_copy: int | None = None,
) -> tuple[cute.CopyAtom, cute.Tensor, cute.Tensor]:
    """Build a per-thread per-subtile partition for a synchronous direct
    global-memory copy on a GMEM tensor previously partitioned through
    ``thr_mma.partition_C``.

    Mirrors the ``epilog_gmem_copy_and_partition_non_tma`` pattern in
    ``examples/CuTeDSL/cute/blackwell/kernel/dense_gemm/dense_gemm_vector_alpha_beta_bias_persistent.py``
    and the no-TMA-store epilogue in ``cutlass.utils.gemm.sm100.epilogue``,
    where the same partition shape works for both direct-read operands and
    direct-write outputs because ``partition_D`` is direction-agnostic.

    :param tidx: thread index inside the epilogue warp group.
    :param tiled_copy_t2r: the accumulator's TMEM-to-register tiled copy,
        whose thread layout determines the per-thread shape that the
        body already operates on (no retile needed for the EFC body).
    :param tCgC: the MMA-partitioned GMEM tensor (output of
        ``thr_mma.partition_C(g)``), shape
        ``((MMA_inner1, MMA_inner2), MMA_M, MMA_N, RestM, RestN, RestL)``.
    :param epi_tile: the epilogue subtile shape.
    :param dtype: element type of the GMEM tensor.
    :param num_bits_per_copy: width of one direct gmem transaction, in bits.
        ``None`` derives it from the partition's max-common-layout
        (capped at 256 bits) so the copy is as wide as alignment permits;
        an explicit integer forces that exact width.
    :returns: ``(atom, tTR_rC, tTR_gC)`` where ``atom`` is the synchronous
        ``CopyUniversalOp`` atom, ``tTR_rC`` is a per-thread per-subtile
        register fragment shaped ``(T2R, T2R_M, T2R_N)``, and ``tTR_gC``
        is the per-thread GMEM partition shaped
        ``(T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL)``.
    """
    # No TV dump: the direct (synchronous) GMEM load/store partition reuses ``tiled_copy_t2r``
    # (only the atom differs), so its TV map is the ``t2r_acc`` dump.
    # Drop the (MMA_M, MMA_N) modes by selecting index 0 -- the partition
    # is uniform across MMA tiles, so flat_divide on the resulting
    # (MMA_inner, RestM, RestN, RestL) shape gives the per-subtile axes.
    gC_epi = cute.flat_divide(tCgC[((None, None), 0, 0, None, None, None)], epi_tile)
    thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
    # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL)
    tTR_gC = thr_copy_t2r.partition_D(gC_epi)
    # (T2R, T2R_M, T2R_N) -- per-thread per-subtile register fragment.
    tTR_rC = cute.make_rmem_tensor(
        tTR_gC[(None, None, None, 0, 0, 0, 0, 0)].shape, dtype
    )
    if num_bits_per_copy is None:
        # Auto-derive width from layout alignment, mirroring
        # ``cutlass.utils.gemm.sm100.epilogue``.
        mclD = cute.max_common_layout(
            tTR_rC.layout, tTR_gC[(None, None, None, 0, 0, 0, 0, 0)].layout
        )
        num_bits_per_copy = min(
            tTR_gC.iterator.alignment * 8,
            cute.size(mclD) * dtype.width,
            256,
        )
    atom = cute.make_copy_atom(
        cute.nvgpu.CopyUniversalOp(),
        dtype,
        num_bits_per_copy=num_bits_per_copy,
    )
    return atom, tTR_rC, tTR_gC
