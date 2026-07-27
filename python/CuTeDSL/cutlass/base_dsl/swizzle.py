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

"""
``cutlass.base_dsl.swizzle`` — SMEM XOR swizzle library.

**Recommended usage** — import ``cutlass`` and use the ``cutlass.`` namespace::

    import cutlass
    sw = cutlass.Swizzle(3, 4, 3)
    sw = cutlass.Swizzle.from_name("s128b")
    vec = (smem_ptr + offset).load_swizzled(sw, count=64)

This file is the base-DSL implementation home.

See ``write-dsl-kernel/swizzle.md`` for full documentation and worked examples.
"""

from dataclasses import dataclass
from typing import cast

from . import dsl_user_op
from .._mlir import ir as _ir


# =============================================================================
# Swizzle descriptor (pure Python — no MLIR dependencies)
# =============================================================================


@dataclass(frozen=True)
class Swizzle:
    """CuTe-style XOR swizzle descriptor for SMEM address permutation.

    Encodes a 3-parameter XOR swizzle applied to SMEM byte addresses::

        mask          = (1 << bbits) - 1
        yyy           = (addr >> (mbase + sshift)) & mask   # upper bitfield
        swizzled_addr = addr ^ (yyy << mbase)               # XOR lower with upper

    Common presets (for use with ``tcgen05.mma kind::f16``)::

        s128b = Swizzle(3, 4, 3)   # 128B XOR — required for SM100 tcgen05.mma
        s64b  = Swizzle(2, 4, 3)
        s32b  = Swizzle(1, 4, 3)
        none  = Swizzle(0, 0, 0)   # identity — no-op

    :param bbits: Number of bits in the XOR mask (width of swizzle
        region).  ``3`` → 8-element swizzle period.
    :param mbase: Least-significant bits kept constant (not affected by
        XOR).  ``4`` → bottom 16B granule is unchanged.
    :param sshift: Shift of the upper mask from ``mbase`` (positive =
        shift right).  ``3`` → upper bits start at
        ``mbase + sshift = 7``.
    """

    bbits: int
    mbase: int
    sshift: int

    @classmethod
    def from_name(cls, name: str) -> "Swizzle":
        """Construct a ``Swizzle`` from its canonical name string.

        Name → Swizzle(bbits, mbase, sshift):

        ========= =======================
        Name      Swizzle
        ========= =======================
        ``none``  ``Swizzle(0, 0, 0)``
        ``s32b``  ``Swizzle(1, 4, 3)``
        ``s64b``  ``Swizzle(2, 4, 3)``
        ``s128b`` ``Swizzle(3, 4, 3)``
        ========= =======================

        :param name: Swizzle name string — one of ``"none"``,
            ``"s32b"``, ``"s64b"``, ``"s128b"``.
        :return: Corresponding ``Swizzle`` instance.
        :raises ValueError: if ``name`` is not one of the supported
            preset names.

        .. code-block:: python

            sw = Swizzle.from_name("s128b")
            # sw == Swizzle(3, 4, 3)
        """
        mapping = {
            "none": cls(0, 0, 0),
            "s32b": cls(1, 4, 3),
            "s64b": cls(2, 4, 3),
            "s128b": cls(3, 4, 3),
        }
        try:
            return mapping[name]
        except KeyError as exc:
            choices = list(mapping)
            raise ValueError(
                f"Unsupported swizzle name {name!r}. Supported: {choices}."
            ) from exc

    def to(self, target_type: type[object]) -> object:
        """Convert this swizzle descriptor to another swizzle representation.

        ``cutlass.Swizzle`` is the semantic SMEM layout descriptor used by
        author code.  TMA tensor maps and tcgen05 descriptors use separate
        low-level enum encodings, so convert at the API boundary instead of
        carrying multiple encodings through kernel configuration.
        """
        if target_type is Swizzle:
            return self

        from cutlass.experimental.cuda import TensorMapSwizzle  # noqa: PLC0415

        mapping: dict[Swizzle, object]
        if target_type is TensorMapSwizzle:
            mapping = {
                Swizzle(0, 0, 0): TensorMapSwizzle.none,
                Swizzle(1, 4, 3): TensorMapSwizzle.s32b,
                Swizzle(2, 4, 3): TensorMapSwizzle.s64b,
                Swizzle(3, 4, 3): TensorMapSwizzle.s128b,
            }
        else:
            raise TypeError(f"Unsupported swizzle conversion target: {target_type!r}")
        try:
            return mapping[self]
        except KeyError as exc:
            raise ValueError(f"No {target_type.__name__} preset for {self!r}.") from exc


