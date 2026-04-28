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

from typing import Optional, Tuple, Type, Union

from cutlass import const_expr
from cutlass.base_dsl.arch import Arch
from cutlass.cutlass_dsl import BaseDSL, dsl_user_op

import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir.dialects import llvm

from ...typing import (
    Coord,
    Layout,
    ComposedLayout,
    Tensor,
    Tiler,
    Pointer,
    Int16,
    Int32,
    Int64,
    Numeric,
    NumericMeta,
)
from ... import core, atom, arch as cute_arch
from .copy import (
    CopyBulkTensorTileG2SOp,
    CopyBulkTensorTileG2SMulticastOp,
    CopyBulkTensorTileS2GOp,
    CopyReduceBulkTensorTileS2GOp,
    CopyBulkTensorTileG2SNonExecTrait,
    CopyBulkTensorTileG2SMulticastNonExecTrait,
    CopyBulkTensorTileS2GNonExecTrait,
    CopyReduceBulkTensorTileS2GNonExecTrait,
)

TMAOp = Union[
    CopyBulkTensorTileG2SOp,
    CopyBulkTensorTileG2SMulticastOp,
    CopyBulkTensorTileS2GOp,
    CopyReduceBulkTensorTileS2GOp,
]


def _check_sm120_tma_load_supported() -> None:
    BaseDSL._get_dsl().check_arch(lambda arch: arch >= Arch.sm_120)


@dsl_user_op
def get_tma_desc_addr(
    tma_atom: atom.CopyAtom,
    *,
    loc=None,
    ip=None,
) -> Pointer:
    """
    Return the address of the tiled TMA descriptor associated with a TMA copy atom.

    This is primarily useful for low-level TMA issue paths that need to bypass
    the generic executable ``cute.copy`` lowering while still using the CuTe DSL
    TMA descriptor builder.
    """
    exec_tma_atom = _cute_nvgpu_ir.atom_make_exec_tma(
        tma_atom._trait.value,
        loc=loc,
        ip=ip,
    )
    tma_desc_ptr_ty = _cute_ir.PtrType.get(
        _cute_nvgpu_ir.TmaDescriptorTiledType.get(),
        _cute_ir.AddressSpace.generic,
        128,
    )
    return _cute_nvgpu_ir.get_tma_desc_addr(
        tma_desc_ptr_ty,
        exec_tma_atom,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def _sm120_issue_tma_load_2d(
    dst_smem_ptr: Pointer,
    tma_desc_ptr: Pointer,
    tma_bar_ptr: Pointer,
    coord0: Int32,
    coord1: Int32,
    *,
    cache_policy: Optional[Int64] = None,
    tile_mode: bool = False,
    loc=None,
    ip=None,
) -> None:
    """
    Unsafe raw SM120 CTA-local rank-2 TMA issuer.

    Callers must ensure only one elected thread issues this instruction for a
    given mbarrier transaction count. Prefer ``sm120_tma_load_2d`` unless the
    caller has already performed election.
    """
    _check_sm120_tma_load_supported()

    dst_smem_i32 = dst_smem_ptr.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    tma_desc_i64 = tma_desc_ptr.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    coord0_i32 = Int32(coord0).ir_value(loc=loc, ip=ip)
    coord1_i32 = Int32(coord1).ir_value(loc=loc, ip=ip)
    tma_bar_i32 = tma_bar_ptr.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)

    tile_qualifier = ".tile" if const_expr(tile_mode) else ""
    if cache_policy is None:
        llvm.inline_asm(
            None,
            [dst_smem_i32, tma_desc_i64, coord0_i32, coord1_i32, tma_bar_i32],
            f"cp.async.bulk.tensor.2d.shared::cta.global{tile_qualifier}.mbarrier::complete_tx::bytes [$0], [$1, {{$2, $3}}], [$4];",
            "r,l,r,r,r",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
            loc=loc,
            ip=ip,
        )
    else:
        cache_policy_i64 = Int64(cache_policy).ir_value(loc=loc, ip=ip)
        llvm.inline_asm(
            None,
            [
                dst_smem_i32,
                tma_desc_i64,
                coord0_i32,
                coord1_i32,
                tma_bar_i32,
                cache_policy_i64,
            ],
            f"cp.async.bulk.tensor.2d.shared::cta.global{tile_qualifier}.mbarrier::complete_tx::bytes.L2::cache_hint [$0], [$1, {{$2, $3}}], [$4], $5;",
            "r,l,r,r,r,l",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
            loc=loc,
            ip=ip,
        )


