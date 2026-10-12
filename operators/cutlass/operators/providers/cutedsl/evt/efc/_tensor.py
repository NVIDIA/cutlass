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

"""User-facing tensor proxy and the subscript helper for the
``tensor.remap_modes[...]`` syntax.

``Tensor`` and ``_RemapModesAccessor`` are exposed on the ``EFC``
namespace as ``EFC.Tensor`` / ``EFC._RemapModesAccessor`` via
``ClassVar`` aliases declared in ``_base.py``.  Method bodies use
``Phase`` (from ``_phase``) and the in-module names ``Tensor`` /
``_RemapModesAccessor`` directly.
"""

# This is not to use module annotations from a future version but to change the type system to postpone the evaluation of annotations,
# about forward declaration and lazy type checking.
# See https://docs.python.org/3/library/__future__.html#future__.annotations and https://peps.python.org/pep-0563/.
from __future__ import annotations

import dataclasses
import enum
import math
import typing

import cutlass.cute as cute
import cutlass.cutlass_dsl as cutlass_dsl
from cutlass._mlir.dialects import llvm
from cutlass.cutlass_dsl import T, dsl_user_op
from cutlass.cute.typing import Float32, Int32, Uint32


"""
CUTLASS EFC Framework
"""
from ._helpers import log
from ._phase import Phase

if typing.TYPE_CHECKING:
    # Annotation-only reference to ``EFC`` from ``_base``; importing it
    # at runtime would be circular (``_base`` imports this module to
    # complete its ``EFC`` definition).  ``from __future__ import
    # annotations`` makes the parameter / attribute annotations below
    # strings, so ``EFC`` is only resolved by type checkers, not at
    # import time.
    from ._base import EFC


# Reduction operators accepted by ``Tensor.reduce``.  ``cute.ReductionOp``
# (re-exported from ``nvvm.ReductionOp``) defines the catalog used
# everywhere else in the DSL, so EFC does not introduce a new enum --
# we just gate which entries we know how to lower.  Extend this tuple
# as additional device-side emits are wired through; see DESIGN.md
# "Scalar Reduction".
_SUPPORTED_REDUCE_OPS = (
    cute.ReductionOp.ADD,
    cute.ReductionOp.MAX,
    cute.ReductionOp.MIN,
)


@dsl_user_op
def _atomic_fmin(
    ptr,
    val: Float32,
    *,
    sign_bit: typing.Optional[bool] = None,
    sem: typing.Optional[
        typing.Literal["relaxed", "release", "acquire", "acq_rel"]
    ] = None,
    scope: typing.Optional[typing.Literal["gpu", "cta", "cluster", "sys"]] = None,
    loc=None,
    ip=None,
) -> Float32:
    """Atomic fmin via integer bitcast, mirror of ``cute.arch.atomic_fmax``.

    The DSL ships an ``atomic_fmax`` (``nvvm_wrappers.py``) but not its
    ``fmin`` sibling.  Hardware ``atomicrmw`` has no FMIN encoding, so
    we reuse the same bitcast trick atomic_fmax uses, inverted:

    - Non-negative floats: IEEE-754 bit patterns are monotonic with
      magnitude, so ``cute.arch.atomic_min`` on the ``Int32`` bitcast
      gives the smaller float.
    - Negative floats: the unsigned-int bit pattern grows with
      magnitude, so the most-negative float (closest to ``-inf``)
      maps to the largest unsigned int.  ``cute.arch.atomic_max`` on
      the ``Uint32`` bitcast auto-promotes to UMAX inside the
      ``atomic_max`` wrapper and yields that float.

    ``sign_bit`` lets callers skip the runtime branch when the value's
    sign is known statically.
    """
    intval = llvm.bitcast(T.i32(), val.ir_value(loc=loc, ip=ip), loc=loc, ip=ip)
    # For negative floats, the most-negative one (smallest float
    # value) maps to the largest unsigned-int bit pattern.
    then_body = lambda: cute.arch.atomic_max(
        ptr, Uint32(intval), sem=sem, scope=scope, loc=loc, ip=ip
    )
    # For non-negative floats, the smallest float maps to the smallest
    # signed-int bit pattern.
    else_body = lambda: cute.arch.atomic_min(
        ptr, Int32(intval), sem=sem, scope=scope, loc=loc, ip=ip
    )

    if sign_bit is None:
        old_intval = cutlass_dsl.if_generate(
            Int32(intval) < 0,
            then_body,
            else_body,
            [],
            [Int32],
            loc=loc,
            ip=ip,
        )
    elif sign_bit:
        old_intval = then_body()
    else:
        old_intval = else_body()

    assert not isinstance(old_intval, list)
    return Float32(
        llvm.bitcast(T.f32(), old_intval.ir_value(loc=loc, ip=ip), loc=loc, ip=ip)
    )


def _max_identity(dtype):
    """Return the identity element for a MAX reduction over ``dtype``.

    Float: ``-inf``.  Signed integer: most-negative representable
    value (``-2**(width-1)``).  Unsigned integer: ``0``.  These are
    derived from ``dtype.width`` and ``dtype.signed`` at JIT time.
    """
    if dtype.is_float:
        return dtype(-math.inf)
    if dtype.signed:
        return dtype(-(2 ** (dtype.width - 1)))
    return dtype(0)


def _min_identity(dtype):
    """Return the identity element for a MIN reduction over ``dtype``.

    Float: ``+inf``.  Signed integer: most-positive representable
    value (``2**(width-1) - 1``).  Unsigned integer:
    ``2**width - 1``.
    """
    if dtype.is_float:
        return dtype(math.inf)
    if dtype.signed:
        return dtype((2 ** (dtype.width - 1)) - 1)
    return dtype((2**dtype.width) - 1)


# Four small op-keyed Python helpers that the unified
# ``_emit_warpgroup_reduce`` skeleton below consults.  Each returns
# the per-op piece of IR while the skeleton keeps the 5-step
# structure (intra-thread fold -> intra-warp fold -> SMEM write ->
# barrier -> CTA fold + atomic) in one place.
#
# These are *plain* Python functions (no ``@cute.jit``).  When called
# from inside a JIT body, their ``if op is ...`` dispatch executes at
# JIT-compile time -- only the chosen branch emits IR, the others are
# never compiled.  Add a new op by extending each of the four helpers
# and updating ``_SUPPORTED_REDUCE_OPS`` plus the PyTorchEvaluation
# branch in ``Tensor.reduce``.


def _op_identity(op, dtype):
    """Identity element of ``op`` over ``dtype``."""
    if op is cute.ReductionOp.ADD:
        return dtype(0)
    if op is cute.ReductionOp.MAX:
        return _max_identity(dtype)
    if op is cute.ReductionOp.MIN:
        return _min_identity(dtype)
    raise NotImplementedError(f"_op_identity for op {op!r} not implemented")


def _op_warp_reduce(op, intra):
    """Intra-warp fold of ``intra`` under ``op``.

    Returns a Numeric whose value is replicated across all 32 lanes
    of the warp.  ``cute.arch.warp_reduction_max`` already dispatches
    between ``fmax`` (for Float32) and ``cutlass_dsl.max`` (for ints)
    internally; we use the same lambda-dispatch pattern for MIN.
    """
    if op is cute.ReductionOp.ADD:
        return cute.arch.warp_reduction_sum(intra)
    if op is cute.ReductionOp.MAX:
        return cute.arch.warp_reduction_max(intra)
    if op is cute.ReductionOp.MIN:
        return cute.arch.warp_reduction(
            intra,
            op=lambda x, y: (
                cute.arch.fmin(x, y)
                if isinstance(x, Float32)
                else cutlass_dsl.min(x, y)
            ),
        )
    raise NotImplementedError(f"_op_warp_reduce for op {op!r} not implemented")


def _op_combine(op, dtype, a, b):
    """Combine two scalars under ``op`` (the cross-warp step).

    Float MAX / MIN use ``cute.arch.fmax`` / ``fmin`` for proper
    NaN handling; integer MAX / MIN go through ``cutlass_dsl.max`` /
    ``min``.  ADD is the same ``+`` for both.
    """
    if op is cute.ReductionOp.ADD:
        return a + b
    if op is cute.ReductionOp.MAX:
        return cute.arch.fmax(a, b) if dtype.is_float else cutlass_dsl.max(a, b)
    if op is cute.ReductionOp.MIN:
        return cute.arch.fmin(a, b) if dtype.is_float else cutlass_dsl.min(a, b)
    raise NotImplementedError(f"_op_combine for op {op!r} not implemented")


def _op_atomic(op, dtype, dest_iter, val):
    """Final cross-CTA atomic for ``op`` on ``dtype``.

    Float MAX uses ``cute.arch.atomic_fmax`` (bitcast trick); float
    MIN uses the file-local ``_atomic_fmin`` mirror.  Integer MAX /
    MIN use plain ``cute.arch.atomic_max`` / ``atomic_min`` which
    auto-promote to UMAX / UMIN for unsigned dtypes inside
    ``_atomic``.  ADD goes through ``cute.arch.atomic_add`` for
    both (auto-promoted to FADD for floats).
    """
    if op is cute.ReductionOp.ADD:
        cute.arch.atomic_add(dest_iter, val)
        return
    if op is cute.ReductionOp.MAX:
        if dtype.is_float:
            cute.arch.atomic_fmax(dest_iter, val)
        else:
            cute.arch.atomic_max(dest_iter, val)
        return
    if op is cute.ReductionOp.MIN:
        if dtype.is_float:
            _atomic_fmin(dest_iter, val)
        else:
            cute.arch.atomic_min(dest_iter, val)
        return
    raise NotImplementedError(f"_op_atomic for op {op!r} not implemented")


@cute.jit
def _emit_warpgroup_reduce(
    value,
    op,
    s_reduce,
    barrier,
    dest_iter,
    num_epi_warps,
    first_epi_warp_id,
):
    """Emit the warpgroup-wide reduction for ``op``:

      (1) Intra-thread fragment fold via ``TensorSSA.reduce``.
      (2) Intra-warp fold via ``_op_warp_reduce``.
      (3) Lane 0 of each epi warp writes its per-warp partial to
          its slot in the SMEM scratch buffer.
      (4) Warpgroup barrier ensures all four slots are committed
          before any read.
      (5) The first epi warp's lane 0 folds the slots via
          ``_op_combine`` and emits one ``_op_atomic`` to the
          destination.

    The op-specific pieces (identity, warp reducer, cross-warp
    combiner, final atomic) live in the four ``_op_*`` Python
    helpers above; this body keeps the 5-step structure visible
    top-to-bottom regardless of the op being emitted.

    The epilogue warpgroup is not assumed to start at warp 0 of
    the CTA -- ``first_epi_warp_id`` (the operation's
    ``epilogue_warp_id[0]``) is subtracted from the absolute
    ``cute.arch.warp_idx()`` to get an epilogue-relative slot
    index in ``[0, num_epi_warps)``.  ``s_reduce`` is sized to
    exactly ``num_epi_warps`` slots, so the SMEM scratch lives
    in [slot 0, slot num_epi_warps), independent of the
    consumer warpgroup's CTA-level offset.  The atomic-emit gate
    fires on the first epi warp's lane 0 (i.e.
    ``warp_idx == first_epi_warp_id``), which collapses to the
    legacy "warp 0" case when the epilogue happens to start at
    warp 0.

    Lives at module scope and decorated with ``@cute.jit`` so the
    DSL preprocesses its body and turns the dynamic ``if``
    predicates (``lane_idx() == 0`` etc.) into proper IR control
    flow.  ``Tensor.reduce`` cannot host this code directly because
    its outer ``match`` statement runs at plain-Python time, never
    going through the JIT preprocessor.
    """
    dtype = value.dtype
    identity = _op_identity(op, dtype)
    # (1) intra-thread fragment fold.
    intra = value.reduce(op, identity, reduction_profile=0)
    # (2) intra-warp fold: every lane of the warp ends up with the
    # same per-warp partial.
    warp_val = _op_warp_reduce(op, intra)
    # (3) lane 0 of each epi warp writes its partial into the
    # warp's slot of the scratch.  ``epi_warp_idx`` lives in
    # ``[0, num_epi_warps)`` regardless of where the epilogue
    # warpgroup starts inside the CTA.
    warp_idx = cute.arch.warp_idx()
    epi_warp_idx = warp_idx - first_epi_warp_id
    if cute.arch.lane_idx() == 0:
        s_reduce[epi_warp_idx] = warp_val
    # (4) cross-warp synchronisation so all four slots are visible
    # before the gathering warp reads them.
    barrier.arrive_and_wait()
    # (5) the first epi warp's lane 0 folds the slots and emits a
    # single atomic to the destination.  The kernel's existing
    # post-epilogue barrier (in ``__call__``, right after
    # ``epilogue_computation`` returns) doubles as the producer
    # fence for the next subtile's writes to the same scratch
    # slots, so no second post-atomic barrier is needed here.
    if epi_warp_idx == 0 and cute.arch.lane_idx() == 0:
        result = identity
        for i in range(num_epi_warps):
            result = _op_combine(op, dtype, result, s_reduce[i])
        _op_atomic(op, dtype, dest_iter, result)


def _count_distinct_offsets(frag):
    """Number of distinct destination offsets in a per-thread reduce
    fragment -- i.e. the global atomics ``_emit_axis_reduce`` emits per
    thread after the intra-thread register fold.

    The fragment's zero-stride layout is static, so each ``crd2idx`` is a
    compile-time constant and the count is a pure trace-time quantity.
    The dispatch selector uses it to choose between the direct GMEM
    scatter and the SMEM-staged fold; it is *not* a ``@cute.jit`` body,
    so a plain ``range`` (not ``range_constexpr``) is correct here.
    """
    flat = cute.group_modes(frag, 0, cute.rank(frag))
    offsets = {int(cute.crd2idx(j, flat.layout)) for j in range(cute.size(flat))}
    return len(offsets)


@cute.jit
def _emit_axis_reduce(value, op, dest):
    """Emit a non-scalar (row / column) reduction by folding each
    thread's fragment in registers first, then atomic-combining one
    partial per distinct destination address into the partitioned
    zero-stride destination view.

    ``dest`` is the reduce target partitioned to the *same* per-thread
    per-subtile fragment layout as ``value`` (the ``remap_modes``
    zero-stride-on-folded-axes view, partitioned through the same
    ``partition_C`` + ``partition_D`` chain as the accumulator).  The
    folded output axes carry stride 0, so fragment positions that differ
    only in a folded axis resolve to the *same* destination offset;
    positions differing in a kept axis resolve to distinct offsets.
    This is the categorical dual of the broadcast read: there one
    source element loads into many fragment positions through a
    zero-stride view; here many fragment positions combine into one
    destination element.

    Rather than emit one atomic per fragment position, group the
    positions by their destination offset and fold each group in
    registers (``_op_combine``), emitting a single atomic per distinct
    offset (``_op_atomic``).  The offset is the kept-coordinate key,
    derived purely from ``dest``'s (static) layout -- no TV-layout
    inspection.  ``crd2idx`` of a static position over that layout is a
    compile-time constant, so the grouping runs at JIT-trace time and
    the per-group fold collapses the intra-thread duplicates for free;
    the surviving cross-thread / cross-CTA duplicates still fold through
    the hardware atomics.  When the per-thread fragment is entirely
    folded -- every position shares one offset, the common case where
    the kept axis lives in the thread/base-pointer dimension -- this
    reduces the whole fragment to a single atomic per thread.

    Lives at module scope and is ``@cute.jit`` so the DSL preprocesses
    the unrolled fold/scatter in this lexical body; ``Tensor.reduce``
    runs at plain Python time and cannot host it directly.
    """
    dtype = value.dtype
    # Materialize the fragment expression into a register tensor so each
    # position can be paired with its destination offset.
    frag = cute.make_rmem_tensor(dest.shape, dtype)
    frag.store(value)
    frag_flat = cute.group_modes(frag, 0, cute.rank(frag))
    dest_flat = cute.group_modes(dest, 0, cute.rank(dest))
    # Group fragment positions by their destination offset.
    # ``range_constexpr`` unrolls in Python, so ``i`` is a compile-time
    # constant and ``crd2idx`` folds to a constant offset -- the grouping
    # is a trace-time dict, not a loop-carried IR value.  A plain
    # ``range`` here would instead lower to a dynamic ``scf.for`` (making
    # the offset dynamic and the dict a structure-changing loop carry).
    # The zero-stride aliasing lives in ``dest``'s layout, so positions
    # differing only in a folded axis share an offset.
    groups = {}  # static destination offset -> fragment positions
    for i in cutlass_dsl.range_constexpr(cute.size(dest_flat)):
        groups.setdefault(int(cute.crd2idx(i, dest_flat.layout)), []).append(i)
    # One register-folded atomic per distinct offset: folding the clump
    # of same-address positions here replaces that many same-address
    # atomics with a single combined one.
    items = list(groups.items())
    for g in cutlass_dsl.range_constexpr(len(items)):
        offset, positions = items[g]
        partial = frag_flat[positions[0]]
        for p in cutlass_dsl.range_constexpr(len(positions) - 1):
            partial = _op_combine(op, dtype, partial, frag_flat[positions[p + 1]])
        # The atomic needs the element's *address*, so offset the base
        # iterator by the (compile-time) layout offset for this group.
        _op_atomic(op, dtype, dest_flat.iterator + offset, partial)


@cute.jit
def _reduce_smem_stripe(kept_extent, num_epi_warps, first_epi_warp_id):
    """Cooperative striping over a ``kept_extent`` SMEM buffer: returns
    ``(epi_tidx, num_epi_threads, n_stripes)`` so epi thread ``epi_tidx``
    owns slots ``epi_tidx, epi_tidx + num_epi_threads, ...``.  ``n_stripes``
    is compile-time; plain helper, called from ``@cute.jit`` bodies.
    """
    num_epi_threads = num_epi_warps * 32
    epi_tidx = (cute.arch.warp_idx() - first_epi_warp_id) * 32 + cute.arch.lane_idx()
    n_stripes = (kept_extent + num_epi_threads - 1) // num_epi_threads
    return epi_tidx, num_epi_threads, n_stripes


# The SMEM-staged kept-axis reduction is split into three phases so the
# fold can accumulate *across* subtiles in one per-CTA buffer and flush
# only once -- driven by the operation around the subtile loop
# (``EFC.Kernel.reduce_smem_init`` / ``reduce_smem_flush``), with the
# per-subtile fold emitted from ``Tensor.reduce``.  Folding once per CTA
# instead of once per subtile cuts both the global-atomic count and the
# warpgroup barriers by ``subtile_cnt``.


@cute.jit
def _emit_axis_reduce_smem_init(
    op, dtype, smem_buf, kept_extent, barrier, num_epi_warps, first_epi_warp_id
):
    """Initialise the per-CTA SMEM fold buffer to the op identity (once,
    before the subtile loop) and fence so every thread sees it before the
    first fold."""
    identity = _op_identity(op, dtype)
    epi_tidx, num_epi_threads, n_stripes = _reduce_smem_stripe(
        kept_extent, num_epi_warps, first_epi_warp_id
    )
    for s in cutlass_dsl.range_constexpr(n_stripes):
        slot = epi_tidx + s * num_epi_threads
        if slot < kept_extent:
            smem_buf[slot] = identity
    barrier.arrive_and_wait()


@cute.jit
def _emit_axis_reduce_smem_fold(value, op, smem_frag):
    """Fold one subtile's contribution into the SMEM buffer: intra-thread
    register fold (as in ``_emit_axis_reduce``), then one SMEM atomic per
    distinct slot into ``smem_frag`` -- the mirror of the destination's
    zero-stride view, so positions and threads sharing a kept coordinate
    alias the same slot and the shared-memory atomics fold them.

    No barrier here: the buffer persists across subtiles and the atomics
    are associative, so successive subtiles simply accumulate.  The init
    fence precedes the first fold and the flush fence follows the last.
    """
    dtype = value.dtype
    frag = cute.make_rmem_tensor(smem_frag.shape, dtype)
    frag.store(value)
    frag_flat = cute.group_modes(frag, 0, cute.rank(frag))
    smem_flat = cute.group_modes(smem_frag, 0, cute.rank(smem_frag))
    groups = {}
    for j in cutlass_dsl.range_constexpr(cute.size(smem_flat)):
        groups.setdefault(int(cute.crd2idx(j, smem_flat.layout)), []).append(j)
    items = list(groups.items())
    for g in cutlass_dsl.range_constexpr(len(items)):
        offset, positions = items[g]
        partial = frag_flat[positions[0]]
        for p in cutlass_dsl.range_constexpr(len(positions) - 1):
            partial = _op_combine(op, dtype, partial, frag_flat[positions[p + 1]])
        _op_atomic(op, dtype, smem_flat.iterator + offset, partial)


@cute.jit
def _emit_axis_reduce_smem_flush(
    op,
    dtype,
    smem_buf,
    gmem_base,
    kept_extent,
    barrier,
    num_epi_warps,
    first_epi_warp_id,
):
    """Fence after the last subtile's fold, flush the accumulated SMEM
    buffer to global memory (one global atomic per kept coordinate,
    combined onto the destination's existing content; the kept axis is
    stride-1 contiguous, so coordinate ``k`` lives at ``gmem_base + k``),
    then fence so a persistent CTA can re-init the buffer for its next
    output tile without racing this flush's reads."""
    barrier.arrive_and_wait()
    epi_tidx, num_epi_threads, n_stripes = _reduce_smem_stripe(
        kept_extent, num_epi_warps, first_epi_warp_id
    )
    for s in cutlass_dsl.range_constexpr(n_stripes):
        slot = epi_tidx + s * num_epi_threads
        if slot < kept_extent:
            _op_atomic(op, dtype, gmem_base + slot, smem_buf[slot])
    barrier.arrive_and_wait()


def _ensure_no_reduce_read_conflict(attributes, name):
    """Raise if the same destination is used as both a ``.load()``
    target and a ``.reduce()`` target inside one epilogue.

    The cross-CTA atomic emitted by ``Tensor.reduce`` races against
    any concurrent ``.load()`` of the same buffer in the same epilogue
    -- there is no defined ordering between threads that hit the
    atomic and threads that read the destination, so the load can
    observe either the pre- or post-reduction value (or, depending
    on memory-ordering semantics, neither).  Forbid the combination
    at ``ParameterAnalysis`` time rather than let the kernel ship
    with an undefined-value bug.

    Called from both ``Tensor.load`` and ``Tensor.reduce`` after
    each has set its own flag (``is_read`` / ``reduce_op``), so the
    invariant is order-independent: ``load`` -> ``reduce`` and
    ``reduce`` -> ``load`` both trigger the same diagnostic on the
    second call, regardless of which side appeared first.
    """
    if attributes.is_read and attributes.reduce_op is not None:
        raise ValueError(
            f"Tensor destination {name!r} was used as both a "
            f".load() target and a .reduce() target in the same "
            f"epilogue; the cross-CTA atomic emitted by reduce() "
            f"races against any .load() of the same buffer, so "
            f"they cannot share a destination."
        )


class Transport(enum.Enum):
    """Per-tensor data transport for an EFC supplemental tensor.

    Selects between four classes of GMEM<->register data movement,
    along two orthogonal axes: TMA descriptor vs. direct addressing,
    and synchronous vs. asynchronous to the issuing thread.

    * ``TMA`` -- TMA-staged through SMEM via the bulk-tensor copy
      engine (default).  Read and write directions both supported.
    * ``SYNC_GMEM_LOAD`` -- synchronous direct load (read only).
      No SMEM staging; the consumer warp emits a per-thread
      ``cute.copy`` with ``cute.nvgpu.CopyUniversalOp`` straight
      from GMEM to a register fragment.  Used for read tensors
      whose alignment, vector width or dimensionality cannot be
      expressed as a TMA descriptor.
    * ``SYNC_GMEM_STORE`` -- synchronous direct store (write only).
      Symmetric to ``SYNC_GMEM_LOAD``: the consumer warp emits a
      per-thread ``cute.copy`` from a register fragment to GMEM.
    * ``ASYNC_GMEM_LOAD`` -- asynchronous load through SMEM via
      ``cp.async`` (read only).  Uses SMEM staging like ``TMA``,
      but emits per-thread ``cp.async`` ops with an explicit
      ``cp.async.mbarrier.arrive`` instead of the byte-counted TMA
      arrive.  For read tensors that need SMEM staging but cannot
      be expressed as a TMA descriptor.
    """

    TMA = "tma"
    SYNC_GMEM_LOAD = "sync_gmem_load"
    SYNC_GMEM_STORE = "sync_gmem_store"
    ASYNC_GMEM_LOAD = "async_gmem_load"


_LOAD_TRANSPORTS = (Transport.TMA, Transport.SYNC_GMEM_LOAD, Transport.ASYNC_GMEM_LOAD)
_STORE_TRANSPORTS = (Transport.TMA, Transport.SYNC_GMEM_STORE)


class _RemapModesAccessor:
    """Helper to enable ``C.remap_modes[:,0,1]`` syntax via ``__getitem__``.

    Converts ``slice(None)`` (``:`` in subscript notation) to ``True``
    (broadcast) and passes integers through as mode indices.
    """

    def __init__(self, tensor):
        self._tensor = tensor

    @staticmethod
    def _convert_subscript_element(i, k):
        """Convert a single subscript element to a source_mode_map entry.

        Only ``:`` (broadcast) and ``int`` (mode index) are valid.
        Reject everything else early with a clear message referencing
        the ``C.remap_modes[:, 0, 1]`` syntax.
        """
        if isinstance(k, int):
            return k
        if isinstance(k, slice):
            if k != slice(None):
                raise TypeError(
                    f"remap_modes subscript element [{i}] is a "
                    f"non-trivial slice ({k.start}:{k.stop}:{k.step}). "
                    f"Only ':' (broadcast) is supported, "
                    f"e.g. C.remap_modes[:, 0, 1]."
                )
            return True
        raise TypeError(
            f"remap_modes subscript element [{i}] has unsupported type "
            f"{type(k).__name__}: {k!r}. Each element must be ':' "
            f"(broadcast) or an int (mode index), "
            f"e.g. C.remap_modes[:, 0, 1]."
        )

    def __getitem__(self, key):
        if not isinstance(key, tuple):
            key = (key,)
        source_mode_map = tuple(
            self._convert_subscript_element(i, k) for i, k in enumerate(key)
        )
        return self._tensor.configuration.remap_modes(
            source=self._tensor,
            source_mode_map=source_mode_map,
        )


class Tensor:
    """A proxy object to be used as an EFC argument to introspect or execute
    the epilogue configuration function in a given phase.
    """

    @dataclasses.dataclass
    class ParameterAttributes:
        """Store some characteristics of the epilogue parameters."""

        is_tensor: bool  # Tensor or scalar.
        is_read: bool = False  # This tensor is read.
        is_written: bool = False  # This tensor is written.
        # The name of the tensor to be remapped.
        mapped_source: str = None
        # The remapping modes to define the new tensor in respect to the
        # layout model. Each element is either an integer to express the
        # source mode to map at its place or `True` to broadcast the source
        # tensor for this mode.
        source_mode_map: tuple = None
        # True if the source_mode_map has only broadcast modes, so the
        # tensor can degenerate to a single scalar as an optimization.
        degenerate_to_scalar: bool = False
        # Per-tensor data transport.  See ``Transport`` for the catalog.
        # Stamped at ``ParameterAnalysis``; first-call-wins (subsequent
        # calls with a disagreeing ``via`` raise ``ValueError``).
        transport: Transport = Transport.TMA
        # Width of one direct GMEM transaction in bits (synchronous
        # or asynchronous), applied when ``transport`` is not
        # ``Transport.TMA``.  Carries
        # the value the user passed to ``Tensor.load`` / ``Tensor.store``:
        # ``None`` (the default) means "auto-derive in the kernel from
        # the per-thread fragment's max-common-layout, capped at 256
        # bits"; an explicit integer forces that exact width regardless
        # of alignment.  The auto-derive path mirrors
        # ``cutlass.utils.gemm.sm100.epilogue``, which has been the
        # canonical no-TMA-store width-picking logic for a while --
        # using the same formula keeps the direct paths consistent
        # with the rest of the codebase.
        num_bits_per_copy: int | None = None
        # Reduction operator, set by ``Tensor.reduce`` during
        # ``ParameterAnalysis``.  When ``None`` (the default), the
        # tensor is not a reduction target and the standard
        # ``store`` / TMA path is used.  When non-``None``, the
        # destination bypasses TMA / SMEM and the device emits a
        # cross-CTA atomic at the destination address.  Restricted
        # to the ``degenerate_to_scalar`` case (all-``:`` remap
        # subscript); see DESIGN.md "Scalar Reduction".
        reduce_op: typing.Any = None

        @property
        def is_direct(self) -> bool:
            """True iff this tensor bypasses SMEM staging entirely (the
            synchronous register<->GMEM transports).  ``ASYNC_GMEM_LOAD``
            still uses SMEM staging and therefore is *not* "direct" in
            this sense -- the predicate is used to gate skips of the
            staging machinery."""
            return self.transport in (
                Transport.SYNC_GMEM_LOAD,
                Transport.SYNC_GMEM_STORE,
            )

        @property
        def reduce_folded_axes(self) -> tuple:
            """Output-tile axes folded away by a remap reduction: the
            ``:`` (broadcast / ``True``) entries of ``source_mode_map``,
            as output-mode indices.

            These are the axes the device collapses when reducing into
            this destination.  ``degenerate_to_scalar`` is exactly the
            case where *every* output axis is folded (so
            ``reduce_kept_axes`` is empty).  Empty when this is not a
            remapped tensor.

            Derived from ``source_mode_map`` so there is a single source
            of truth: the remap subscript already encodes fold-vs-keep
            (``_remap.py`` turns folded axes into zero-stride modes, the
            categorical dual of the broadcast read).
            """
            if self.source_mode_map is None:
                return ()
            return tuple(i for i, v in enumerate(self.source_mode_map) if v is True)

        @property
        def reduce_kept_axes(self) -> tuple:
            """Output-tile axes preserved by a remap reduction: the
            integer entries of ``source_mode_map``, in output-mode
            order.  Empty for the scalar (all-folded) case.

            For a kept-axis reduction (e.g. a column bias keeping N),
            the device folds ``reduce_folded_axes`` and atomically
            scatters one reduced value per coordinate of these kept
            axes into the zero-stride destination view.
            """
            if self.source_mode_map is None:
                return ()
            return tuple(i for i, v in enumerate(self.source_mode_map) if v is not True)

    def __init__(
        self,
        phase: Phase,
        name: str,
        efc: EFC,
        configuration,
    ):
        """Initialize a tensor proxy bound to an EFC phase and configuration.

        This proxy tracks how an epilogue parameter is used during different
        phases of EFC execution and provides access to per-parameter metadata.
        It also captures the current configuration context so later `load()`
        and `store()` calls can route to the correct backend (analysis,
        kernel-thread operation, or PyTorch evaluation).

        Args:
            phase: Current EFC phase controlling the proxy behavior.
            name: Parameter name as declared in the epilogue function.
            efc: Owning EFC instance that holds shared state.
            configuration: Phase-specific configuration with runtime args.
        """
        self.phase = phase
        self.name = name
        self.efc = efc
        self.configuration = configuration
        self.attributes: Tensor.ParameterAttributes = efc.parameter_attributes[name]
        log(f"Tensor {self.name = }")

    def _record_copy_options(
        self, via: Transport, num_bits_per_copy: int | None
    ) -> None:
        """Stamp the copy options on first call; verify on later calls."""
        # ``num_bits_per_copy`` sizes a direct (synchronous or async)
        # GMEM transaction; TMA derives its own transfer width from the
        # descriptor, so an explicit width with ``via=Transport.TMA`` is
        # a meaningless config.  Reject it loudly rather than silently
        # ignore it, matching the runtime-side validation.
        if via is Transport.TMA and num_bits_per_copy is not None:
            raise ValueError(
                f"Tensor {self.name!r}: num_bits_per_copy is only valid "
                f"for non-TMA transports, not via={via}."
            )
        # The flags are *per tensor*, not per access -- a tensor that is
        # both read and written must use the same ``via`` for both.
        seen = self.attributes.is_read or self.attributes.is_written
        if seen:
            if self.attributes.transport is not via:
                raise ValueError(
                    f"Tensor {self.name!r} accessed with conflicting "
                    f"``via``: previously {self.attributes.transport}, "
                    f"now {via}."
                )
            # ``num_bits_per_copy`` is only meaningful for non-TMA transports.
            if (
                via is not Transport.TMA
                and self.attributes.num_bits_per_copy != num_bits_per_copy
            ):
                raise ValueError(
                    f"Tensor {self.name!r} accessed with conflicting "
                    f"``num_bits_per_copy``: previously "
                    f"{self.attributes.num_bits_per_copy}, "
                    f"now {num_bits_per_copy}."
                )
        else:
            self.attributes.transport = via
            self.attributes.num_bits_per_copy = num_bits_per_copy

    def load(
        self,
        *,
        via: Transport = Transport.TMA,
        num_bits_per_copy: int | None = None,
    ):
        """Load a tensor value inside the EFC function.

        The behavior depends on the phase:
        - ParameterAnalysis: mark the tensor as read and return a dummy value
        - ThreadOperation: load from the epilogue context and cast to epi dtype
        - PyTorchEvaluation: return the runtime tensor from evaluation inputs

        ``via`` selects the data transport; see ``Transport``.
        ``num_bits_per_copy`` (compile-time int, default ``None``)
        controls the transaction width for non-TMA transports.
        ``None`` means "auto-derive in the kernel from the per-thread
        fragment's max-common-layout, capped at 256 bits".

        Raises ``ValueError`` at ``ParameterAnalysis`` time if the same
        destination is also a ``.reduce()`` target -- the cross-CTA
        atomic emitted on the reduce side races against any concurrent
        read.  The mirror check lives in ``Tensor.reduce`` and shares
        the same ``_ensure_no_reduce_read_conflict`` helper, so the
        diagnostic fires regardless of which call happens first.
        """
        if via not in _LOAD_TRANSPORTS:
            raise ValueError(
                f"Tensor.load() ``via`` must be one of "
                f"{tuple(t.name for t in _LOAD_TRANSPORTS)}, got {via!r}."
            )
        log(
            f"Tensor.load {self.name = } {self.phase = } "
            f"{via = } {num_bits_per_copy = }"
        )
        match self.phase:
            case Phase.ParameterAnalysis:
                self._record_copy_options(via, num_bits_per_copy)
                # Record that the tensor is read:
                self.attributes.is_read = True
                # Catch ``reduce()`` then ``load()`` on the same
                # destination -- the mirror check in
                # ``Tensor.reduce`` only catches the opposite
                # ordering, so a centralised helper keeps the
                # invariant order-independent.
                _ensure_no_reduce_read_conflict(self.attributes, self.name)
                # Some value to have expression evaluation happy
                return 1

            case Phase.ThreadOperation:
                # All paths populate ``epilogue_context.load[name]``:
                # TMA via ``load_setup``'s
                # ``tiled_copy_r2s.retile(tSR_rC).load()``,
                # ``SYNC_GMEM_LOAD`` via ``load_setup``'s
                # ``tTR_rC_direct.load()`` after a per-subtile direct
                # load fired before this body ran.  ``ASYNC_GMEM_LOAD``
                # follows the same per-subtile pattern as TMA but
                # through ``cp.async`` -- not yet wired up here.
                return self.configuration.epilogue_context.load[self.name].to(
                    self.efc.operation.epi_dtype
                )

            case Phase.PyTorchEvaluation:
                return self.configuration.args[self.name]

            case _:
                raise NotImplementedError(
                    f"load({self.name}) not implemented for phase {self.phase}"
                )

    def store(
        self,
        value,
        *,
        via: Transport = Transport.TMA,
        num_bits_per_copy: int | None = None,
    ):
        """Store a tensor value inside the EFC function.

        The behavior depends on the phase:
        - ParameterAnalysis: mark the tensor as written (no data movement)
        - ThreadOperation: store into epilogue context with JIT dtype
        - PyTorchEvaluation: copy into the runtime output tensor

        ``via`` selects the data transport; see ``Transport``.  Only
        ``Transport.TMA`` and ``Transport.SYNC_GMEM_STORE`` are valid
        for writes (``cp.async`` has no S2G analogue).
        ``num_bits_per_copy`` (compile-time int, default ``None``)
        controls the direct-store transaction width when ``via is
        Transport.SYNC_GMEM_STORE``.  ``None`` means "auto-derive in
        the kernel from the per-thread fragment's max-common-layout,
        capped at 256 bits".
        """
        if via not in _STORE_TRANSPORTS:
            raise ValueError(
                f"Tensor.store() ``via`` must be one of "
                f"{tuple(t.name for t in _STORE_TRANSPORTS)}, got {via!r}."
            )
        log(
            f"Tensor.store {self.name = } {self.phase = } "
            f"{via = } {num_bits_per_copy = }"
        )
        match self.phase:
            case Phase.ParameterAnalysis:
                self._record_copy_options(via, num_bits_per_copy)
                # Record that the tensor is written:
                self.attributes.is_written = True

            case Phase.ThreadOperation:
                # Both paths surface a register fragment via
                # ``epilogue_context.store[name]``: TMA via
                # ``store_setup``'s ``tRS_rD``, direct via
                # ``store_setup``'s ``tTR_rD_direct``.  The body writes
                # into it; for direct tensors, the per-subtile direct
                # store fires after the body returns.
                tRS_rD = self.configuration.epilogue_context.store[self.name]
                tRS_rD.store(value.to(self.efc.jit.tensor_dtype[self.name]))

            case Phase.PyTorchEvaluation:
                # Assign the PyTorch tensor target with the given value.
                self.configuration.args[self.name].copy_(value)

            case _:
                raise NotImplementedError(
                    f"store({self.name}) not implemented for phase {self.phase}"
                )

    def reduce(self, value, *, op):
        """Reduce ``value`` (a tile-shaped expression) into this destination
        tensor under the binary operator ``op``.

        Symmetric with broadcasting via ``remap_modes``: where broadcast
        expands a low-rank source by giving the missing output modes a
        zero-stride view, reduction collapses the tile onto a low-rank
        destination by folding the same modes away.  The kernel
        composes on top of whatever value the destination buffer
        already holds, so the user can pre-load it with a partial sum,
        a calibration bias, or just zero.

        Accepts ``op`` in ``{ADD, MAX, MIN}`` from ``cute.ReductionOp``
        and the all-``:`` remap subscript (single-element destination);
        both constraints are checked at ``ParameterAnalysis`` time.
        See DESIGN.md "Scalar Reduction" for the full design and
        extension points.

        Raises ``ValueError`` at ``ParameterAnalysis`` time if the same
        destination is also a ``.load()`` target (mirror of the check
        in ``Tensor.load``; the shared ``_ensure_no_reduce_read_conflict``
        helper keeps the invariant order-independent).

        :param value:  the tile-shaped expression to fold.
        :param op:     a ``cute.ReductionOp`` selecting the binary
                       operator; see ``_SUPPORTED_REDUCE_OPS``.
        """
        log(f"Tensor.reduce {self.name = } {self.phase = } {op = }")
        # The op gate is the same in every phase -- catch unsupported
        # operators early so we never reach the ThreadOperation /
        # PyTorchEvaluation code paths with a value we cannot lower.
        if op not in _SUPPORTED_REDUCE_OPS:
            raise ValueError(
                f"Tensor.reduce() op {op!r} is not supported; "
                f"supported ops are "
                f"{tuple(o.name for o in _SUPPORTED_REDUCE_OPS)}."
            )
        match self.phase:
            case Phase.ParameterAnalysis:
                # Reduction is only meaningful when the destination
                # has fewer modes than the output, which in EFC is
                # expressed by routing through ``remap_modes``.  A
                # direct ``dest.reduce(...)`` on the un-remapped proxy
                # has no folded axes, so it would just be a fancy
                # ``store`` and would mislead the user about what is
                # happening.
                if self.attributes.mapped_source is None:
                    raise ValueError(
                        f"Tensor.reduce() requires a remapped view; "
                        f"call it on '{self.name}.remap_modes[...]' "
                        f"with ':' for the output modes to fold."
                    )
                # Both the scalar (all-``:``) and the non-scalar
                # (row / column / per-batch, i.e. some kept axes)
                # destinations are supported.  The scalar case folds the
                # whole tile to one element via the warpgroup fold; the
                # non-scalar case atomic-scatters each fragment element
                # through the zero-stride destination view.  The split
                # is decided in the ``ThreadOperation`` phase on
                # ``degenerate_to_scalar``.
                # Multiple reduce calls onto the same destination must
                # agree on the operation: there is one atomic op type
                # per destination address, not one per call site.
                if (
                    self.attributes.reduce_op is not None
                    and self.attributes.reduce_op is not op
                ):
                    raise ValueError(
                        f"Tensor.reduce() on '{self.name}' was "
                        f"previously called with op "
                        f"{self.attributes.reduce_op!r}; cannot mix "
                        f"reduce operators on a single destination."
                    )
                self.attributes.is_written = True
                self.attributes.reduce_op = op
                # Catch ``load()`` then ``reduce()`` on the same
                # destination (and, via the mirror in ``Tensor.load``,
                # the opposite ordering too) -- the cross-CTA atomic
                # races against any concurrent read of the same buffer.
                _ensure_no_reduce_read_conflict(self.attributes, self.name)

            case Phase.ThreadOperation:
                # Both reduction emitters live at module scope and are
                # ``@cute.jit`` so the DSL preprocesses their dynamic
                # ``if`` / ``range_constexpr`` bodies; this ``match``
                # block runs at plain-Python time and cannot host that
                # code directly.
                ctx = self.configuration.epilogue_context
                if self.attributes.degenerate_to_scalar:
                    # Scalar destination: warpgroup-wide fold to one
                    # value, then a single cross-CTA atomic.  The
                    # epilogue warpgroup may start at any warp-aligned
                    # offset inside the CTA (e.g. warps ``[4,5,6,7]``);
                    # pass the first epi warp id so the helper computes
                    # an epilogue-relative SMEM-scratch slot index and
                    # gates the final atomic on the right warp.
                    _emit_warpgroup_reduce(
                        value,
                        op,
                        ctx.reduce_smem[self.name],
                        ctx.reduce_barrier,
                        ctx.reduce[self.name].iterator,
                        len(self.efc.operation.epilogue_warp_id),
                        self.efc.operation.epilogue_warp_id[0],
                    )
                else:
                    # Non-scalar (kept-axis) destination.  ``reduce_use_smem``
                    # (decided before the subtile loop, layout-derived) picks
                    # the path: when the folded axis lives in the thread
                    # dimension (column-style) the SMEM-staged fold pays, so
                    # emit just *this subtile's* fold into the per-CTA SMEM
                    # buffer -- the operation runs the init before the loop and
                    # the flush after, accumulating across subtiles.  Otherwise
                    # (value-dim fold, row-style: register fold already at the
                    # ``kept_extent`` floor) the direct scatter avoids the SMEM
                    # round-trip and the barriers entirely.
                    if ctx.reduce_use_smem[self.name]:
                        _emit_axis_reduce_smem_fold(
                            value, op, ctx.reduce_smem_frag[self.name]
                        )
                    else:
                        _emit_axis_reduce(value, op, ctx.reduce[self.name])

            case Phase.PyTorchEvaluation:
                # Compose the reduced ``value`` on top of the
                # destination's current content -- this is what makes
                # the "user pre-initializes" framing work and what the
                # GPU path will mirror by seeding the device-side
                # reduction with the loaded GMEM value.
                #
                # The original (un-remapped) destination tensor lives
                # under ``mapped_source``; we want to write into it
                # rather than into the broadcast view at ``self.name``
                # so the update is unambiguous when the view has
                # zero-strided dims.
                import torch

                source_name = self.attributes.mapped_source
                dest = self.configuration.args[source_name]
                # Reduce ``value`` (an output-shaped (m, n, l) tensor)
                # over the folded output axes only, keeping the kept
                # axes.  The scalar (all-``:``) case has every axis
                # folded, so this collapses to a single value -- the
                # same result the previous ``value.sum()`` / ``.max()``
                # / ``.min()`` produced.  ``torch.amax`` / ``amin`` are
                # used (not ``.max()`` / ``.min()``) because they accept
                # a tuple of dims and return values only (no indices).
                folded = self.attributes.reduce_folded_axes
                kept = self.attributes.reduce_kept_axes
                if op is cute.ReductionOp.ADD:
                    reduced = value.sum(dim=folded) if folded else value
                    combine = torch.add
                elif op is cute.ReductionOp.MAX:
                    reduced = torch.amax(value, dim=folded) if folded else value
                    combine = torch.maximum
                elif op is cute.ReductionOp.MIN:
                    reduced = torch.amin(value, dim=folded) if folded else value
                    combine = torch.minimum
                else:
                    # Defensive: should have been caught by the
                    # _SUPPORTED_REDUCE_OPS gate above.
                    raise NotImplementedError(
                        f"PyTorch reference for op {op!r} not implemented."
                    )
                # ``reduced`` now carries the kept axes in *output* mode
                # order; the destination is indexed by *source* axes.
                # Reorder reduced's axes into source order so it aligns
                # with ``dest`` (a no-op for a single kept axis).
                if kept:
                    kept_src = tuple(self.attributes.source_mode_map[i] for i in kept)
                    perm = sorted(range(len(kept)), key=lambda j: kept_src[j])
                    reduced = reduced.permute(perm)
                # ``view_as`` keeps the destination's exact shape (rank-0
                # / size-1 for scalar, the kept-axis vector otherwise) so
                # ``copy_`` does not complain about a shape mismatch.
                reduced = reduced.to(dest.dtype).view_as(dest)
                dest.copy_(combine(dest, reduced))

            case _:
                raise NotImplementedError(
                    f"reduce({self.name}) not implemented for phase {self.phase}"
                )

    @property
    def remap_modes(self):
        """Remap modes of this tensor to match the output shape (m, n, l).

        Use subscript syntax with ``:`` for broadcast (``True``) and
        integers for mode indices::

            C.remap_modes[:,0,1].load()    # broadcast along first dim
            Y.remap_modes[1,0,2].store(v)  # transpose
            s.remap_modes[:,:,:].load()     # scalar broadcast

        This is a ``@property`` so that ``C.remap_modes`` (without
        parentheses) returns a helper object whose ``__getitem__``
        intercepts the ``[...]`` subscript.  Without ``@property``,
        ``C.remap_modes[:,0,1]`` would be a syntax error because
        Python would see ``remap_modes`` as an unsubscripted method
        object, not something that supports ``[]``.
        """
        return _RemapModesAccessor(self)