# =============================================================================
# Standalone swizzle library functions
# =============================================================================


@dsl_user_op
def apply_swizzle(
    ptr: object,
    swizzle: Swizzle,
    *,
    loc: _ir.Location | None = None,
    ip: _ir.InsertionPoint | None = None,
) -> object:
    """Apply a CuTe-style XOR swizzle to a base-DSL Pointer's SMEM address.

    This low-level helper returns the physically swizzled pointer for op
    families that need the address itself, such as per-thread
    ``cp_async_shared_global`` destinations. For ordinary SMEM reads and writes,
    prefer :func:`load_swizzled` and :func:`store_swizzled` so vector width is
    preserved.
    """
    if swizzle.bbits == 0:
        return ptr

    from .typing import Pointer  # noqa: PLC0415
    from .._mlir.dialects import cute as _cute_ir  # noqa: PLC0415

    base_ptr = cast(Pointer, ptr)
    sw_ty = _ir.Type.parse(
        f'!cute.swizzle<"S<{swizzle.bbits},{swizzle.mbase},{swizzle.sshift}>">'
    )
    llvm_ptr = base_ptr.llvm_ptr
    op = _cute_ir.ApplySwizzleOp(
        ptr=llvm_ptr,
        swizzle=sw_ty.attribute,
        results=[llvm_ptr.type],
        loc=loc,
        ip=ip,
    )
    return Pointer._from_raw_ptr(op.result, base_ptr.dtype)


