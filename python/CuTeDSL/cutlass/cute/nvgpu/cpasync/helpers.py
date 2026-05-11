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

from typing import Any, Iterator, List, Optional, Tuple, Type, Union, cast
from typing_extensions import deprecated

from cutlass.cutlass_dsl import (
    dsl_user_op,
    extract_mlir_attributes,
    extract_mlir_values,
    new_from_mlir_values,
)

import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir import ir
from cutlass._mlir.dialects import llvm

from ...typing import (
    Coord,
    Layout,
    ComposedLayout,
    Tensor,
    Tiler,
    Pointer,
    Int16,
    Numeric,
    NumericMeta,
    IntTuple,
)
from ... import core, atom
from .copy import (
    CopyBulkTensorTileG2SOp,
    CopyBulkTensorIm2ColG2SOp,
    CopyBulkTensorTileG2SMulticastOp,
    CopyBulkTensorIm2ColG2SMulticastOp,
    CopyBulkTensorTileS2GOp,
    CopyBulkTensorIm2ColS2GOp,
    CopyReduceBulkTensorTileS2GOp,
    CopyBulkTensorTileG2SNonExecTrait,
    CopyBulkTensorTileG2SMulticastNonExecTrait,
    CopyBulkTensorTileS2GNonExecTrait,
    CopyReduceBulkTensorTileS2GNonExecTrait,
    CopyBulkTensorIm2ColG2SNonExecTrait,
    CopyBulkTensorIm2ColG2SMulticastNonExecTrait,
    CopyBulkTensorIm2ColS2GNonExecTrait,
)


class TmaInfo:
    """
    Container for TMA Copy Atom and related data.

    This class uses software composition to bundle a CopyAtom with the SMEM
    layout and TMA tensor.

    Supports tuple unpacking for backward compatibility::

        atom, tma_tensor = make_tiled_tma_atom(...)

    Access smem_layout via the container::

        tma_info = make_tiled_tma_atom(...)
        layout = tma_info.smem_layout

    :param atom: The TMA Copy Atom
    :type atom: CopyAtom
    :param tma_tensor: The TMA tensor for coordinate mapping
    :param smem_layout: The SMEM layout used to construct the TMA descriptor
    """

    def __init__(
        self, copy_atom: atom.CopyAtom, tma_tensor: Any, smem_layout: Any = None
    ) -> None:
        self._atom = copy_atom
        self._tma_tensor = tma_tensor
        self._smem_layout = smem_layout

    @property
    def atom(self) -> atom.CopyAtom:
        """The TMA Copy Atom."""
        return self._atom

    @property
    def tma_tensor(self) -> Any:
        """The TMA tensor for coordinate mapping."""
        return self._tma_tensor

    @property
    def smem_layout(self) -> Any:
        """The SMEM layout used to construct the TMA descriptor."""
        return self._smem_layout

    def __iter__(self) -> Iterator[Any]:
        """
        Support tuple unpacking: ``atom, tma_tensor = tma_info``

        This provides backward compatibility with the original return type.
        """
        yield self._atom
        yield self._tma_tensor

    def __getitem__(self, index: int) -> Any:
        """Support indexing for backward compatibility."""
        if index == 0:
            return self._atom
        if index == 1:
            return self._tma_tensor
        raise IndexError(f"TmaInfo index out of range: {index}")

    def __len__(self) -> int:
        """Return 2 for backward compatibility with tuple unpacking."""
        return 2

    def __extract_mlir_values__(self) -> List[Any]:
        vals = extract_mlir_values(self._atom)
        vals += extract_mlir_values(self._tma_tensor)
        if self._smem_layout is not None:
            vals += extract_mlir_values(self._smem_layout)
        return vals

    def __extract_mlir_attributes__(self) -> List[Any]:
        attrs = extract_mlir_attributes(self._atom)
        attrs += extract_mlir_attributes(self._tma_tensor)
        if self._smem_layout is not None:
            attrs += extract_mlir_attributes(self._smem_layout)
        return attrs

    def __new_from_mlir_values__(self, values: List[Any]) -> "TmaInfo":
        atom_len = len(extract_mlir_values(self._atom))
        tensor_len = len(extract_mlir_values(self._tma_tensor))
        smem_len = (
            len(extract_mlir_values(self._smem_layout))
            if self._smem_layout is not None
            else 0
        )

        atom_vals = values[:atom_len]
        tensor_vals = values[atom_len : atom_len + tensor_len]
        smem_vals = values[atom_len + tensor_len : atom_len + tensor_len + smem_len]

        new_atom = new_from_mlir_values(self._atom, atom_vals)
        new_tensor = new_from_mlir_values(self._tma_tensor, tensor_vals)

        new_smem_layout = self._smem_layout
        if smem_len:
            new_smem_layout = new_from_mlir_values(self._smem_layout, smem_vals)

        return TmaInfo(new_atom, new_tensor, new_smem_layout)


TMAOp = Union[
    CopyBulkTensorTileG2SOp,
    CopyBulkTensorTileG2SMulticastOp,
    CopyBulkTensorTileS2GOp,
    CopyBulkTensorIm2ColG2SOp,
    CopyBulkTensorIm2ColS2GOp,
    CopyReduceBulkTensorTileS2GOp,
]


@dsl_user_op
def make_im2col_tma_atom(
    op: TMAOp,
    gmem_tensor: Tensor,
    smem_layout_: Union[Layout, ComposedLayout],
    cta_tiler: Tiler,
    lower_corner_whd: Optional[IntTuple] = None,
    upper_corner_whd: Optional[IntTuple] = None,
    lower_padding_whd: Optional[IntTuple] = None,
    upper_padding_whd: Optional[IntTuple] = None,
    stride_whd: Optional[IntTuple] = None,
    lower_srt: Optional[IntTuple] = None,
    stride_srt: Optional[IntTuple] = None,
    num_multicast: int = 1,
    *,
    internal_type: Optional[Type[Numeric]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> TmaInfo:
    """
    Makes a TMA Copy Atom in the ``.im2col`` mode to copy tiles of a GMEM tensor to/from SMEM
    buffer with the given Layout.  The im2col descriptor parameters:
        - lower_corner_whd
        - upper_corner_whd
        - lower_padding_whd
        - upper_padding_whd
        - stride_whd
        - lower_srt
        - stride_srt 
    are only needed for the load mode (GMEM -> SMEM).

    Given

    - a GMEM tensor
    - a SMEM layout
    - a CTA-level Tiler
    - a lower corner tuple for w,h,d
    - a upper corner tuple for w,h,d
    - a lower padding tuple for w,h,d
    - a upper padding tuple for w,h,d
    - a stride tuple for w,h,d
    - a lower corner tuple for s,r,t
    - a stride tuple for s,r,t

    this function figures out the bulk tensor asynchronous copy instruction to use with the maximum
    "TMA vector length" to copy tiles of the GMEM tensor to/from an SMEM buffer with the provided
    layout while maintaining consistency with the provided Tiler.

    This function returns two results:

    1. the Copy Atom
    2. a TMA tensor that maps logical coordinates of the GMEM tensor to coordinates consumed by the \
       TMA unit. TMA tensors contain basis stride elements that enable their associated layout to \
       compute coordinates. Like other CuTe tensors, TMA tensors can be partitioned.

    :param op:                The TMA Copy Operation to construct an Atom
    :type op:                 TMAOp
    :param gmem_tensor:       The GMEM tensor involved in the Copy
    :type gmem_tensor:        Tensor
    :param smem_layout:       The SMEM layout to construct the Copy Atom, either w/ or w/o the stage mode
    :type smem_layout:        Union[Layout, ComposedLayout]
    :param cta_tiler:         The CTA Tiler to use
    :type cta_tiler:          Tiler
    :param lower_corner_whd:  The lower corner of w,h,d involved in the im2col copy
    :type lower_corner_whd:   IntTuple
    :param upper_corner_whd:  The uppper corner of w,h,d involved in the im2col copy
    :type upper_corner_whd:   IntTuple
    :param lower_padding_whd: The lower padding of w,h,d involved in the im2col copy
    :type lower_padding_whd:  IntTuple
    :param upper_padding_whd: The upper padding of w,h,d involved in the im2col copy
    :type upper_padding_whd:  IntTuple
    :param stride_whd:        The conv stride of w,h,d involved in the im2col copy
    :type stride_whd:         IntTuple
    :param lower_srt:         The lower corner of s,r,t involved in the im2col copy for easily reused in fprop and dgrad
    :type lower_srt:          IntTuple
    :param stride_srt:        The stride of s,r,t involved in the im2col copy as dilation, and for easily reused in fprop and dgrad
    :type stride_srt:         IntTuple
    :param num_multicast:     The multicast factor
    :type num_multicast:      int
    :param internal_type:     Optional internal data type to use when the tensor data type is not supported by the TMA unit
    :type internal_type:      Type[Numeric]
    :return:                  A TmaInfo containing the Copy Atom, TMA tensor, and SMEM layout
    :rtype:                   TmaInfo
    """
    smem_rank = core.rank(smem_layout_)
    tiler_rank = core.rank(cta_tiler)
    assert smem_rank == tiler_rank or smem_rank == tiler_rank + 1, (
        "smem_layout must be non-staged (rank(smem_layout) == rank(cta_tiler)) "
        "or staged (rank(smem_layout) == rank(cta_tiler) + 1)"
    )

    # Keep the original SMEM layout object for later retrieval at Python level.
    stored_smem_layout = smem_layout_

    # Set the smem_layout on the operation for later retrieval
    cast(Any, op).smem_layout = (
        smem_layout_.value
        if isinstance(smem_layout_, core._ComposedLayout)
        else smem_layout_
    )

    # Slice the smem_layout if it is staged
    if smem_rank == tiler_rank + 1:
        smem_layout = core.select(smem_layout_, mode=list(range(tiler_rank)))
    else:
        smem_layout = smem_layout_

    # gmem_tensor is hierarchical form ((w, h, d, n), c) or (k, (c, s, r, t))
    cta_v_map = core.composition(
        core.make_identity_layout(core.product_each(gmem_tensor.shape), loc=loc, ip=ip),
        cta_tiler,
        loc=loc,
        ip=ip,
    )

    if isinstance(smem_layout, core._ComposedLayout):
        smem_layout = smem_layout.value

    tma_format = None
    if internal_type is not None:
        itype: Any = internal_type
        if not isinstance(internal_type, NumericMeta):
            raise TypeError(f"internal_type must be a Numeric, but got {internal_type}")

        use_unpack = (
            itype.width == 8
            and isinstance(gmem_tensor.element_type, NumericMeta)
            and gmem_tensor.element_type.width < 8  # type: ignore[union-attr]
        )
        internal_mlir_type = (
            gmem_tensor.element_type.mlir_type if use_unpack else itype.mlir_type  # type: ignore[union-attr]
        )
        tma_format = _cute_nvgpu_ir.TmaDataFormat(
            _cute_nvgpu_ir.get_default_tma_format(internal_mlir_type, use_unpack)
        )

    if (
        isinstance(op, (CopyBulkTensorIm2ColG2SOp, CopyBulkTensorIm2ColG2SMulticastOp))
    ) and (
        lower_corner_whd is None
        or upper_corner_whd is None
        or lower_padding_whd is None
        or upper_padding_whd is None
        or stride_whd is None
        or lower_srt is None
        or stride_srt is None
    ):
        raise ValueError(
            f"expects lower_corner_whd, upper_corner_whd, lower_padding_whd, upper_padding_whd, stride_whd, lower_srt, stride_srt to be provided for load mode (GMEM -> SMEM), but got {lower_corner_whd}, {upper_corner_whd}, {lower_padding_whd}, {upper_padding_whd}, {stride_whd}, {lower_srt}, {stride_srt}"
        )
    if isinstance(op, CopyBulkTensorIm2ColG2SOp):
        if num_multicast != 1:
            raise ValueError(
                f"expects num_multicast to be 1 for non multicast G2S copies, "
                f"but got {num_multicast}"
            )
        # Get the non-exec im2col tma load atom
        assert lower_corner_whd is not None
        assert upper_corner_whd is not None
        assert lower_padding_whd is not None
        assert upper_padding_whd is not None
        assert stride_whd is not None
        assert lower_srt is not None
        assert stride_srt is not None
        res = _cute_nvgpu_ir.atom_make_non_exec_im2col_tma_load(
            cast(Any, gmem_tensor).value,
            smem_layout,
            cta_v_map,
            op._to_ir(),
            core._pack_int_tuple(lower_corner_whd, loc=loc, ip=ip),
            core._pack_int_tuple(upper_corner_whd, loc=loc, ip=ip),
            core._pack_int_tuple(lower_padding_whd, loc=loc, ip=ip),
            core._pack_int_tuple(upper_padding_whd, loc=loc, ip=ip),
            core._pack_int_tuple(stride_whd, loc=loc, ip=ip),
            core._pack_int_tuple(lower_srt, loc=loc, ip=ip),
            core._pack_int_tuple(stride_srt, loc=loc, ip=ip),
            num_multicast=num_multicast,
            tma_format=tma_format,
            loc=loc,
            ip=ip,
        )
        return TmaInfo(
            atom.CopyAtom(op, CopyBulkTensorIm2ColG2SNonExecTrait(res[0])),
            res[1],
            stored_smem_layout,
        )

    elif isinstance(op, CopyBulkTensorIm2ColG2SMulticastOp):
        if num_multicast < 1:
            raise ValueError(
                f"expects num_multicast to be >= 1 for multicast G2S copies, "
                f"but got {num_multicast}"
            )
        res = _cute_nvgpu_ir.atom_make_non_exec_im2col_tma_load(
            cast(Any, gmem_tensor).value,
            smem_layout,
            cta_v_map,
            op._to_ir(),
            core._pack_int_tuple(lower_corner_whd, loc=loc, ip=ip),
            core._pack_int_tuple(upper_corner_whd, loc=loc, ip=ip),
            core._pack_int_tuple(lower_padding_whd, loc=loc, ip=ip),
            core._pack_int_tuple(upper_padding_whd, loc=loc, ip=ip),
            core._pack_int_tuple(stride_whd, loc=loc, ip=ip),
            core._pack_int_tuple(lower_srt, loc=loc, ip=ip),
            core._pack_int_tuple(stride_srt, loc=loc, ip=ip),
            num_multicast=num_multicast,
            tma_format=tma_format,
            loc=loc,
            ip=ip,
        )
        return TmaInfo(
            atom.CopyAtom(op, CopyBulkTensorIm2ColG2SMulticastNonExecTrait(res[0])),
            res[1],
            stored_smem_layout,
        )
    elif isinstance(op, CopyBulkTensorIm2ColS2GOp):
        res = _cute_nvgpu_ir.atom_make_non_exec_im2col_tma_store(
            cast(Any, gmem_tensor).value,
            smem_layout,
            cta_v_map,
            tma_format=tma_format,
            loc=loc,
            ip=ip,
        )
        return TmaInfo(
            atom.CopyAtom(op, CopyBulkTensorIm2ColS2GNonExecTrait(res[0])),
            res[1],
            stored_smem_layout,
        )
    else:
        raise ValueError(f"expects a bulk tensor (TMA) im2col Copy Op, but got {op}")


@dsl_user_op
def make_tiled_tma_atom(
    op: TMAOp,
    gmem_tensor: Tensor,
    smem_layout_: Union[Layout, ComposedLayout],
    cta_tiler: Tiler,
    num_multicast: int = 1,
    *,
    internal_type: Optional[Type[Numeric]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> TmaInfo:
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
    :return:              A TmaInfo containing the Copy Atom, TMA tensor, and SMEM layout
    :rtype:               TmaInfo
    """
    smem_rank = core.rank(smem_layout_)
    tiler_rank = core.rank(cta_tiler)
    assert smem_rank == tiler_rank or smem_rank == tiler_rank + 1, (
        "smem_layout must be non-staged (rank(smem_layout) == rank(cta_tiler)) "
        "or staged (rank(smem_layout) == rank(cta_tiler) + 1)"
    )

    # Keep the original SMEM layout object for later retrieval at Python level.
    stored_smem_layout = smem_layout_

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
        itype: Any = internal_type
        if not isinstance(internal_type, NumericMeta):
            raise TypeError(f"internal_type must be a Numeric, but got {internal_type}")

        use_unpack = (
            itype.width == 8
            and isinstance(gmem_tensor.element_type, NumericMeta)
            and gmem_tensor.element_type.width < 8  # type: ignore[union-attr]
        )
        internal_mlir_type = (
            gmem_tensor.element_type.mlir_type if use_unpack else itype.mlir_type  # type: ignore[union-attr]
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
            cast(Any, gmem_tensor).value,
            smem_layout,
            cta_v_map,
            op._to_ir(),
            num_multicast=num_multicast,
            tma_format=tma_format,
            loc=loc,
            ip=ip,
        )
        return TmaInfo(
            atom.CopyAtom(op, CopyBulkTensorTileG2SNonExecTrait(res[0])),
            res[1],
            stored_smem_layout,
        )
    elif isinstance(op, CopyBulkTensorTileG2SMulticastOp):
        if num_multicast < 1:
            raise ValueError(
                f"expects num_multicast to be >= 1 for multicast G2S copies, "
                f"but got {num_multicast}"
            )
        res = _cute_nvgpu_ir.atom_make_non_exec_tiled_tma_load(
            cast(Any, gmem_tensor).value,
            smem_layout,
            cta_v_map,
            op._to_ir(),
            num_multicast=num_multicast,
            tma_format=tma_format,
            loc=loc,
            ip=ip,
        )
        return TmaInfo(
            atom.CopyAtom(op, CopyBulkTensorTileG2SMulticastNonExecTrait(res[0])),
            res[1],
            stored_smem_layout,
        )
    elif isinstance(op, CopyBulkTensorTileS2GOp):
        res = _cute_nvgpu_ir.atom_make_non_exec_tiled_tma_store(
            cast(Any, gmem_tensor).value,
            smem_layout,
            cta_v_map,
            tma_format=tma_format,
            loc=loc,
            ip=ip,
        )
        return TmaInfo(
            atom.CopyAtom(op, CopyBulkTensorTileS2GNonExecTrait(res[0])),
            res[1],
            stored_smem_layout,
        )
    elif isinstance(op, CopyReduceBulkTensorTileS2GOp):
        res = _cute_nvgpu_ir.atom_make_non_exec_tiled_tma_reduce(
            cast(Any, gmem_tensor).value,
            smem_layout,
            cta_v_map,
            op._to_ir(),
            tma_format=tma_format,
            loc=loc,
            ip=ip,
        )
        return TmaInfo(
            atom.CopyAtom(op, CopyReduceBulkTensorTileS2GNonExecTrait(res[0])),
            res[1],
            stored_smem_layout,
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
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[Tensor, Tensor]:
    """
    Tiles the GMEM and SMEM tensors for the provided TMA Copy Atom.
    """
    cta_coord_val = core._pack_coord(cta_coord, loc=loc, ip=ip)
    s, d = _cute_nvgpu_ir.atom_tma_partition(
        atom._trait.value,
        cta_coord=cta_coord_val,
        cta_layout=cta_layout,
        smem_tensor=cast(Any, smem_tensor).value,
        target_tensors=[cast(Any, gmem_tensor).value],
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
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
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
def prefetch_descriptor(
    tma_atom: atom.CopyAtom,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Prefetches the TMA descriptor associated with the TMA Atom.
    """
    _cute_nvgpu_ir.prefetch_tma_desc(tma_atom._trait.value, loc=loc, ip=ip)


@dsl_user_op
def copy_tensormap(
    tma_atom: atom.CopyAtom,
    tensormap_ptr: Pointer,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
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
        tma_atom._trait.value, cast(Any, tensormap_ptr).value, loc=loc, ip=ip
    )


@dsl_user_op
def update_tma_descriptor(
    tma_atom: atom.CopyAtom,
    gmem_tensor: Tensor,
    tma_desc_ptr: Pointer,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
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
        tma_atom._trait.value,
        cast(Any, gmem_tensor).value,
        cast(Any, tma_desc_ptr).value,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def fence_tma_desc_acquire(
    tma_desc_ptr: Pointer,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-membar>`__.
    """
    tma_desc_ptr_i64 = (
        cast(Any, tma_desc_ptr).toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    )
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
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-tensormap-cp-fenceproxy>`__.
    """
    tma_desc_global_ptr_i64 = (
        cast(Any, tma_desc_global_ptr).toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    )
    tma_desc_shared_ptr_i32 = (
        cast(Any, tma_desc_shared_ptr).toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
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
def fence_tma_desc_release(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> None:
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


@dsl_user_op
@deprecated("`group_bulk_copy_modes` is deprecated, use `group_modes` instead")
def group_bulk_copy_modes(
    src: Tensor,
    dst: Tensor,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[Tensor, Tensor]:
    """
    Copy async bulk need group mode 0, acquiring whole tensor for bulk copy
    """
    mSrc = core.group_modes(src, 0, core.rank(src), loc=loc, ip=ip)
    mDst = core.group_modes(dst, 0, core.rank(dst), loc=loc, ip=ip)
    return (mSrc, mDst)
