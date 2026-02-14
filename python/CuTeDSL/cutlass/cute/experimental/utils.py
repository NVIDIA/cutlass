# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from cutlass import cute


def get_cta_v_map_ab(
    gmem_tensor,
    mma_tiler_mnk,
    tiled_mma,
    input_operand,
    *,
    loc=None,
    ip=None,
):
    """
    Build the **CTA-to-value map** (aka **CTA V-map**) layout for a TMA load of A/B
    (and scale-factor variants SFA/SFB).

    In practice, `cta_v_map` is a `cute.Layout` that tells TMA how this CTA’s
    portion of a global tensor tile maps onto the values being transferred into
    shared memory.

    :param gmem_tensor: Global-memory tensor being loaded by TMA.
    :type gmem_tensor: cute.Tensor
    :param mma_tiler_mnk: The (M,N,K,...) tiler describing the CTA tile shape.
    :type mma_tiler_mnk: tuple
    :param tiled_mma: The tiled MMA object used to derive the per-operand thread/value mapping.
    :type tiled_mma: cute.core.TiledMma
    :param input_operand: One of {"A","B","SFA","SFB"} selecting which operand mapping to use.
    :type input_operand: str
    :returns: A layout suitable to pass as `cta_v_map=...` to `tma_load` / `tma_load_multicast`.
    :rtype: cute.Layout
    """
    ident = cute.core.make_identity_layout(gmem_tensor.shape, loc=loc, ip=ip)
    mode = 0 if (input_operand in ("A", "SFA")) else 1
    mma_tiler_mk = (mma_tiler_mnk[mode], *mma_tiler_mnk[2:])
    g_tile = cute.core.composition(ident, mma_tiler_mk, loc=loc, ip=ip)
    if input_operand in ("A", "SFA"):
        cta_v_map = tiled_mma._thrfrg_A(g_tile)
    if input_operand in ("B", "SFB"):
        cta_v_map = tiled_mma._thrfrg_B(g_tile)
    cta_v_map = cute.core.get(cta_v_map, mode=[1])
    cta_v_map = cute.core.dice(cta_v_map, (1, (1,) * cute.core.rank(g_tile)))
    return cta_v_map


def get_cta_v_map_c(
    gmem_tensor,
    epi_tile,
    *,
    loc=None,
    ip=None,
):
    """
    Build the **CTA-to-value map** (aka **CTA V-map**) layout for a TMA store/load
    of the output tensor C/D.

    This returns an identity layout over the global tensor composed with the
    epilogue tile, yielding a `cute.Layout` that describes which global indices
    this CTA is responsible for.

    :param gmem_tensor: Global-memory tensor being stored/loaded by TMA.
    :type gmem_tensor: cute.Tensor
    :param epi_tile: Epilogue tile layout describing the CTA's output tile shape.
    :type epi_tile: cute.Layout
    :returns: A layout suitable to pass as `cta_v_map=...` to `tma_store` / `tma_load`.
    :rtype: cute.Layout
    """
    ident = cute.core.make_identity_layout(gmem_tensor.shape, loc=loc, ip=ip)
    return cute.core.composition(ident, epi_tile, loc=loc, ip=ip)


def make_tmem_layout_acc(
    tiled_mma,
    mnk_tiler,
    acc_stage,
    *,
    loc=None,
    ip=None,
):
    """Return TMEM accumulator buffer layout for a tiled MMA.

    This is a small helper around ``tiled_mma.make_fragment_C(...).layout`` to
    keep example code fragment-free at the call site.

    :param tiled_mma: The MMA tiler (``cute.TiledMma``).
    :type tiled_mma: cute.TiledMma
    :param mnk_tiler: Full MNK tiler; only the MN components are used for C.
    :type mnk_tiler: tuple
    :param acc_stage: Accumulator pipeline stages.
    :param loc: Optional location for DSL ops.
    :param ip: Optional insertion point for DSL ops.
    :return: Layout for the accumulator TMEM buffer.
    :rtype: cute.Layout
    """
    acc_shape = tiled_mma.partition_shape_C(mnk_tiler[:2], loc=loc, ip=ip)
    acc_shape_staged = cute.append(acc_shape, acc_stage, loc=loc, ip=ip)
    return tiled_mma.make_fragment_C(acc_shape_staged, loc=loc, ip=ip).layout


def make_tmem_layout_a(
    tiled_mma,
    mk_tiler,
    stage,
    *,
    loc=None,
    ip=None,
):
    """Return TMEM A operand buffer layout for a tiled MMA.

    :param tiled_mma: The MMA tiler (``cute.TiledMma``).
    :type tiled_mma: cute.TiledMma
    :param mk_tiler: MK tiler used to shape the A operand.
    :type mk_tiler: tuple
    :param stage: Pipeline stages for the A operand buffer.
    :param loc: Optional location for DSL ops.
    :param ip: Optional insertion point for DSL ops.
    :return: Layout for the A operand TMEM buffer.
    :rtype: cute.Layout
    """
    a_shape = tiled_mma.partition_shape_A(mk_tiler, loc=loc, ip=ip)
    a_shape_staged = cute.append(a_shape, stage, loc=loc, ip=ip)
    return tiled_mma.make_fragment_A(a_shape_staged, loc=loc, ip=ip).layout


def make_t2r_rmem_layout(
    tiled_copy_t2r,
    gC_mnl_epi,
    tidx,
    *,
    loc=None,
    ip=None,
):
    """Return RMEM buffer layout for the T2R epilogue destination.

    Computes the per-thread RMEM buffer layout produced by a TMEM->RMEM copy
    for a single epilogue iteration.

    :param tiled_copy_t2r: The TMEM->RMEM tiled copy op (``cute.TiledCopy``).
    :type tiled_copy_t2r: cute.TiledCopy
    :param gC_mnl_epi: Global C tensor partitioned by epilogue tile.
    :type gC_mnl_epi: cute.Tensor
    :param tidx: Thread index for the copy slice.
    :param loc: Optional location for DSL ops.
    :param ip: Optional insertion point for DSL ops.
    :return: Layout for the RMEM buffer.
    :rtype: cute.Layout
    """
    thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
    tTR_gC = thr_copy_t2r.partition_D(gC_mnl_epi, loc=loc, ip=ip)
    return cute.make_fragment_like(
        tTR_gC[(None, None, None, 0, 0)].layout, loc=loc, ip=ip
    )