@dsl_user_op
def sm120_tma_load_2d(
    dst_smem_ptr: Pointer,
    tma_desc_ptr: Pointer,
    tma_bar_ptr: Pointer,
    coord0: Int32,
    coord1: Int32,
    *,
    cache_policy: Optional[Int64] = None,
    already_elected: bool = False,
    tile_mode: bool = False,
    loc=None,
    ip=None,
) -> None:
    """
    Issue a rank-2 SM120 CTA-local TMA load from one elected thread.

    The descriptor must use direct TMA basis: coordinate 0 is the contiguous
    dimension and coordinate 1 is the next slower dimension. For FlashAttention
    ``(seq, d)`` memory this means constructing the descriptor as ``(d, seq)``
    and passing coordinates ``{d_coord, seq_coord}``.

    ``already_elected=True`` is only for callers that have already wrapped this
    call in ``cute.arch.elect_one()`` or an equivalent single-issuer guard.
    """
    if const_expr(already_elected):
        _sm120_issue_tma_load_2d(
            dst_smem_ptr,
            tma_desc_ptr,
            tma_bar_ptr,
            coord0,
            coord1,
            cache_policy=cache_policy,
            tile_mode=tile_mode,
            loc=loc,
            ip=ip,
        )
    else:
        with cute_arch.elect_one(loc=loc, ip=ip):
            _sm120_issue_tma_load_2d(
                dst_smem_ptr,
                tma_desc_ptr,
                tma_bar_ptr,
                coord0,
                coord1,
                cache_policy=cache_policy,
                tile_mode=tile_mode,
                loc=loc,
                ip=ip,
            )


@dsl_user_op
def make_sm120_tma_load_2d_atom(
    gmem_tensor: Tensor,
    smem_layout_: Union[Layout, ComposedLayout],
    cta_tiler: Tiler,
    *,
    internal_type: Optional[Type[Numeric]] = None,
    loc=None,
    ip=None,
) -> Tuple[atom.CopyAtom, Tensor, Pointer]:
    """
    Build a narrow SM120 direct-basis rank-2 TMA load atom.

    This helper deliberately does not canonicalize or logicalize tensor modes.
    The caller must present the tensor in the descriptor basis consumed by TMA:
    mode 0 is the contiguous physical mode and mode 1 is the next slower mode.
    For FlashAttention ``(seq, d)`` GMEM, create a separate direct-basis view
    shaped ``(d, seq)`` with stride ``(1, D)`` before calling this helper.

    The returned descriptor pointer is intended for ``sm120_tma_load_2d``.
    Generic ``cute.copy`` executable TMA lowering remains a separate backend
    path and is not used by this helper.
    """
    _check_sm120_tma_load_supported()

    if core.rank(gmem_tensor) != 2:
        raise ValueError(
            f"SM120 direct TMA load helper expects a rank-2 GMEM tensor, "
            f"but got rank {core.rank(gmem_tensor)}"
        )

    if not isinstance(gmem_tensor.element_type, NumericMeta):
        raise TypeError(
            "SM120 direct TMA load helper expects a numeric GMEM element type"
        )
    if gmem_tensor.element_type.width < 8:
        raise ValueError(
            "SM120 direct TMA load helper requires element width >= 8 bits"
        )

    stride0 = core.get(gmem_tensor.stride, mode=[0], loc=loc, ip=ip)
    if not core.is_static(stride0) or stride0 != 1:
        raise ValueError(
            "SM120 direct TMA load helper expects GMEM mode 0 to be statically "
            f"contiguous with stride 1, but got stride {stride0}"
        )

    tile_shape = core.shape(cta_tiler, loc=loc, ip=ip)
    if core.rank(tile_shape) != 2:
        raise ValueError(
            f"SM120 direct TMA load helper expects a rank-2 CTA tiler, "
            f"but got rank {core.rank(tile_shape)}"
        )

    tile0 = core.get(tile_shape, mode=[0], loc=loc, ip=ip)
    if not core.is_static(tile0):
        raise ValueError(
            "SM120 direct TMA load helper requires a static mode-0 tile extent"
        )
    if tile0 > 256:
        raise ValueError(
            f"SM120 direct TMA load helper requires tile extent 0 <= 256, "
            f"but got {tile0}"
        )

    element_bytes = gmem_tensor.element_type.width // 8
    if (tile0 * element_bytes) % 16 != 0:
        raise ValueError(
            "SM120 direct TMA load helper requires mode-0 tile bytes to be a "
            f"multiple of 16, but got {tile0 * element_bytes}"
        )

    tma_atom, tma_tensor = make_tiled_tma_atom(
        CopyBulkTensorTileG2SOp(),
        gmem_tensor,
        smem_layout_,
        cta_tiler,
        num_multicast=1,
        internal_type=internal_type,
        loc=loc,
        ip=ip,
    )
    return tma_atom, tma_tensor, get_tma_desc_addr(tma_atom, loc=loc, ip=ip)