@dsl_user_op
def load_swizzled(
    ptr: object,
    swizzle: Swizzle,
    alignment: int | None = None,
    *,
    count: int | None = None,
    loc: _ir.Location | None = None,
    ip: _ir.InsertionPoint | None = None,
) -> object:
    """Load scalar or vector from a swizzled SMEM base-DSL Pointer.

    Builds a CuTe-typed pointer with the swizzle encoded in its type, then
    issues a CuTe load.  Equivalent to ``ptr.load_swizzled(swizzle, ...)``.

    **Prefer wide vectors for efficiency.**  The CuTe tensor that
    implements the load remaps addresses over whole 128-bit vectors
    (16 B, 8 fp16), not individual elements.  Any ``count`` value is
    correct — CuTe handles the XOR for scalar reads (``count=None``),
    ``count=8`` atoms, single-period loads, and counts that span
    multiple swizzle periods.  The preference is about cost: scalar
    and ``count=8`` reads emit N× the memory ops of a single wide
    load, block ILP, and produce more instructions for the same
    bytes.  Use ``count = <swizzle period>`` (16 / 32 / 64 fp16 for
    s32b / s64b / s128b) or the full per-thread row span unless you
    have a concrete measured reason to fragment.

    :param ptr: SMEM base-DSL ``Pointer`` to load from.
    :param swizzle: ``Swizzle`` descriptor matching the SMEM layout.
    :param alignment: Optional byte alignment hint for the load.
    :param count: Element count.  ``None`` → scalar load.  Any integer
        ``N ≥ 1`` → a ``Vector`` of length ``N`` (even ``count=1``
        returns a 1-element Vector, not a scalar).  Very large counts
        (≥ 256) can stress the MLIR lowering; if you see compile-time
        regressions, drop back to one period per load.
    :return: Scalar ``Numeric`` when ``count is None``; otherwise a
        base-DSL ``Vector[ptr.dtype, count]`` so callers can use
        ``vec.reduce(op)``, ``vec.to(dtype)``, element-wise arithmetic,
        and pair with :func:`store_swizzled` without any intermediate
        conversions.

    .. code-block:: python

        sw  = cutlass.Swizzle.from_name("s128b")
        vec = (smem_ptr + offset).load_swizzled(sw, count=64)  # one period, fp16

    :sync-class: Per-thread — single-thread SMEM load; not a collective.
    :elect-safe: N/A — no divergent hardware side effect.
    :device: SM80+ (swizzle kinds depend on what downstream op consumes
        them; for ``tcgen05.mma kind::f16`` on SM100 the swizzle must be
        ``SWIZZLE_128B``, i.e. ``Swizzle.from_name("s128b")``).
    :side-effects: issues a swizzle-aware CuTe load; writes into the
        register file (as scalar or 1-D Vector).
    :peer: Pairs with :func:`store_swizzled` for an SMEM round-trip; the
        vector returned here can be fed back verbatim.  Swizzle must
        match the writer's (TMA ``TensorMapSwizzle.sXb`` or a prior
        :func:`store_swizzled` with the same ``Swizzle``). Keep the same
        logical swizzle name across the TMA descriptor,
        ``load_swizzled`` / ``store_swizzled``, and tcgen05 descriptor;
        note that those APIs use different integer encodings for the
        same logical swizzle.
    """
    from .typing import Pointer  # noqa: PLC0415
    import cutlass.cute as cute  # noqa: PLC0415

    base_ptr = cast(Pointer, ptr)
    swizzle_obj = cute.make_swizzle(
        swizzle.bbits, swizzle.mbase, swizzle.sshift, loc=loc, ip=ip
    )
    cute_ptr = cute.make_ptr(
        base_ptr.dtype,
        base_ptr,
        assumed_align=alignment,
        swizzle_=swizzle_obj,
        loc=loc,
        ip=ip,
    )
    if count is None:
        return cute_ptr.load(loc=loc, ip=ip)
    # Shape must be a tuple — passing a bare int here causes downstream
    # make_tensor / layout machinery to mis-flatten for count > 8 and
    # produces "`load_swizzled` count must be 8" tutorial folklore.
    cute_tensor = cute.make_tensor(cute_ptr, (count,), loc=loc, ip=ip)
    # TensorSSA.to_vector() returns a base-DSL Vector so the result works
    # natively with Vector.reduce(op), Vector.to(dtype), element-wise ops,
    # and round-trips through store_swizzled without manual conversion.
    return cute_tensor.load(loc=loc, ip=ip).to_vector(loc=loc, ip=ip)


