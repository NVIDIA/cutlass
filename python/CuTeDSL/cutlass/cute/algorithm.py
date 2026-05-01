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


import math
from typing import Optional, Dict, Any, List, Tuple, Type, Union

from cutlass._mlir import ir
from cutlass.cutlass_dsl import (
    for_generate,
    yield_out,
    if_generate,
    dsl_user_op,
    LoopUnroll,
)
import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir

from .typing import Numeric, Tensor, Int64, Int16, AddressSpace
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
    slice_,
)
from .atom import (
    MmaAtom,
    CopyAtom,
    make_atom,
    _normalize_variadic_tensor_operand,
    copy_atom_call,
)
from .nvgpu.common import (
    CacheEvictionPriority,
    CopyG2ROp,
    CopyR2GOp,
    CopyS2ROp,
    CopyR2SOp,
)


@dsl_user_op
def gemm(
    atom: MmaAtom,
    d: Tensor,
    a: Union[Tensor, List[Tensor], Tuple[Tensor, ...]],
    b: Union[Tensor, List[Tensor], Tuple[Tensor, ...]],
    c: Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
    **kwargs: Any,
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

    The operands `a` and `b` are variadic, each containing a variable number of tensors:

    - For regular GEMM, `a` and `b` contain the GEMM A and B tensors respectively.
    - For GEMM with auxiliary operands, `a` and `b` contain the GEMM A and B tensors followed by
      their respective auxiliary tensors. For example:

      - For BlockScaledGemm, `a` = [A, SFA] and `b` = [B, SFB].

    :param atom: MMA atom
    :type atom: MmaAtom
    :param d: Destination tensor (output accumulator)
    :type d: Tensor
    :param a: A tensor or list of tensors containing the GEMM A tensor and optional auxiliary tensors
    :type a: Union[Tensor, List[Tensor], Tuple[Tensor, ...]]
    :param b: B tensor or list of tensors containing the GEMM B tensor and optional auxiliary tensors
    :type b: Union[Tensor, List[Tensor], Tuple[Tensor, ...]]
    :param c: Input accumulator tensor
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
    a_list = _normalize_variadic_tensor_operand(a, "a")
    b_list = _normalize_variadic_tensor_operand(b, "b")

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


def _make_copy_atom(
    copy_internal_type: Type[Numeric],
    num_bits_per_copy: int,
    src_memspace: AddressSpace,
    dst_memspace: AddressSpace,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
    **mem_attrs: Any,
) -> ir.Value:
    """Create a copy atom, using the universal copy by default.

    When no ``mem_attrs`` are provided, the universal copy atom is used.
    Otherwise, the function dispatches to a specialized copy op based on the
    source/destination memory spaces and forwards the memory attributes:
      - gmem -> rmem: ``CopyG2ROp``
      - rmem -> gmem: ``CopyR2GOp``
      - smem -> rmem: ``CopyS2ROp``
      - rmem -> smem: ``CopyR2SOp``

    A ``ValueError`` is raised if no specialized op matches the memory-space pair.
    """

    if not mem_attrs:
        atom_type = _cute_nvgpu_ir.CopyAtomSIMTSyncCopyType.get(
            copy_internal_type.mlir_type,
            num_bits_per_copy,
        )
        return make_atom(atom_type, loc=loc, ip=ip)

    # Specialized path: dispatch based on memory spaces.
    op: Union[
        CopyG2ROp,
        CopyR2GOp,
        CopyS2ROp,
        CopyR2SOp,
    ]
    if src_memspace == AddressSpace.gmem and dst_memspace == AddressSpace.rmem:
        op = CopyG2ROp()
    elif src_memspace == AddressSpace.rmem and dst_memspace == AddressSpace.gmem:
        op = CopyR2GOp()
    elif src_memspace == AddressSpace.smem and dst_memspace == AddressSpace.rmem:
        op = CopyS2ROp()
    elif src_memspace == AddressSpace.rmem and dst_memspace == AddressSpace.smem:
        op = CopyR2SOp()
    else:
        raise ValueError(
            f"Memory attributes {set(mem_attrs)} are not supported for "
            f"{src_memspace} -> {dst_memspace} copies (no specialized op available)."
        )
    trait = op._make_trait(
        copy_internal_type,
        num_bits_per_copy=num_bits_per_copy,
        loc=loc,
        ip=ip,
        **mem_attrs,
    )
    return trait.value


@dsl_user_op
def basic_copy(
    src: Tensor,
    dst: Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
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
            src.element_type.mlir_type,  # type: ignore[union-attr]
            src.element_type.width,  # type: ignore[union-attr]
        )
        simt_copy = make_atom(simt_copy_ty, loc=loc, ip=ip)
        return _cute_ir.copy(simt_copy, [src.value], [dst.value], loc=loc, ip=ip)

    s = size(dst, loc=loc, ip=ip)
    # Always generate an scf.for Op when one of the tensors is dynamic
    for i in for_generate(0, s, loc=loc, ip=ip):
        dst[i] = src[i]
        yield_out()


@dsl_user_op
def basic_copy_if(
    pred: Tensor,
    src: Tensor,
    dst: Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Performs a basic predicated element-wise copy.

    This functions **assumes** the following pre-conditions:
    1. `size(src) == size(dst)`
    2. `size(src) == size(pred)`

    When all shapes are static, the pre-conditions are actually verified and the element-wise loop
    is fully unrolled.

    """
    if src.element_type.width != dst.element_type.width:  # type: ignore[union-attr]
        raise NotImplementedError(
            "basic_copy_if currently only supports equal source and destination "
            "element type bit width"
        )

    if is_static(src.shape) and is_static(dst.shape) and is_static(pred.shape):
        return _basic_copy_if_static(pred, src, dst, loc=loc, ip=ip)

    s = size(dst, loc=loc, ip=ip)
    # Always generate an scf.for Op when one of the tensors is dynamic
    for i in for_generate(0, s, loc=loc, ip=ip):
        if_generate(pred[i], lambda: dst.__setitem__(i, src[i]), loc=loc, ip=ip)
        yield_out()


# Version of basic_copy_if when src and dst have static shapes
# - verify size(src) == size(dst) == size(prd)
# - fully unroll the loop for now
def _basic_copy_if_static(
    pred: Tensor,
    src: Tensor,
    dst: Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    assert is_static(src.shape) and is_static(dst.shape) and is_static(pred.shape)
    if size(src, loc=loc, ip=ip) != size(dst, loc=loc, ip=ip):
        raise ValueError(
            "basic_copy expects the size of source, destination, and predicate tensors to match"
        )
    # Fully unrolled loop in the static case for now
    for i in range(size(dst, loc=loc, ip=ip)):
        if_generate(pred[i], lambda: dst.__setitem__(i, src[i]), loc=loc, ip=ip)


@dsl_user_op
def autovec_copy(
    src: Tensor,
    dst: Tensor,
    *,
    l1c_evict_priority: CacheEvictionPriority = CacheEvictionPriority.EVICT_NORMAL,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Auto-vectorization SIMT copy policy.

    Given a source and destination tensors that are statically shaped, this policy
    figures out the largest safe vector width that the copy instruction can take
    and performs the copy. Any extra memory attributes are forwarded to the specialized
    copy op.

    """
    if src.element_type.width != dst.element_type.width:  # type: ignore[union-attr]
        raise NotImplementedError(
            "autovec_copy only supports equal source and destination "
            f"element type bit widths, got {src.element_type} and {dst.element_type}"
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

    upper_bound = math.gcd(src.layout.max_alignment, dst.layout.max_alignment)  # type: ignore[union-attr]
    upper_bound = math.gcd(upper_bound, num_common_elements)
    upper_bound *= src.element_type.width  # type: ignore[union-attr]

    # For our instructions, the alignment of the pointer is an upper bound to the vector width
    # max_alignment, as opposed to alignment, takes into account possible address swizzling
    upper_bound = math.gcd(upper_bound, src.iterator.max_alignment * 8)  # type: ignore[union-attr]
    upper_bound = math.gcd(upper_bound, dst.iterator.max_alignment * 8)  # type: ignore[union-attr]

    # Finally, we put a cap at 256b
    num_bits_per_copy = math.gcd(upper_bound, 256)

    if (num_common_elements > 1) and (num_bits_per_copy % 8 == 0):
        num_common_elements = num_bits_per_copy // src.element_type.width  # type: ignore[union-attr]

        # 2 step logical divides ensuring that the divides are valid at every step
        vec_src = logical_divide(src, vec_layout, loc=loc, ip=ip)
        vec_dst = logical_divide(dst, vec_layout, loc=loc, ip=ip)
        tiled_src = logical_divide(
            vec_src, make_layout(num_common_elements, loc=loc, ip=ip), loc=loc, ip=ip
        )
        tiled_dst = logical_divide(
            vec_dst, make_layout(num_common_elements, loc=loc, ip=ip), loc=loc, ip=ip
        )

        # Forward memory attributes that differ from their defaults so _make_copy_atom
        # falls back to the universal copy when no specialisation is needed.
        mem_attrs = {}
        if l1c_evict_priority != CacheEvictionPriority.EVICT_NORMAL:
            mem_attrs["l1c_evict_priority"] = l1c_evict_priority

        simt_copy_atom = _make_copy_atom(
            src.element_type,  # type: ignore[arg-type]
            num_bits_per_copy,
            src.iterator.memspace,  # type: ignore[union-attr]
            dst.iterator.memspace,  # type: ignore[union-attr]
            loc=loc,
            ip=ip,
            **mem_attrs,
        )
        return _cute_ir.copy(
            simt_copy_atom,
            [tiled_src.value],
            [tiled_dst.value],
            loc=loc,
            ip=ip,
        )

    # Failed to vectorize, use a basic copy
    basic_copy(src, dst, loc=loc, ip=ip)


def _parse_tma_multicast_args(
    kwargs: Dict[str, Any],
) -> List[Tuple[str, ir.Attribute]]:
    """
    Parse multicast-related kwargs and return a list of (attr_name, attr) pairs.

    This function consumes the following key from kwargs if present:
      - 'tma_multicast': dict with keys:
          { 'cluster_shape': (m, n), 'multicast_dim': 'M' or 'N',
            'use_2cta_mma_inst': bool, 'from_block_api': bool }

    Returns:
      List of (attr_name, ir.Attribute) pairs to be attached to the op.
      Recognized attributes:
        - ('multicast_layout', #cute.layout<...>)
        - ('use_2cta', unit) when use_2cta_mma_inst is True
        - ('from_block_api', unit) when from_block_api is True
    """
    attr_pairs: List[Tuple[str, ir.Attribute]] = []

    # Pop known keys to avoid leaking to trait unpack
    tma_multicast = kwargs.pop("tma_multicast", None)

    if tma_multicast is None:
        return attr_pairs

    if not isinstance(tma_multicast, dict):
        raise TypeError("tma_multicast must be a dict")

    # Validate required keys
    required_keys = ["cluster_shape", "multicast_dim"]
    for key in required_keys:
        if key not in tma_multicast:
            raise KeyError(
                f"tma_multicast is missing required key '{key}'. "
                f"Expected keys: {required_keys}"
            )

    multicast_dim = tma_multicast["multicast_dim"]
    if multicast_dim not in ("M", "N"):
        raise ValueError(f"multicast_dim must be 'M' or 'N', got '{multicast_dim}'")

    cluster_m, cluster_n = tma_multicast["cluster_shape"]
    direction = "(1,0)" if multicast_dim == "M" else "(0,1)"
    layout_str = f"({cluster_m},{cluster_n}):{direction}"

    attr_pairs.append(
        (
            "multicast_layout",
            ir.Attribute.parse(f'#cute.layout<"{layout_str}">'),
        )
    )
    if tma_multicast.get("from_block_api", False):
        attr_pairs.append(("from_block_api", ir.UnitAttr.get()))
    if tma_multicast.get("use_2cta_mma_inst", False):
        attr_pairs.append(("use_2cta", ir.UnitAttr.get()))

    return attr_pairs


@dsl_user_op
def copy(
    atom: CopyAtom,
    src: Union[Tensor, List[Tensor], Tuple[Tensor, ...]],
    dst: Union[Tensor, List[Tensor], Tuple[Tensor, ...]],
    *,
    pred: Optional[Tensor] = None,
    unroll_factor: Optional[int] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
    **kwargs: Any,
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
    :param unroll_factor: Optional unroll count for loop over Rest... modes, defaults to None for fully unroll when Rest... modes are static
    :type unroll_factor: Optional[int], optional
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

    if isinstance(
        src_primary.type,  # type: ignore[attr-defined]
        _cute_ir.MemRefType,
    ) and isinstance(
        dst_primary.type,  # type: ignore[attr-defined]
        _cute_ir.MemRefType,
    ):
        if (
            len(dst_list) == 1
            and src_primary.element_type.width != dst_primary.element_type.width  # type: ignore[union-attr]
        ):
            raise TypeError(
                "`copy` currently only supports equal source and destination "
                "element type bit width"
            )

    if unroll_factor is not None:
        if not isinstance(unroll_factor, int) or unroll_factor < 1:
            raise ValueError(
                f"unroll_factor must be a positive integer, but got {unroll_factor}"
            )

    if rank(src_primary) != rank(dst_primary):
        raise ValueError(
            "Expected source and destination tensors to have the same rank, "
            f"but got {rank(src_primary)} and {rank(dst_primary)}"
        )

    # Canonicalize all tensors to at least rank-2
    src_list = [group_modes(append_ones(t, up_to_rank=2), 1) for t in src_list]  # type: ignore[call-overload]
    dst_list = [group_modes(append_ones(t, up_to_rank=2), 1) for t in dst_list]  # type: ignore[call-overload]
    if pred is not None:
        pred = group_modes(append_ones(pred, up_to_rank=2), 1)  # type: ignore[call-overload]

    # Recompute primary references after canonicalization
    src_primary = src_list[0]
    dst_primary = dst_list[0]

    if is_static(src_primary.shape[1]) and is_static(dst_primary.shape[1]):  # type: ignore[index]
        if size(src_primary, mode=[1]) != size(dst_primary, mode=[1]):
            raise ValueError(
                "Expected source and destination tensors to have the same size in mode-1, "
                f"but got {size(src_primary, mode=[1])} and {size(dst_primary, mode=[1])}"
            )

    multicast_attr_pairs = _parse_tma_multicast_args(kwargs)

    # Unroll the loop per specified unroll_factor for static RestM case
    if is_static(src_primary.shape[1]) and unroll_factor is not None:  # type: ignore[index]
        unroll_factor = LoopUnroll(count=unroll_factor)
        for i in for_generate(
            0,
            stop=size(src_primary, mode=[1], loc=loc, ip=ip),
            unroll=unroll_factor,
            loc=loc,
            ip=ip,
        ):
            src_atom = [slice_(src, (None, i), loc=loc, ip=ip) for src in src_list]
            dst_atom = [slice_(dst, (None, i), loc=loc, ip=ip) for dst in dst_list]
            pred_atom = (
                slice_(pred, (None, i), loc=loc, ip=ip) if pred is not None else None
            )
            copy_atom_call(
                atom, src_atom, dst_atom, pred=pred_atom, loc=loc, ip=ip, **kwargs
            )
            yield_out()
    else:
        value = atom._unpack(loc=loc, ip=ip, **kwargs)
        pred_value = pred.value if isinstance(pred, Tensor) else pred

        src_vals = [t.value for t in src_list]
        dst_vals = [t.value for t in dst_list]
        op = _cute_ir.copy(value, src_vals, dst_vals, pred=pred_value, loc=loc, ip=ip)

        for name, attr in multicast_attr_pairs:
            op.attributes[name] = attr


@dsl_user_op
def prefetch(
    atom: CopyAtom,
    src: Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
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
