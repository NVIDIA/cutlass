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

import math
from typing import Optional, Dict, Any, List, Tuple, Union

from cutlass._mlir import ir
from cutlass.cutlass_dsl import for_generate, yield_out, if_generate, dsl_user_op
import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir

from .typing import Tensor, Int64, Int16, AddressSpace
from .core import (
    rank,
    is_static,
    size,
    make_layout,
    make_ptr,
    max_common_layout,
    logical_divide,
    append_ones,
    group_modes,
)
from .atom import (
    MmaAtom,
    CopyAtom,
    make_atom,
    _normalize_variadic_tensor_operand,
    copy_atom_call,
)
from .nvgpu.common import CacheEvictionPriority

def _normalize_gemm_operand_list(
    x: Union["Tensor", List["Tensor"], Tuple["Tensor", ...]], name: str
) -> List["Tensor"]:
    if isinstance(x, Tensor):
        return [x]
    if isinstance(x, (list, tuple)):
        if len(x) == 0:
            raise ValueError(f"`{name}` must contain at least one Tensor")
        if not all(isinstance(t, Tensor) for t in x):
            raise TypeError(f"All elements of `{name}` must be Tensor")
        return list(x)  # type: ignore
    raise TypeError(f"`{name}` must be a Tensor or a sequence of Tensors")


@dsl_user_op
def gemm(
    atom: MmaAtom,
    d: Tensor,
    a: Union[Tensor, List[Tensor], Tuple[Tensor, ...]],
    b: Union[Tensor, List[Tensor], Tuple[Tensor, ...]],
    c: Tensor,
    *,
    loc=None,
    ip=None,
    **kwargs,
) -> None:
    """The GEMM algorithm.

    Computes ``D <- A * B + C`` where ``C`` and ``D`` can alias. Note that some MMA Atoms (e.g.
    warpgroup-wide or tcgen05 MMAs) require manually setting an "accumulate" boolean field.

    All tensors must be partitioned according to the provided MMA Atom.

    For MMA Atoms that require single-threaded execution, the gemm op automatically handles thread
    election internally. Manual thread selection is not required in such cases.

    Following dispatch rules are supported:

    - Dispatch [1]: (V) x (V) => (V)          => (V,1,1) x (V,1,1) => (V,1,1)
    - Dispatch [2]: (M) x (N) => (M,N)        => (1,M,1) x (1,N,1) => (1,M,N)
    - Dispatch [3]: (M,K) x (N,K) => (M,N)    => (1,M,K) x (1,N,K) => (1,M,N)
    - Dispatch [4]: (V,M) x (V,N) => (V,M,N)  => (V,M,1) x (V,N,1) => (V,M,N)
    - Dispatch [5]: (V,M,K) x (V,N,K) => (V,M,N)

    Operand flexibility:
    - `a` and `b` can be a single Tensor (regular GEMM) or a sequence `[operand, scale_factor]` for block-scaled GEMM.

    :param atom: MMA atom
    :type atom: MmaAtom
    :param d: Destination tensor
    :type d: Tensor
    :param a: First source tensor or sequence for advanced modes (e.g., `[a, sfa]`)
    :type a: Union[Tensor, List[Tensor], Tuple[Tensor, ...]]
    :param b: Second source tensor or sequence for advanced modes (e.g., `[b, sfb]`)
    :type b: Union[Tensor, List[Tensor], Tuple[Tensor, ...]]
    :param c: Third source tensor
    :type c: Tensor
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point for MLIR, defaults to None
    :type ip: Optional[InsertionPoint], optional
    :param kwargs: Additional keyword arguments
    :type kwargs: dict
    :return: None
    :rtype: None
    """

    # Normalize A/B to lists for variadic IR operands, while keeping old API working.
    a_list = _normalize_gemm_operand_list(a, "a")
    b_list = _normalize_gemm_operand_list(b, "b")

    # Rank validations based on the primary A/B tensors (guaranteed non-empty)
    a_rank = rank(a_list[0].shape)
    b_rank = rank(b_list[0].shape)
    c_rank = rank(c.shape)
    d_rank = rank(d.shape)

    if a_rank != b_rank:
        raise ValueError("`a` and `b` must have the same rank")

    if c_rank != d_rank:
        raise ValueError("`c` and `d` must have the same rank")

    if a_rank == 1:
        if c_rank > 2:
            raise ValueError("`c` must have rank <= 2 when `a` has rank 1")
    elif a_rank == 2:
        if c_rank not in (2, 3):
            raise ValueError("`c` must have rank 2 or 3 when `a` has rank 2")
    elif a_rank == 3:
        if c_rank != 3:
            raise ValueError("`c` must have rank 3 when `a` has rank 3")

    value = atom._unpack(loc=loc, ip=ip, **kwargs)
    a_vals = [t.value for t in a_list]
    b_vals = [t.value for t in b_list]
    return _cute_ir.gemm(value, d.value, a_vals, b_vals, c.value, loc=loc, ip=ip)