@dsl_user_op
def make_tiled_tma_atom(
    op: TMAOp,
    gmem_tensor: Tensor,
    smem_layout_: Union[Layout, ComposedLayout],
    cta_tiler: Tiler,
    num_multicast: int = 1,
    *,
    internal_type: Optional[Type[Numeric]] = None,
    loc=None,
    ip=None,
) -> Tuple[atom.CopyAtom, Tensor]:
    """
    Makes a TMA Copy Atom in the ``.tile`` mode to copy tiles of a GMEM tensor to/from SMEM
    buffer with the given Layout.

    Given

    - a GMEM tensor
    - a SMEM layout
    - a CTA-level Tiler

    this function figures out the bulk tensor asynchronous copy instruction to use with the maximum
    "TMA vector length" to copy tiles of the GMEM tensor to/from an SMEM buffer with the provided
    layout while maintaining consistency with the provided Tiler.

    This function returns two results:

    1. the Copy Atom
    2. a TMA tensor that maps logical coordinates of the GMEM tensor to coordinates consumed by the \
       TMA unit. TMA tensors contain basis stride elements that enable their associated layout to \
       compute coordinates. Like other CuTe tensors, TMA tensors can be partitioned.

    :param op:            The TMA Copy Operation to construct an Atom
    :type op:             TMAOp
    :param gmem_tensor:   The GMEM tensor involved in the Copy
    :type gmem_tensor:    Tensor
    :param smem_layout:   The SMEM layout to construct the Copy Atom, either w/ or w/o the stage mode
    :type smem_layout:    Union[Layout, ComposedLayout]
    :param cta_tiler:     The CTA Tiler to use
    :type cta_tiler:      Tiler
    :param num_multicast: The multicast factor
    :type num_multicast:  int
    :param internal_type: Optional internal data type to use when the tensor data type is not supported by the TMA unit
    :type internal_type:  Type[Numeric]
    :return:              A TMA Copy Atom associated with the TMA tensor
    :rtype:               Tuple[atom.CopyAtom, Tensor]
    """
    smem_rank = core.rank(smem_layout_)
    tiler_rank = core.rank(cta_tiler)
    assert smem_rank == tiler_rank or smem_rank == tiler_rank + 1, (
        f"smem_layout must be non-staged (rank(smem_layout) == rank(cta_tiler)) "
        f"or staged (rank(smem_layout) == rank(cta_tiler) + 1)"
    )

    # Set the smem_layout on the operation for later retrieval
    op.smem_layout = (
        smem_layout_.value
        if isinstance(smem_layout_, core._ComposedLayout)
        else smem_layout_
    )

    # Slice the smem_layout if it is staged
    if smem_rank == tiler_rank + 1:
        smem_layout = core.select(smem_layout_, mode=list(range(tiler_rank)))
    else:
        smem_layout = smem_layout_

    cta_v_map = core.composition(
        core.make_identity_layout(gmem_tensor.shape, loc=loc, ip=ip),
        cta_tiler,
        loc=loc,
        ip=ip,
    )

    if isinstance(smem_layout, core._ComposedLayout):
        smem_layout = smem_layout.value

    tma_format = None
    if internal_type is not None:
        if not isinstance(internal_type, NumericMeta):
            raise TypeError(f"internal_type must be a Numeric, but got {internal_type}")

        use_unpack = (
            internal_type.width == 8
            and isinstance(gmem_tensor.element_type, NumericMeta)
            and gmem_tensor.element_type.width < 8
        )
        internal_mlir_type = (
            gmem_tensor.element_type.mlir_type
            if use_unpack
            else internal_type.mlir_type
        )
        tma_format = _cute_nvgpu_ir.TmaDataFormat(
            _cute_nvgpu_ir.get_default_tma_format(internal_mlir_type, use_unpack)
        )

    if isinstance(op, CopyBulkTensorTileG2SOp):
        if num_multicast != 1:
            raise ValueError(
                f"expects num_multicast to be 1 for non multicast G2S copies, "
                f"but got {num_multicast}"
            )
        res = _cute_nvgpu_ir.atom_make_non_exec_tiled_tma_load(
            gmem_tensor.value,
            smem_layout,
            cta_v_map,
            op._to_ir(),
            num_multicast=num_multicast,
            tma_format=tma_format,
            loc=loc,
            ip=ip,
        )
        return atom.CopyAtom(op, CopyBulkTensorTileG2SNonExecTrait(res[0])), res[1]
    elif isinstance(op, CopyBulkTensorTileG2SMulticastOp):
        if num_multicast < 1:
            raise ValueError(
                f"expects num_multicast to be >= 1 for multicast G2S copies, "
                f"but got {num_multicast}"
            )
        res = _cute_nvgpu_ir.atom_make_non_exec_tiled_tma_load(
            gmem_tensor.value,
            smem_layout,
            cta_v_map,
            op._to_ir(),
            num_multicast=num_multicast,
            tma_format=tma_format,
            loc=loc,
            ip=ip,
        )
        return (
            atom.CopyAtom(op, CopyBulkTensorTileG2SMulticastNonExecTrait(res[0])),
            res[1],
        )
    elif isinstance(op, CopyBulkTensorTileS2GOp):
        res = _cute_nvgpu_ir.atom_make_non_exec_tiled_tma_store(
            gmem_tensor.value,
            smem_layout,
            cta_v_map,
            tma_format=tma_format,
            loc=loc,
            ip=ip,
        )
        return atom.CopyAtom(op, CopyBulkTensorTileS2GNonExecTrait(res[0])), res[1]
    elif isinstance(op, CopyReduceBulkTensorTileS2GOp):
        res = _cute_nvgpu_ir.atom_make_non_exec_tiled_tma_reduce(
            gmem_tensor.value,
            smem_layout,
            cta_v_map,
            op._to_ir(),
            tma_format=tma_format,
            loc=loc,
            ip=ip,
        )
        return (
            atom.CopyAtom(op, CopyReduceBulkTensorTileS2GNonExecTrait(res[0])),
            res[1],
        )
    else:
        raise ValueError(f"expects a bulk tensor (TMA) Copy Op, but got {op}")


