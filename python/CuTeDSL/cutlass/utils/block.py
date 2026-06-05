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


from cutlass.cutlass_dsl import dsl_user_op, CuTeDSL

from cutlass.cute.typing import Tensor
from cutlass.cute.core import make_layout, filter_zeros
from cutlass.cute.atom import TiledCopy
from cutlass.cute.algorithm import copy
from cutlass.cute.nvgpu import tcgen05
from cutlass.cute.nvgpu.cpasync.copy import (
    TmaCopyOp,
    CopyBulkTensorTileG2SOp,
    CopyBulkTensorTileG2SMulticastOp,
)
from cutlass.cute.nvgpu.cpasync.helpers import tma_partition
from cutlass.cute.nvgpu.tcgen05.copy import _S2TCopyBase
from typing import Any, Optional
from cutlass._mlir import ir


def _check_required_args(
    required_args: list[str], kwargs: dict, condition: bool = True
) -> None:
    if not condition:
        return
    for arg in required_args:
        if arg not in kwargs:
            raise ValueError(f"Argument {arg} is required.")


def _tma_copy_impl(
    tiled_copy: TiledCopy,
    src: Tensor,
    dst: Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
    **kwargs: Any,
) -> None:
    """Internal implementation for TMA-based block-level copy."""
    #
    # Handle tma_multicast argument
    #
    if "tma_multicast" in kwargs:
        if not isinstance(
            tiled_copy.op,
            (
                CopyBulkTensorTileG2SOp,
            ),
        ):
            raise ValueError(
                "block_copy with tma_multicast expects a non-multicast G2S TMA copy atom "
                "(CopyBulkTensorTileG2SOp) for compiler-driven multicast"
            )
        # Mark as coming from block API
        kwargs["tma_multicast"]["from_block_api"] = True

    #
    # Check if required arguments are provided
    #
    is_bar_ptr_required = isinstance(
        tiled_copy.op,
        (
            CopyBulkTensorTileG2SOp,
            CopyBulkTensorTileG2SMulticastOp,
        ),
    )
    _check_required_args(["tma_bar_ptr"], kwargs, is_bar_ptr_required)

    #
    # TMA bulk tensor copies: partition via tma_partition
    #
    is_g2s = isinstance(
        tiled_copy.op,
        (
            CopyBulkTensorTileG2SOp,
        ),
    )
    stensor = dst if is_g2s else src
    gtensor = src if is_g2s else dst
    cta_coord = 0
    cta_layout = make_layout(1, loc=loc, ip=ip)
    s_ptn, g_ptn = tma_partition(
        tiled_copy, cta_coord, cta_layout, stensor, gtensor, loc=loc, ip=ip
    )

    s_ptn = filter_zeros(s_ptn)
    g_ptn = filter_zeros(g_ptn)

    src_arg = g_ptn if is_g2s else s_ptn
    dst_arg = s_ptn if is_g2s else g_ptn
    return copy(tiled_copy, src_arg, dst_arg, loc=loc, ip=ip, **kwargs)


def _utccp_copy_impl(
    tiled_copy: TiledCopy,
    src: Tensor,
    dst: Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
    **kwargs: Any,
) -> None:
    """Internal implementation for S2T (SMEM to TMEM) copy operations.

    This function abstracts the S2T copy pattern which involves:
    1. Filtering zeros from src (smem) and dst (tmem) tensors
    2. Creating a tiled copy using make_s2t_copy
    3. Partitioning source and destination
    4. Getting the SMEM descriptor tensor
    5. Executing the copy

    :param tiled_copy: The tiled copy for S2T operations.
    :type tiled_copy: TiledCopy
    :param src: The source tensor in shared memory.
    :type src: Tensor
    :param dst: The destination tensor in TMEM.
    :type dst: Tensor
    """
    # Filter zeros from src (smem) and dst (tmem) tensors
    src_compact = filter_zeros(src)
    dst_compact = filter_zeros(dst)

    # S2T has a single thread slice; election handled automatically in lowering
    thr_copy = tiled_copy.get_slice(0)

    # Partition source and destination
    src_partitioned = thr_copy.partition_S(src_compact, loc=loc, ip=ip)
    dst_partitioned = thr_copy.partition_D(dst_compact, loc=loc, ip=ip)

    # Get SMEM descriptor tensor for the source
    smem_desc_tensor = tcgen05.get_s2t_smem_desc_tensor(
        tiled_copy, src_partitioned, loc=loc, ip=ip
    )

    # Execute the copy
    return copy(tiled_copy, smem_desc_tensor, dst_partitioned, loc=loc, ip=ip, **kwargs)


@dsl_user_op
@CuTeDSL.jit
def block_copy(
    tiled_copy: TiledCopy,
    src: Tensor,
    dst: Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
    **kwargs: Any,
) -> None:
    """Performs a block-level copy operation.

    This function adds an abstraction layer over the `cute.copy` usage model by
    allowing operands with layouts shaped like tiles to be passed directly. This
    removes the need to manually partition. The API is designed to support multiple
    copy kinds; currently TMA-based copies and S2T (SMEM to TMEM) copies are supported.

    **TMA copy requirements**:

    When using TMA-based tiled copies, the ``src`` and ``dst`` tensors must have
    their first mode representing the TMATile, i.e. tensors shaped as ``(TMATile, Rest...)``.
    For a rank-2 tensor with logical layout (e.g., ``(TILE_M, TILE_N)``), call
    ``group_modes(tensor, 0, 2)`` before passing it to this function.

    **TMA multicast support**:

    For TMA-based copies that enable compiler-driven multicast in a 2D cluster, pass the
    ``tma_multicast`` argument as a dict with the following keys:

      - ``cluster_shape``: a tuple of 2 integers ``(cluster_m, cluster_n)``
        representing the **2D cluster shape**.
      - ``multicast_dim``: either ``"M"`` or ``"N"`` indicating which
        cluster dimension the multicast happens along.
      - ``use_2cta_mma_inst`` (optional): a ``bool`` indicating whether to
        use 2CTA MMA instructions when the loaded data is consumed by MMA.
        Defaults to ``False`` when omitted.

    **S2T (SMEM to TMEM) copy**:

    When using S2T copy operations (e.g., ``tcgen05.Cp4x32x128bOp``), the function
    automatically handles the filtering, partitioning, and SMEM descriptor creation.
    Pass a copy atom created with ``cute.make_copy_atom(tcgen05.Cp*Op(...), dtype)``
    along with source (SMEM) and destination (TMEM) tensors.

    Examples:

    .. code-block:: python

        # 1) TMA load without compiler-driven multicast
        #    Note: group_modes is called to make the first mode TMATile
        block_copy(tma_atom_a, group_modes(tCgA_, 0, 2), group_modes(tCsA_, 0, 2),
                   tma_bar_ptr=tma_bar_ptr)

        # 2) TMA load with compiler-driven multicast along M in a (4,2) cluster
        block_copy(
            tma_atom_a,
            group_modes(tCgA_, 0, 2),
            group_modes(tCsA_, 0, 2),
            tma_multicast={
                "cluster_shape": (4, 2),
                "multicast_dim": "M",
                "use_2cta_mma_inst": True,
            },
            tma_bar_ptr=tma_bar_ptr,
        )

        # 3) TMA store
        #    Note that `tma_bar_ptr` and CTA params (`cta_coord` and `cta_layout`)
        #    are not needed for TMA store
        block_copy(tma_atom_c, group_modes(tCsC_, 0, 2), group_modes(tCgC_, 0, 2))

        # 4) S2T copy (SMEM to TMEM)
        copy_atom_s2t = cute.make_copy_atom(
            tcgen05.Cp4x32x128bOp(tcgen05.CtaGroup.ONE), sf_dtype
        )
        block_copy(copy_atom_s2t, tCsSF, tCtSF)

    :param tiled_copy: The tiled_copy or copy_atom of the current copy operation.
    :type tiled_copy: TiledCopy
    :param src: The source tensor.
    :type src: Tensor
    :param dst: The destination tensor.
    :type dst: Tensor
    :param tma_multicast: Optional dict for TMA multicast configuration with keys
                          ``cluster_shape``, ``multicast_dim``, and optionally
                          ``use_2cta_mma_inst``.
    :type tma_multicast: dict, optional
    """
    import cutlass  # local import to avoid circular import at module load time

    if cutlass.const_expr(isinstance(tiled_copy.op, TmaCopyOp)):
        return _tma_copy_impl(tiled_copy, src, dst, loc=loc, ip=ip, **kwargs)
    elif cutlass.const_expr(isinstance(tiled_copy.op, _S2TCopyBase)):
        return _utccp_copy_impl(tiled_copy, src, dst, loc=loc, ip=ip, **kwargs)
    else:
        raise NotImplementedError(
            f"Copy op {type(tiled_copy.op).__name__} is not supported yet."
        )
