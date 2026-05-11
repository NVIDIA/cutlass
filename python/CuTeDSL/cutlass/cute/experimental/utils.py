# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from typing import Callable, Optional, Tuple, Union

import cutlass
from cutlass import cute
from cutlass._mlir import ir

from ... import cutlass_dsl as _dsl
from .pipeline import TMAStorePipeline, TMAToUMMAPipeline


def get_cta_v_map_ab(
    gmem_tensor: cute.Tensor,
    mma_tiler_mnk: cute.Shape,
    tiled_mma: cute.TiledMma,
    input_operand: str,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[cute.Layout, cute.ComposedLayout]:
    ident = cute.core.make_identity_layout(gmem_tensor.shape, loc=loc, ip=ip)
    mode = 0 if (input_operand in ("A", "SFA")) else 1
    mma_tiler_mk = (mma_tiler_mnk[mode], *mma_tiler_mnk[2:])  # type: ignore[index]
    g_tile = cute.core.composition(ident, mma_tiler_mk, loc=loc, ip=ip)
    if input_operand in ("A", "SFA"):
        cta_v_map = tiled_mma._thrfrg_A(g_tile)
    if input_operand in ("B", "SFB"):
        cta_v_map = tiled_mma._thrfrg_B(g_tile)
    cta_v_map = cute.core.get(cta_v_map, mode=[1])  # type: ignore[assignment]
    cta_v_map = cute.core.dice(cta_v_map, (1, (1,) * cute.core.rank(g_tile)))  # type: ignore[assignment]
    return cta_v_map  # type: ignore[return-value]



def get_cta_v_map_c(
    gmem_tensor: cute.Tensor,
    epi_tile: Union[cute.Tile, cute.Shape],
) -> cute.Layout:
    return cute.composition(cute.make_identity_layout(gmem_tensor.shape), epi_tile)


def make_tmem_layout_acc(
    tiled_mma: cute.TiledMma,
    mnk_tiler: cute.Shape,
    acc_stage: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return TMEM accumulator buffer layout for a tiled MMA.

    This is a small helper around ``tiled_mma.make_fragment_C(...).layout`` to
    keep example code fragment-free at the call site.

    Args:
        tiled_mma: The MMA tiler (``cute.TiledMma``).
        mnk_tiler: Full MNK tiler; only the MN components are used for C.
        acc_stage: Accumulator pipeline stages.
        loc: Optional location for DSL ops.
        ip: Optional insertion point for DSL ops.

    Returns:
        ``cute.Layout`` for the accumulator TMEM buffer.
    """
    acc_shape = tiled_mma.partition_shape_C(mnk_tiler[:2], loc=loc, ip=ip)  # type: ignore[index]
    acc_shape_staged = cute.append(acc_shape, acc_stage, loc=loc, ip=ip)
    return tiled_mma.make_fragment_C(acc_shape_staged, loc=loc, ip=ip).layout


def make_tmem_layout_a(
    tiled_mma: cute.TiledMma,
    mk_tiler: cute.Shape,
    stage: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return TMEM A operand buffer layout for a tiled MMA.

    Args:
        tiled_mma: The MMA tiler (``cute.TiledMma``).
        mk_tiler: MK tiler used to shape the A operand.
        stage: Pipeline stages for the A operand buffer.
        loc: Optional location for DSL ops.
        ip: Optional insertion point for DSL ops.

    Returns:
        ``cute.Layout`` for the A operand TMEM buffer.
    """
    a_shape = tiled_mma.partition_shape_A(mk_tiler, loc=loc, ip=ip)
    a_shape_staged = cute.append(a_shape, stage, loc=loc, ip=ip)
    return tiled_mma.make_fragment_A(a_shape_staged, loc=loc, ip=ip).layout


def make_t2r_rmem_layout(
    tiled_copy_t2r: cute.TiledCopy,
    gC_mnl_epi: cute.Tensor,
    tidx: cute.Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[cute.Layout, cute.ComposedLayout]:
    """Return RMEM buffer layout for the T2R epilogue destination.

    Computes the per-thread RMEM buffer layout produced by a TMEM->RMEM copy
    for a single epilogue iteration.

    Args:
        tiled_copy_t2r: The TMEM->RMEM tiled copy op (``cute.TiledCopy``).
        gC_mnl_epi: Global C tensor partitioned by epilogue tile.
        tidx: Thread index for the copy slice.
        loc: Optional location for DSL ops.
        ip: Optional insertion point for DSL ops.

    Returns:
        ``cute.Layout`` for the RMEM buffer.
    """
    thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
    tTR_gC = thr_copy_t2r.partition_D(gC_mnl_epi, loc=loc, ip=ip)
    return cute.make_fragment_like(
        tTR_gC[(None, None, None, 0, 0)].layout, loc=loc, ip=ip
    )


@_dsl.CuteExperimentalDSL.jit
def epilogue_tma_store(
    cta_tile_shape_mnk: cute.Shape,
    use_2cta_instrs: bool,
    tmem_acc_buffer_staged: cute.Tensor,
    gmem_d: cute.Tensor,
    cta_d_tile_coord: cute.Coord,
    tma_store_pipeline: TMAStorePipeline,
    tma_store_warp_id: int,
    epilogue_op: Callable[[cute.Tensor], cute.Tensor],
    d_major_mode: Optional["LayoutEnum"] = None,  # type: ignore[name-defined]
    tid_x_in_group: Optional[int] = None,
) -> TMAStorePipeline:
    """
    Epilogue phase: copy accumulator from TMEM to GMEM via RMEM and TMA store.

    This function implements the epilogue for GEMM on Blackwell (SM100): it consumes
    the accumulator produced by the MMA warp and writes the output tile to global
    memory. The data flow is:

        TMEM --copy--> RMEM --epilogue op--> RMEM --copy--> SMEM --TMA--> GMEM

    The TMA store pipeline coordinates multiple warps writing to SMEM before a single
    warp (tma_store_warp_id) issues the TMA store. Pipeline protocol per sub-tile:
    acquire_sync() -> RMEM->SMEM copy -> commit_sync() -> TMA store (TMA warp only)
    -> release_advance(). tail() is called at the end to wait for in-flight TMA stores.

    Args:
        cta_tile_shape_mnk: Effective (M, N, K) tile shape per CTA for epilogue tiling
        use_2cta_instrs: True if using 2-CTA MMA instructions (affects epilogue tile shape)
        tmem_acc_buffer_staged: One stage slice from the full accumulator pipeline for
            this CTA's tile, should have shape
            (cta_tile_shape_mnk[0], cta_tile_shape_mnk[1], 1, 1)
        gmem_d: Global output tensor D
        cta_d_tile_coord: Coordinate of this CTA's output tile, e.g. (cta_m, cta_n, cta_l)
        tma_store_pipeline: TMAStorePipeline instance
        tma_store_warp_id: Warp index that issues TMA stores
        epilogue_op: Callable applied in registers to accumulator values before store
        d_major_mode: LayoutEnum for d_tensor, the function will automatically detect
            the d_major_mode from gmem_d if not provided
        tid_x_in_group: Thread index in the group of warps that issue TMA stores. For
            example, if warps 4-7 are in the same group and calling this function,
            tid_x_in_group should be 0-127 instead of 128-255. If not provided, the
            function will use cute.arch.thread_idx().

    Returns:
        tma_store_pipeline: The updated TMAStorePipeline instance
    """
    from .algorithm import partition_and_copy
    from .memory import allocate, tma_store
    import cutlass.utils.blackwell_helpers as blackwell_helpers
    from cutlass import utils as utils

    if cutlass.const_expr(tid_x_in_group is None):
        tid_x_in_group, _, _ = cute.arch.thread_idx()
        tid_x_in_group = tid_x_in_group % 128
    warp_idx = cute.arch.warp_idx()
    warp_idx = cute.arch.make_warp_uniform(warp_idx)

    acc_dtype = tmem_acc_buffer_staged.element_type
    d_dtype = gmem_d.element_type
    if cutlass.const_expr(d_major_mode is None):
        d_major_mode = utils.LayoutEnum.from_tensor(gmem_d)

    epi_tile_shape = blackwell_helpers.compute_epilogue_tile_shape(
        cta_tile_shape_mnk,
        use_2cta_instrs,
        d_major_mode,
        d_dtype,
    )

    copy_atom_t2r = blackwell_helpers.get_tmem_load_op(
        cta_tile_shape_mnk,
        d_major_mode,
        d_dtype,
        acc_dtype,
        epi_tile_shape,
        use_2cta_instrs,
    )

    acc_epi_div_tiled = cute.flat_divide(tmem_acc_buffer_staged, epi_tile_shape)
    acc_epi_div_slice = acc_epi_div_tiled[None, None, 0, 0]
    tiled_copy_t2r = cute.nvgpu.tcgen05.make_tmem_copy(copy_atom_t2r, acc_epi_div_slice)
    tiled_copy_r2s = cute.make_tiled_copy_D(
        cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), d_dtype),
        tiled_copy_t2r,
    )

    tiler_mn = (cta_tile_shape_mnk[0], cta_tile_shape_mnk[1])  # type: ignore[index]
    gmem_d_mn_tiled = cute.zipped_divide(gmem_d, tiler_mn)
    gmem_d_tile = gmem_d_mn_tiled[(None, None), cta_d_tile_coord]
    gmem_d_epi_tma = cute.flat_divide(gmem_d_tile, epi_tile_shape)  # type: ignore[arg-type]
    epi_subtile_cnt = gmem_d_epi_tma.shape[3]  # type: ignore[index]

    acc_d_rmem_layout = make_t2r_rmem_layout(
        tiled_copy_t2r,
        gmem_d_epi_tma,
        tid_x_in_group,  # type: ignore[arg-type]
    )
    rmem_acc_buffer = allocate(
        acc_dtype,
        cute.AddressSpace.rmem,
        acc_d_rmem_layout,
        alignment=32,
    )
    rmem_d_buffer = allocate(
        d_dtype,
        cute.AddressSpace.rmem,
        acc_d_rmem_layout,
        alignment=32,
    )

    d_smem_layout_staged = blackwell_helpers.make_smem_layout_epi(
        d_dtype,
        d_major_mode,
        epi_tile_shape,
        tma_store_pipeline.get_num_stages(),
    )
    smem_d_buffer = allocate(
        d_dtype,
        cute.AddressSpace.smem,
        d_smem_layout_staged,
        alignment=1024,
    )

    for epi_subtile_idx in range(epi_subtile_cnt):  # type: ignore[arg-type]
        # TMEM -> RMEM
        partition_and_copy(
            tiled_copy_t2r.get_slice(tid_x_in_group),
            acc_epi_div_tiled[None, None, 0, epi_subtile_idx],
            rmem_acc_buffer,
        )

        # RMEM -> RMEM and epilogue Op
        acc_vec = rmem_acc_buffer.load()
        epilogue_out = epilogue_op(acc_vec.to(d_dtype))
        rmem_d_buffer.store(epilogue_out)

        # RMEM -> SMEM
        # The TMA store pipeline coordinates multiple warps writing to SMEM
        # before a single warp issues the TMA store.
        # acquire_sync():
        # - TMA warp waits for any in-flight TMA ops to complete
        # - All warps synchronize via a named barrier
        tma_store_pipeline.acquire_sync()
        store_idx = tma_store_pipeline.get_index()
        partition_and_copy(
            tiled_copy_r2s.get_slice(tid_x_in_group),
            rmem_d_buffer,
            smem_d_buffer[None, None, store_idx],
        )

        # commit_sync():
        # - Fences SMEM writes to ensure visibility for TMA
        # - All warps synchronize before TMA store
        # This is CRITICAL: TMA must see committed SMEM writes
        tma_store_pipeline.commit_sync()

        # SMEM -> GMEM
        if warp_idx == tma_store_warp_id:
            tma_store(
                smem_d_buffer[None, None, store_idx],
                gmem_d_epi_tma[None, None, 0, epi_subtile_idx],
            )

        # release_advance():
        # - TMA warp commits TMA ops to bulk group
        # - All warps advance to the next pipeline stage
        tma_store_pipeline.release_advance()

    tma_store_pipeline.tail()
    return tma_store_pipeline


@_dsl.CuteExperimentalDSL.jit
def mainloop_mma(
    tiled_mma: cute.TiledMma,
    a_buffer: cute.Tensor,
    b_buffer: cute.Tensor,
    acc_buffer: cute.Tensor,
    k_tile_start: cute.Int32,
    k_tile_end: cute.Int32,
    mma_inst_tile_k: cute.Int32,
    a_buffer_pipeline: TMAToUMMAPipeline,
    b_buffer_pipeline: TMAToUMMAPipeline,
    ab_buffer_same_pipeline: bool = True,
    accumulate_to_acc: bool = False,
) -> Tuple[TMAToUMMAPipeline, TMAToUMMAPipeline]:
    """
    Mainloop MMA phase: consume A/B tiles from the pipeline and compute into TMEM accumulator.

    This function is the consumer side of the TMA load -> MMA pipeline. It waits
    for the TMA load warp to fill a pipeline stage, then runs multiple MMA
    instructions over the K-tile (inner loop over mma_inst_tile_k), and releases the stage.

    Args:
        tiled_mma: Tiled MMA descriptor (e.g. from blackwell_helpers.make_trivial_tiled_mma)
        a_buffer: A operand buffer, shape (..., mma_inst_tile_k, num_a_buffer_stages)
        b_buffer: B operand buffer, shape (..., mma_inst_tile_k, num_b_buffer_stages)
        acc_buffer: Accumulator buffer for this CTA's tile
        k_tile_start: Start index of the K-tile to iterate over (outer loop)
        k_tile_end: End index of the K-tile to iterate over (outer loop)
        mma_inst_tile_k: Number of MMA instructions per K-tile (inner loop)
        a_buffer_pipeline: TMAToUMMAPipeline to sync with TMA load producer for A buffer
        b_buffer_pipeline: TMAToUMMAPipeline to sync with TMA load producer for B buffer
        ab_buffer_same_pipeline: If the TMA load producers for A and B are the same pipeline
        accumulate_to_acc: If the first K-tile should accumulate to the accumulator,
            otherwise the result will be overwritten.

    Returns:
        a_buffer_pipeline: The updated TMAToUMMAPipeline for A buffer
        b_buffer_pipeline: The updated TMAToUMMAPipeline for B buffer
    """
    from .math import dot

    mma_atom = cute.make_mma_atom(tiled_mma.op)
    mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, accumulate_to_acc)
    for _k_tile in cutlass.range(k_tile_start, k_tile_end, 1, unroll=1):
        _, a_buffer_stage_idx = a_buffer_pipeline.consumer_wait_and_get_stage()
        if cutlass.const_expr(ab_buffer_same_pipeline):
            b_buffer_stage_idx = a_buffer_stage_idx
        else:
            _, b_buffer_stage_idx = b_buffer_pipeline.consumer_wait_and_get_stage()
        for k_instr_tile in cutlass.range(mma_inst_tile_k, unroll_full=True):
            a_buffer_sliced = a_buffer[None, None, k_instr_tile, a_buffer_stage_idx]
            b_buffer_sliced = b_buffer[None, None, k_instr_tile, b_buffer_stage_idx]
            dot(
                mma_atom,
                cute.append_ones(a_buffer_sliced, up_to_rank=3),  # type: ignore[arg-type]
                cute.append_ones(b_buffer_sliced, up_to_rank=3),  # type: ignore[arg-type]
                acc_buffer,
            )
            mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)
        a_buffer_pipeline.consumer_release_and_advance()
        if not cutlass.const_expr(ab_buffer_same_pipeline):
            b_buffer_pipeline.consumer_release_and_advance()

    return a_buffer_pipeline, b_buffer_pipeline