@dsl_user_op
def store_swizzled(
    ptr: object,
    value: object,
    swizzle: Swizzle,
    alignment: int | None = None,
    *,
    loc: _ir.Location | None = None,
    ip: _ir.InsertionPoint | None = None,
) -> None:
    """Store a scalar or 1-D vector to a swizzled SMEM base-DSL Pointer.

    Builds a CuTe-typed pointer with the swizzle encoded in its type, then
    issues a CuTe store.  Equivalent to ``ptr.store_swizzled(value, swizzle, ...)``.

    **Prefer wide vectors.**  The CuTe tensor that implements the store
    remaps addresses over whole 128-bit vectors (16 B, 8 fp16), not
    individual elements.  Pair a ``load_swizzled(sw, count=N)`` with a
    ``store_swizzled(vec, sw)`` of the same width — one SMEM load,
    one SMEM store, compute in registers between them.  Storing
    scalars one at a time on a swizzled pointer is legal (a dedicated
    scalar path handles the XOR), but inflates SMEM traffic by N×;
    there is no reason to fragment a vector return from
    :func:`load_swizzled` into per-element stores.

    :param ptr: SMEM base-DSL ``Pointer`` to store to.
    :param value: Either a scalar ``Numeric`` / ``ArithValue`` / Python
        ``int`` / ``float`` (one element), or a 1-D ``Vector`` of
        values.  The element type is cast to ``ptr.dtype``
        automatically.  Mirrors :func:`load_swizzled`: a scalar return
        there pairs with a scalar ``value`` here; a ``Vector[T, N]``
        (any ``N ≥ 1``) return pairs with a matching ``Vector[T, N]``
        here.
    :param swizzle: ``Swizzle`` descriptor matching the SMEM layout.
    :param alignment: Optional byte alignment hint for the store.
    :raises ValueError: if ``value`` is a multi-dimensional Vector
        (only scalar or 1-D is accepted).

    .. code-block:: python

        # Canonical round-trip (preferred)
        sw  = cutlass.Swizzle.from_name("s128b")
        vec = (smem_ptr + offset).load_swizzled(sw, count=64)
        vec = (vec.to(cutlass.Float32) * 2.0).to(cutlass.Float16)
        (smem_ptr + offset).store_swizzled(vec, sw)

    :sync-class: Per-thread — single-thread SMEM store; not a collective.
    :elect-safe: N/A — no divergent hardware side effect.
    :device: SM80+ (swizzle kinds depend on what downstream op consumes
        them; for ``tcgen05.mma kind::f16`` on SM100 the swizzle must be
        ``SWIZZLE_128B``, i.e. ``Swizzle.from_name("s128b")``).
    :side-effects: issues a swizzle-aware CuTe store; writes into SMEM
        at the XOR'd physical address.  The ``Swizzle`` passed here
        defines the physical layout any subsequent reader must assume.
    :peer: Pairs with :func:`load_swizzled` — use the same ``Swizzle``
        on both ends of a register-residency round-trip.  A TMA reader
        consuming the tile must be built with a matching
        ``TensorMapSwizzle``.
    """
    from .typing import Pointer  # noqa: PLC0415
    import cutlass.cute as cute  # noqa: PLC0415

    base_ptr = cast(Pointer, ptr)
    # Detect scalar vs 1-D Vector. Scalars (Python int/float, Numeric, bare
    # ArithValue) have no `.shape`; Vector exposes `.shape = (N,)` for N ≥ 1.
    value_shape = getattr(value, "shape", None)
    if value_shape is None or not isinstance(value_shape, tuple):
        # Scalar path — route through the cute swizzle op + scalar store.
        # The cute.make_ptr / cute_ptr.store path used below for vectors
        # lowers a scalar store through `unrealized_conversion_cast` back
        # to !llvm.ptr<3> before emitting llvm.store, which drops the
        # swizzle-type annotation and stores at the unswizzled address.
        swizzled_ptr = cast(Pointer, apply_swizzle(base_ptr, swizzle, loc=loc, ip=ip))
        swizzled_ptr.store(value, loc=loc, ip=ip)
        return
    swizzle_obj = cute.make_swizzle(
        swizzle.bbits, swizzle.mbase, swizzle.sshift, loc=loc, ip=ip
    )
    cute_ptr = cute.make_ptr(
        base_ptr.dtype,
        base_ptr,
        assumed_align=alignment,
        swizzle_=swizzle_obj,
        loc=loc,
        ip=ip,
    )
    if len(value_shape) != 1:
        raise ValueError(
            "store_swizzled only supports scalar or 1-D Vector, "
            f"got shape {value_shape}"
        )
    count = value_shape[0]
    cute_tensor = cute.make_tensor(cute_ptr, (count,), loc=loc, ip=ip)
    # Internal: convert Vector -> TensorSSA and cast dtype before issuing the
    # cute-side store. This is an implementation detail; callers pass a Vector.
    cute_tensor.store(
        cute.TensorSSA.from_vector(value).to(base_ptr.dtype), loc=loc, ip=ip
    )


__all__ = [
    "Swizzle",
    "apply_swizzle",
    "load_swizzled",
    "store_swizzled",
]