@dsl_user_op
def tma_partition(
    atom: atom.CopyAtom,
    cta_coord: Coord,
    cta_layout: Layout,
    smem_tensor: Tensor,
    gmem_tensor: Tensor,
    *,
    loc=None,
    ip=None,
) -> Tuple[Tensor, Tensor]:
    """
    Tiles the GMEM and SMEM tensors for the provided TMA Copy Atom.
    """
    cta_coord_val = core._pack_coord(cta_coord, loc=loc, ip=ip)
    s, d = _cute_nvgpu_ir.atom_tma_partition(
        atom._trait.value,
        cta_coord=cta_coord_val,
        cta_layout=cta_layout,
        smem_tensor=smem_tensor.value,
        gmem_tensor=gmem_tensor.value,
        loc=loc,
        ip=ip,
    )
    return s, d


@dsl_user_op
def create_tma_multicast_mask(
    cta_layout_vmnk: Layout,
    cta_coord_vmnk: Coord,
    mcast_mode: int,
    *,
    loc=None,
    ip=None,
) -> Int16:
    """
    Computes a multicast mask for a TMA load Copy.

    :param cta_layout_vmnk: The VMNK layout of the cluster
    :type cta_layout_vmnk:  Layout
    :param cta_coord_vmnk:  The VMNK coordinate of the current CTA
    :type cta_coord_vmnk:   Coord
    :param mcast_mode:      The tensor mode in which to multicast
    :type mcast_mode:       int
    :return:                The resulting mask
    :rtype:                 Int16
    """
    if core.rank(cta_layout_vmnk) != 4:
        raise ValueError(
            f"cta_layout_vmnk must be rank 4, but got {core.pretty_str(cta_layout_vmnk)}"
        )
    if core.rank(cta_coord_vmnk) != 4:
        raise ValueError(
            f"cta_coord_vmnk must be rank 4, but got {core.pretty_str(cta_coord_vmnk)}"
        )
    return core.make_layout_image_mask(
        cta_layout_vmnk, cta_coord_vmnk, mcast_mode, loc=loc, ip=ip
    )