@dsl_user_op
def basic_copy(src: Tensor, dst: Tensor, *, loc=None, ip=None) -> None:
    """Performs a basic element-wise copy.

    This functions **assumes** the following pre-conditions:
    1. `size(src) == size(dst)`

    When the `src` and `dst` shapes are static, the pre-conditions are actually verified and the
    element-wise loop is fully unrolled.

    :param src: Source tensor
    :type src: Tensor
    :param dst: Destination tensor
    :type dst: Tensor
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point, defaults to None
    :type ip: Optional[InsertionPoint], optional
    """

    if is_static(src.shape) and is_static(dst.shape):
        simt_copy_ty = _cute_nvgpu_ir.CopyAtomSIMTSyncCopyType.get(
            src.element_type.mlir_type, src.element_type.width
        )
        simt_copy = make_atom(simt_copy_ty, loc=loc, ip=ip)
        return _cute_ir.copy(simt_copy, [src.value], [dst.value], loc=loc, ip=ip)

    s = size(dst, loc=loc, ip=ip)
    # Always generate an scf.for Op when one of the tensors is dynamic
    for i in for_generate(0, s, loc=loc, ip=ip):
        dst[i] = src[i]
        yield_out()


@dsl_user_op
def basic_copy_if(pred: Tensor, src: Tensor, dst: Tensor, *, loc=None, ip=None) -> None:
    """Performs a basic predicated element-wise copy.

    This functions **assumes** the following pre-conditions:
    1. `size(src) == size(dst)`
    2. `size(src) == size(pred)`

    When all shapes are static, the pre-conditions are actually verified and the element-wise loop
    is fully unrolled.

    """
    if src.element_type.width != dst.element_type.width:
        raise NotImplementedError(
            "basic_copy_if currently only supports equal source and destination "
            "element type bit width"
        )

    if is_static(src.shape) and is_static(dst.shape) and is_static(pred.shape):
        return _basic_copy_if_static(pred, src, dst, loc=loc, ip=ip)

    s = size(dst, loc=loc, ip=ip)
    # Always generate an scf.for Op when one of the tensors is dynamic
    for i in for_generate(0, s, loc=loc, ip=ip):
        if_generate(pred[i], lambda: dst.__setitem__(i, src[i]), loc=loc, ip=ip)  # type: ignore
        yield_out()


# Version of basic_copy_if when src and dst have static shapes
# - verify size(src) == size(dst) == size(prd)
# - fully unroll the loop for now
def _basic_copy_if_static(
    pred: Tensor, src: Tensor, dst: Tensor, *, loc=None, ip=None
) -> None:
    assert is_static(src.shape) and is_static(dst.shape) and is_static(pred.shape)
    if size(src, loc=loc, ip=ip) != size(dst, loc=loc, ip=ip):
        raise ValueError(
            "basic_copy expects the size of source, destination, and predicate tensors to match"
        )
    # Fully unrolled loop in the static case for now
    for i in range(size(dst, loc=loc, ip=ip)):
        if_generate(pred[i], lambda: dst.__setitem__(i, src[i]), loc=loc, ip=ip)  # type: ignore


@dsl_user_op
def autovec_copy(
    src: Tensor,
    dst: Tensor,
    *,
    l1c_evict_priority: CacheEvictionPriority = CacheEvictionPriority.EVICT_NORMAL,
    loc=None,
    ip=None,
) -> None:
    """
    Auto-vectorization SIMT copy policy.

    Given a source and destination tensors that are statically shaped, this policy figures out the
    largest safe vector width that the copy instruction can take and performs the copy.
    """
    if src.element_type.width != dst.element_type.width:
        raise NotImplementedError(
            "autovec_copy currently only supports equal source and destination "
            "element type bit width"
        )

    # We are going to dispatch to copy-with-atom which requires shapes to be static
    if not is_static(src.shape) or not is_static(dst.shape):
        raise ValueError(
            "autovec_copy expects source and destination tensors to be statically shaped"
        )

    vec_layout = max_common_layout(src, dst, loc=loc, ip=ip)
    num_common_elements = size(vec_layout, loc=loc, ip=ip)

    # Next we construct an upper-bound on the number bits that can be vectorized by considering
    # - the maximum alignment of the layouts
    # - the maximum alignment of the pointers

    upper_bound = math.gcd(src.layout.max_alignment, dst.layout.max_alignment)
    upper_bound = math.gcd(upper_bound, num_common_elements)
    upper_bound *= src.element_type.width

    # For our instructions, the alignment of the pointer is an upper bound to the vector width
    # max_alignment, as opposed to alignment, takes into account possible address swizzling
    upper_bound = math.gcd(upper_bound, src.iterator.max_alignment * 8)
    upper_bound = math.gcd(upper_bound, dst.iterator.max_alignment * 8)

    # Finally, we put a cap at 256b
    num_bits_per_copy = math.gcd(upper_bound, 256)

    if (num_common_elements > 1) and (num_bits_per_copy % 8 == 0):
        num_common_elements = num_bits_per_copy // src.element_type.width

        # 2 step logical divides ensuring that the divides are valid at every step
        vec_src = logical_divide(src, vec_layout, loc=loc, ip=ip)
        vec_dst = logical_divide(dst, vec_layout, loc=loc, ip=ip)
        tiled_src = logical_divide(
            vec_src, make_layout(num_common_elements, loc=loc, ip=ip), loc=loc, ip=ip
        )
        tiled_dst = logical_divide(
            vec_dst, make_layout(num_common_elements, loc=loc, ip=ip), loc=loc, ip=ip
        )

        # Dispatch to copy with atom
        simt_type = _cute_nvgpu_ir.CopyAtomSIMTSyncCopyType.get(
            src.element_type.mlir_type,
            num_bits_per_copy,
            0,
            0,
            l1c_evict_priority._to_ir(),
        )
        simt_copy = make_atom(simt_type, loc=loc, ip=ip)
        return _cute_ir.copy(
            simt_copy, [tiled_src.value], [tiled_dst.value], loc=loc, ip=ip
        )

    # Failed to vectorize, use a basic copy
    basic_copy(src, dst, loc=loc, ip=ip)


def _parse_auto_multicast_args(
    kwargs: Dict[str, Any],
) -> List[Tuple[str, ir.Attribute]]:
    """
    Parse multicast-related kwargs and return a list of (attr_name, attr) pairs.

    This function consumes the following key from kwargs if present:
      - 'auto_multicast': dict
          dict: { 'multicast_layout': str, 'use_2cta': bool, 'from_block_api': bool }

    Returns:
      List of (attr_name, ir.Attribute) pairs to be attached to the op.
      Recognized attributes:
        - ('multicast_layout', #cute.layout<...>) when a layout string is provided
        - ('use_2cta', unit) when use_2cta is True
        - ('from_block_api', unit) when from_block_api is True
    """
    attr_pairs: List[Tuple[str, ir.Attribute]] = []

    # Pop known keys to avoid leaking to trait unpack
    auto_multicast = kwargs.pop("auto_multicast", None)

    from_block_api: bool = False
    use_2cta: bool = False
    layout_str: Optional[str] = None

    if auto_multicast is not None:
        if not isinstance(auto_multicast, dict):
            raise TypeError(
                "auto_multicast must be a dict with keys 'multicast_layout' and optional 'use_2cta'"
            )
        layout_str = auto_multicast.get("multicast_layout", None)
        use_2cta = bool(auto_multicast.get("use_2cta", False))
        from_block_api = bool(auto_multicast.get("from_block_api", False))

    if layout_str is not None:
        if not isinstance(layout_str, str):
            raise TypeError(
                "multicast_layout must be a string representing a CuTe layout, e.g. '(4,2):(1,0)'"
            )
        attr_pairs.append(
            (
                "multicast_layout",
                ir.Attribute.parse(f'#cute.layout<"{layout_str}">'),
            )
        )
    if from_block_api:
        attr_pairs.append(("from_block_api", ir.UnitAttr.get()))
    if use_2cta:
        attr_pairs.append(("use_2cta", ir.UnitAttr.get()))

    return attr_pairs


@dsl_user_op
def copy(
    atom: CopyAtom,
    src: Union[Tensor, List[Tensor], Tuple[Tensor, ...]],
    dst: Union[Tensor, List[Tensor], Tuple[Tensor, ...]],
    *,
    pred: Optional[Tensor] = None,
    loc=None,
    ip=None,
    **kwargs,
) -> None:
    """Facilitates data transfer between two tensors conforming to layout profile ``(V, Rest...)``.

    :param atom: Copy atom specifying the transfer operation
    :type atom: CopyAtom
    :param src: Source tensor or list of tensors with layout profile ``(V, Rest...)``
    :type src: Union[Tensor, List[Tensor], Tuple[Tensor, ...]]
    :param dst: Destination tensor or list of tensors with layout profile ``(V, Rest...)``
    :type dst: Union[Tensor, List[Tensor], Tuple[Tensor, ...]]
    :param pred: Optional predication tensor for conditional transfers, defaults to None
    :type pred: Optional[Tensor], optional
    :param loc: Source location information, defaults to None
    :type loc: Any, optional
    :param ip: Insertion point, defaults to None
    :type ip: Any, optional
    :param kwargs: Additional copy atom specific arguments
    :type kwargs: Dict[str, Any]
    :raises TypeError: If source and destination element type bit widths differ
    :raises ValueError: If source and destination ranks differ
    :raises ValueError: If source and destination mode-1 sizes differ
    :raises NotImplementedError: If ``V-mode`` rank exceeds 2
    :return: None
    :rtype: None

    The ``V-mode`` represents either:

    - A singular mode directly consumable by the provided Copy Atom
    - A composite mode requiring recursive decomposition, structured as ``(V, Rest...)``,
      and src/dst layout like ``((V, Rest...), Rest...)``

    The algorithm recursively processes the ``V-mode``, decomposing it until reaching the minimum granularity
    compatible with the provided Copy Atom's requirements.

    Source and destination tensors must be partitioned in accordance with the Copy Atom specifications.
    Post-partitioning, both tensors will exhibit a ``(V, Rest...)`` layout profile.

    The operands `src` and `dst` are variadic, each containing a variable number of tensors:

    - For regular copy, `src` and `dst` contain single source and destination tensors respectively.
    - For copy with auxiliary operands, `src` and `dst` contain the primary tensors followed by
      their respective auxiliary tensors.

    **Precondition:** The size of mode 1 must be equal for both source and destination tensors:
    ``size(src, mode=[1]) == size(dst, mode=[1])``

    **Examples**:

    TMA copy operation with multicast functionality:

    .. code-block:: python

        cute.copy(tma_atom, src, dst, tma_bar_ptr=mbar_ptr, mcast_mask=mask, cache_policy=policy)

    Optional predication is supported through an additional tensor parameter. For partitioned tensors with
    logical profile ``((ATOM_V,ATOM_REST),REST,...)``, the predication tensor must maintain profile
    compatibility with ``(ATOM_REST,REST,...)``.

    For Copy Atoms requiring single-threaded execution, thread election is managed automatically by the
    copy operation. External thread selection mechanisms are not necessary.

    .. note::

        - Certain Atoms may require additional operation-specific keyword arguments.
        - Current implementation limits ``V-mode`` rank to 2 or less. Support for higher ranks is planned
          for future releases.

    """
    # Normalize src/dst to lists for variadic IR operands
    src_list = _normalize_variadic_tensor_operand(src, "src")
    dst_list = _normalize_variadic_tensor_operand(dst, "dst")

    # Validate primary tensors (first element)
    src_primary = src_list[0]
    dst_primary = dst_list[0]

    if isinstance(src_primary.type, _cute_ir.MemRefType) and isinstance(
        dst_primary.type, _cute_ir.MemRefType
    ):
        if src_primary.element_type.width != dst_primary.element_type.width:
            raise TypeError(
                "`copy` currently only supports equal source and destination "
                "element type bit width"
            )

    if rank(src_primary) != rank(dst_primary):
        raise ValueError(
            "Expected source and destination tensors to have the same rank, "
            f"but got {rank(src_primary)} and {rank(dst_primary)}"
        )

    # Canonicalize all tensors to at least rank-2
    src_list = [group_modes(append_ones(t, up_to_rank=2), 1) for t in src_list]
    dst_list = [group_modes(append_ones(t, up_to_rank=2), 1) for t in dst_list]
    if pred is not None:
        pred = group_modes(append_ones(pred, up_to_rank=2), 1)

    # Recompute primary references after canonicalization
    src_primary = src_list[0]
    dst_primary = dst_list[0]

    if is_static(src_primary.shape[1]) and is_static(dst_primary.shape[1]):
        if size(src_primary, mode=[1]) != size(dst_primary, mode=[1]):
            raise ValueError(
                "Expected source and destination tensors to have the same size in mode-1, "
                f"but got {size(src_primary, mode=[1])} and {size(dst_primary, mode=[1])}"
            )

    multicast_attr_pairs = _parse_auto_multicast_args(kwargs)

    value = atom._unpack(loc=loc, ip=ip, **kwargs)
    pred_value = pred.value if isinstance(pred, Tensor) else pred

    src_vals = [t.value for t in src_list]
    dst_vals = [t.value for t in dst_list]
    op = _cute_ir.copy(value, src_vals, dst_vals, pred=pred_value, loc=loc, ip=ip)

    for name, attr in multicast_attr_pairs:
        op.attributes[name] = attr

    return op


@dsl_user_op
def prefetch(atom: CopyAtom, src: Tensor, *, loc=None, ip=None) -> None:
    """
    The Prefetch algorithm.

    The "prefetch" expects source tensors to be partitioned according to the provided Copy Atom.
    Prefetch is used for loading tensors from global memory to L2.

    Prefetch accepts Copy Atom but not all are allowed. Currently, only supports TMA prefetch.

    .. code-block:: python

        cute.prefetch(tma_prefetch, src)

    For Copy Atoms that require single-threaded execution, the copy op automatically handles thread
    election internally. Manual thread selection is not required in such cases.
    """
    dummy_tma_bar_ptr = make_ptr(Int64, 0, AddressSpace.smem, loc=loc, ip=ip)
    dummy_mcast_mask = Int16(0)
    value = atom._unpack(
        loc=loc, ip=ip, tma_bar_ptr=dummy_tma_bar_ptr, mcast_mask=dummy_mcast_mask
    )
    return _cute_ir.prefetch(value, src.value, loc=loc, ip=ip)
