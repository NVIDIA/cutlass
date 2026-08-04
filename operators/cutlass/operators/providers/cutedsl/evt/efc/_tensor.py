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
    the CTA -- ``first_epi_warp_id`` (the operator's
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
                    self.efc.operator.epi_dtype
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
                # Only the all-``:'' (scalar destination) case is
                # wired up.  Bail loudly so the user knows the framework
                # cannot yet handle row / column / mixed reductions
                # even though the API would naturally extend to them.
                if not self.attributes.degenerate_to_scalar:
                    raise NotImplementedError(
                        f"Tensor.reduce() on '{self.name}' requires an "
                        f"all-':' remap subscript (single-element "
                        f"destination).  Row / column / partial "
                        f"reductions are not yet wired up."
                    )
                # Multiple reduce calls onto the same destination must
                # agree on the operator: there is one atomic op type
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
                # Delegate to the unified ``@cute.jit`` helper at
                # module scope: the 5-step warpgroup fold needs DSL
                # preprocessing of its dynamic ``if`` predicates
                # (``lane_idx() == 0``, ``warp_idx == 0 and ...``),
                # which only happens for code lexically inside a
                # JIT-decorated function.  The match block here runs
                # at plain-Python time and cannot host that body
                # directly.  ``_emit_warpgroup_reduce`` dispatches
                # per-op internally through the ``_op_*`` Python
                # helpers, so adding a new op only requires extending
                # those four helpers (and ``_SUPPORTED_REDUCE_OPS``).
                ctx = self.configuration.epilogue_context
                # The epilogue warpgroup may start at any
                # warp-aligned offset inside the CTA (e.g. warps
                # ``[4,5,6,7]``); pass the first epi warp id so
                # ``_emit_warpgroup_reduce`` can compute an
                # epilogue-relative slot index for the SMEM
                # scratch and gate the final atomic on the right
                # warp.
                _emit_warpgroup_reduce(
                    value,
                    op,
                    ctx.reduce_smem[self.name],
                    ctx.reduce_barrier,
                    ctx.reduce[self.name].iterator,
                    len(self.efc.operator.epilogue_warp_id),
                    self.efc.operator.epilogue_warp_id[0],
                )

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
                if op is cute.ReductionOp.ADD:
                    # ``value.sum()`` collapses across every axis to
                    # match the all-``:'' (scalar) destination case;
                    # ``view_as`` keeps the destination's rank-0 or
                    # rank-1-size-1 shape so ``copy_`` does not
                    # complain about a shape mismatch.
                    reduced = value.sum()
                    dest.copy_(dest + reduced.to(dest.dtype).view_as(dest))
                elif op is cute.ReductionOp.MAX:
                    reduced = value.max()
                    dest.copy_(
                        torch.maximum(dest, reduced.to(dest.dtype).view_as(dest))
                    )
                elif op is cute.ReductionOp.MIN:
                    reduced = value.min()
                    dest.copy_(
                        torch.minimum(dest, reduced.to(dest.dtype).view_as(dest))
                    )
                else:
                    # Defensive: should have been caught by the
                    # _SUPPORTED_REDUCE_OPS gate above.
                    raise NotImplementedError(
                        f"PyTorch reference for op {op!r} not implemented."
                    )

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