@dsl_user_op
def prefetch_descriptor(tma_atom: atom.CopyAtom, *, loc=None, ip=None) -> None:
    """
    Prefetches the TMA descriptor associated with the TMA Atom.
    """
    _cute_nvgpu_ir.prefetch_tma_desc(tma_atom._trait.value, loc=loc, ip=ip)


@dsl_user_op
def copy_tensormap(
    tma_atom: atom.CopyAtom, tensormap_ptr: Pointer, *, loc=None, ip=None
) -> None:
    """
    Copies the tensormap held by a TMA Copy Atom to the memory location pointed to by the provided
    pointer.

    :param tma_atom:      The TMA Copy Atom
    :type tma_atom:       CopyAtom
    :param tensormap_ptr: The pointer to the memory location to copy the tensormap to
    :type tensormap_ptr:  Pointer
    """
    _cute_nvgpu_ir.copy_tma_desc(
        tma_atom._trait.value, tensormap_ptr.value, loc=loc, ip=ip
    )


@dsl_user_op
def update_tma_descriptor(
    tma_atom: atom.CopyAtom,
    gmem_tensor: Tensor,
    tma_desc_ptr: Pointer,
    *,
    loc=None,
    ip=None,
) -> None:
    """
    Updates the TMA descriptor in the memory location pointed to by the provided pointer using
    information from a TMA Copy Atom and the provided GMEM tensor.

    Specifically, the following fields of the TMA descriptor will be updated:

    1. the GMEM tensor base address
    2. the GMEM tensor shape
    3. the GMEM tensor stride

    Other fields of the TMA descriptor are left unchanged.

    :param tma_atom:      The TMA Copy Atom
    :type tma_atom:       CopyAtom
    :param gmem_tensor:   The GMEM tensor
    :type gmem_tensor:    Tensor
    :param tensormap_ptr: The pointer to the memory location of the descriptor to udpate
    :type tensormap_ptr:  Pointer
    """
    _cute_nvgpu_ir.update_tma_desc(
        tma_atom._trait.value, gmem_tensor.value, tma_desc_ptr.value, loc=loc, ip=ip
    )


@dsl_user_op
def fence_tma_desc_acquire(
    tma_desc_ptr: Pointer,
    *,
    loc=None,
    ip=None,
) -> None:
    """
    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-membar>`__.
    """
    tma_desc_ptr_i64 = tma_desc_ptr.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    llvm.inline_asm(
        None,
        [tma_desc_ptr_i64],
        "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;",
        "l",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cp_fence_tma_desc_release(
    tma_desc_global_ptr: Pointer,
    tma_desc_shared_ptr: Pointer,
    *,
    loc=None,
    ip=None,
) -> None:
    """
    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-tensormap-cp-fenceproxy>`__.
    """
    tma_desc_global_ptr_i64 = tma_desc_global_ptr.toint(loc=loc, ip=ip).ir_value(
        loc=loc, ip=ip
    )
    tma_desc_shared_ptr_i32 = tma_desc_shared_ptr.toint(loc=loc, ip=ip).ir_value(
        loc=loc, ip=ip
    )
    llvm.inline_asm(
        None,
        [tma_desc_global_ptr_i64, tma_desc_shared_ptr_i32],
        "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;",
        "l,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def fence_tma_desc_release(*, loc=None, ip=None) -> None:
    """
    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-membar>`__.
    """
    llvm.inline_asm(
        None,
        [],
        "fence.proxy.tensormap::generic.release.gpu;",
        "",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )
