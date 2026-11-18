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

from dataclasses import dataclass
from enum import Enum
from typing import Optional, Protocol, Sequence, TypeAlias, Union

from cutlass.cutlass_dsl import dsl_user_op
from cutlass._mlir.dialects import lir as cutlass_lir_ir, nvvm as _nvvm
from cutlass._mlir import ir
from cutlass.cutlass_dsl import lru_cache_ir
from cutlass._mlir.dialects.core import OperationTypeEnum, is_sm10x_mma_operation
from cutlass import cute
from cutlass.cute.typing import Boolean


class _SupportsIrValue(Protocol):
    def ir_value(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> ir.Value: ...


SkipWaitToken: TypeAlias = Union[bool, ir.Value, _SupportsIrValue]


class MmaOperand(Enum):
    """An Enum describing the MMA operand held by a pipeline's stage buffers."""

    A = "A"
    B = "B"
    C = "C"
    D = "D"
    METADATA = "Metadata"


# A member (``MmaOperand.A``), its name (``"A"``) or the IR keyword
# (``"Metadata"``) are all accepted where an MMA operand is expected.
MmaOperandSpec: TypeAlias = Union[MmaOperand, str]


def normalize_mma_operand(spec: MmaOperandSpec) -> MmaOperand:
    """Resolve an MMA operand argument to :class:`MmaOperand`."""
    if isinstance(spec, MmaOperand):
        return spec
    if isinstance(spec, str):
        try:
            return MmaOperand[spec]
        except KeyError:
            pass
        try:
            return MmaOperand(spec)
        except ValueError:
            names = ", ".join(f"{m.name} ({m.value})" for m in MmaOperand)
            raise ValueError(
                f"unknown MMA operand {spec!r}; expected one of {names}"
            ) from None
    raise TypeError(
        "MMA operand must be a MmaOperand, its name or its IR keyword, "
        f"got {type(spec)}"
    )


@dataclass(frozen=True)
class MmaOperation:
    """Describes an MMA operation type refined by the operand its pipeline stage
    buffers hold - described as ``KIND<OPERAND>`` in the pipeline type
    (``SM100_MMA_1SM_SS<A>``). Only an MMA kind can carry an operand, so an
    operand cannot be attached to a pipeline that has no MMA side. The
    operand is accepted as a :class:`MmaOperand`, its name or its IR keyword.
    """

    kind: OperationTypeEnum
    operand: MmaOperand

    def __post_init__(self) -> None:
        if not isinstance(self.kind, OperationTypeEnum):
            raise TypeError(
                f"MmaOperation kind must be an OperationTypeEnum, got {type(self.kind)}"
            )
        if not is_sm10x_mma_operation(self.kind):
            raise ValueError(
                f"MmaOperation requires an MMA operation type, got {self.kind}"
            )
        object.__setattr__(self, "operand", normalize_mma_operand(self.operand))

    def __str__(self) -> str:
        return f"{self.kind}<{self.operand.value}>"


# One endpoint of a pipeline side: a bare operation type, or an MMA
# refined by the operand it accesses in the stage buffers.
OperationDescriptor: TypeAlias = Union[OperationTypeEnum, MmaOperation]

# One descriptor, or an unordered non-empty set of them when several
# operation kinds share a stage.
OperationTypeSpec: TypeAlias = Union[OperationDescriptor, Sequence[OperationDescriptor]]


def _operation_descriptors(spec: OperationTypeSpec) -> list[OperationDescriptor]:
    """The descriptors of one pipeline side, checked against the constraints
    the pipeline type enforces: non-empty, no duplicates, and no kind both
    bare and refined."""
    if isinstance(spec, (OperationTypeEnum, MmaOperation)):
        items = [spec]
    elif isinstance(spec, Sequence) and not isinstance(spec, str):
        items = list(spec)
    else:
        raise TypeError(
            "operation type must be an OperationTypeEnum, an MmaOperation or a "
            f"sequence of them, got {type(spec)}"
        )
    if not items:
        raise ValueError("operation type set must be non-empty")
    for item in items:
        if not isinstance(item, (OperationTypeEnum, MmaOperation)):
            raise TypeError(
                "operation type must be an OperationTypeEnum or an MmaOperation, "
                f"got {type(item)}"
            )
    if len(set(items)) != len(items):
        texts = ", ".join(str(item) for item in items)
        raise ValueError(f"duplicate operation descriptor in [{texts}]")
    bare = {item for item in items if isinstance(item, OperationTypeEnum)}
    refined = {item.kind for item in items if isinstance(item, MmaOperation)}
    for kind in sorted(bare & refined, key=str):
        raise ValueError(
            f"{kind} appears both with and without an operand; name the operand "
            "on every occurrence or on none"
        )
    return items


def _operation_kind(descriptor: OperationDescriptor) -> OperationTypeEnum:
    """The operation kind of a descriptor, with any MMA operand dropped."""
    return descriptor.kind if isinstance(descriptor, MmaOperation) else descriptor


def _mma_operand_of(descriptor: OperationDescriptor) -> Optional[MmaOperand]:
    """The operand a descriptor refines its MMA with, if any."""
    return descriptor.operand if isinstance(descriptor, MmaOperation) else None


def _validate_descriptor_side(descriptor: OperationDescriptor, side: str) -> None:
    """An MMA reads A, B, C and Metadata from the stage buffers as a consumer
    and writes D into them as a producer; a refined descriptor on the other
    side can never be satisfied."""
    operand = _mma_operand_of(descriptor)
    if operand is None:
        return
    expected = "producer" if operand is MmaOperand.D else "consumer"
    if side != expected:
        role = "the MMA's output" if operand is MmaOperand.D else "read by the MMA"
        raise ValueError(
            f"{descriptor} is {role}, so it belongs on the {expected} side, "
            f"not the {side} side"
        )


class MbarrierOwner(Enum):
    """Named mbarrier owner accepted by :class:`PipelineLocale`."""

    ALL = "all"
    CTA_PAIR_LEADER = "cta_pair_leader"
    CTA_PAIR_PEER = "cta_pair_peer"


MbarrierOwnerSpec: TypeAlias = Union[MbarrierOwner, int]


def _format_mbarrier_owner(owner: MbarrierOwnerSpec) -> str:
    if isinstance(owner, MbarrierOwner):
        return owner.value
    if isinstance(owner, int):
        if owner < 0:
            raise ValueError(
                f"cluster-id mbarrier owner must be non-negative, got {owner}"
            )
        return str(owner)
    raise TypeError(
        "mbarrier owner must be a MbarrierOwner or non-negative cluster id, "
        f"got {type(owner)}"
    )


@dataclass(frozen=True)
class PipelineLocale:
    """Typed builder for a pipeline synchronization locale."""

    _scope: str
    _full: MbarrierOwnerSpec | None = None
    _empty: MbarrierOwnerSpec | None = None

    def __post_init__(self) -> None:
        if self._scope == "cta":
            if self._full is not None or self._empty is not None:
                raise ValueError("CTA pipeline locale does not take mbarrier owners")
            return

        if self._scope == "cluster":
            if self._full is None or self._empty is None:
                raise ValueError(
                    "cluster pipeline locale requires full and empty mbarrier owners"
                )
            _format_mbarrier_owner(self._full)
            _format_mbarrier_owner(self._empty)
            return

        raise ValueError(f"unknown pipeline locale scope '{self._scope}'")

    @staticmethod
    def cta() -> "PipelineLocale":
        return PipelineLocale("cta")

    @staticmethod
    def cluster(full: MbarrierOwnerSpec, empty: MbarrierOwnerSpec) -> "PipelineLocale":
        return PipelineLocale("cluster", full, empty)

    def _to_ir_text(self) -> str:
        if self._scope == "cta":
            return "cta"
        assert self._full is not None and self._empty is not None
        full_text = _format_mbarrier_owner(self._full)
        empty_text = _format_mbarrier_owner(self._empty)
        return f"cluster<{full_text}, {empty_text}>"


def _format_operation_types(spec: OperationTypeSpec, side: str) -> str:
    """Render one side of a pipeline type: a single descriptor or a bracketed
    set, each refined MMA spelled ``KIND<OPERAND>``."""
    descriptors = _operation_descriptors(spec)
    for descriptor in descriptors:
        _validate_descriptor_side(descriptor, side)
    texts = [str(descriptor) for descriptor in descriptors]
    if len(texts) == 1:
        return texts[0]
    return "[" + ", ".join(texts) + "]"


def _descriptor_attr(descriptor: OperationDescriptor) -> ir.Attribute:
    """A descriptor as the attribute the pipeline type stores for it."""
    if isinstance(descriptor, MmaOperation):
        return ir.Attribute.parse(
            f"#lir.mma_operation<{descriptor.kind}, {descriptor.operand.value}>"
        )
    return ir.Attribute.parse(f"#core.operation_type<value = {descriptor}>")


def _operation_type_array_attr(spec: OperationTypeSpec, side: str) -> ir.ArrayAttr:
    """Render one side's descriptors for the arrival-count query exactly as
    the pipeline type spells them, so the query names the pipeline's edges."""
    descriptors = _operation_descriptors(spec)
    for descriptor in descriptors:
        _validate_descriptor_side(descriptor, side)
    return ir.ArrayAttr.get([_descriptor_attr(d) for d in descriptors])


@dsl_user_op
def elect_sync(
    loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> ir.Value:
    return _nvvm.elect_sync(loc=loc, ip=ip)



@dsl_user_op
def get_mbarrier(
    stage_token: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Returns the mbarrier pointer for a given stage token.
    """
    return cutlass_lir_ir.GetMbarrierOp(stage_token, loc=loc, ip=ip)


@ir.register_value_caster(cutlass_lir_ir.PipelineStateType.get_static_typeid())
class PipelineState(ir.Value):
    def __init__(self, value: ir.Value) -> None:
        if isinstance(value, ir.Value):
            self.value = value
        else:
            raise TypeError(f"Expected ir.Value, got {type(value)}")
        super().__init__(value)

    @property
    @lru_cache_ir()
    def type(self) -> ir.Type:
        return self.value.type

    @classmethod
    def __new_from_mlir_values__(cls, values: list[ir.Value]) -> "PipelineState":
        assert len(values) == 1, f"Expected 1 value, but got {len(values)}"
        return PipelineState(values[0])


def _normalize_create_pipeline_arrival_mask(
    arrival_mask: Optional[cute.Int16],
    compat_kwargs: dict[str, object],
) -> Optional[cute.Int16]:
    # Legacy source compatibility: older callers used `multicast` as the sixth
    # argument. Keep `False` working, but force `True` callers onto the explicit
    # mask APIs because the legacy path produced incorrect IR.
    # Remove this shim once the team is comfortable breaking low-level
    # create_pipeline() callers and dropping the legacy multicast spelling.
    multicast = compat_kwargs.pop("multicast", None)
    if compat_kwargs:
        unexpected_arg = next(iter(compat_kwargs))
        raise TypeError(
            f"create_pipeline() got an unexpected keyword argument '{unexpected_arg}'"
        )

    if multicast is not None:
        if not isinstance(multicast, bool):
            raise TypeError(f"Expected `multicast` to be a bool, got {type(multicast)}")
        if arrival_mask is not None:
            raise ValueError(
                "create_pipeline() does not accept both `arrival_mask` and legacy `multicast`."
            )
        if multicast:
            raise ValueError(
                "create_pipeline(multicast=True) is no longer supported; "
                "use create_pipeline(..., arrival_mask=...) or "
                "create_pipeline_with_mask(...)."
            )
        return None

    if isinstance(arrival_mask, bool):
        if arrival_mask:
            raise ValueError(
                "create_pipeline(True) no longer supports the legacy multicast "
                "form; use create_pipeline(..., arrival_mask=...) or "
                "create_pipeline_with_mask(...)."
            )
        return None

    return arrival_mask


def _pipeline_type_str(
    stage: int,
    producer: OperationTypeSpec,
    consumer: OperationTypeSpec,
    locale: Optional[PipelineLocale] = None,
    producer_report_valid: bool = False,
) -> str:
    """The ``!lir.pipeline<...>`` type string, shared by pipeline creation and
    the arrival-count query so a query for a pipeline carries exactly the type
    ``create_pipeline`` builds. Every type-affecting input (the descriptors,
    the locale and any pipeline mode flags) must be threaded through here so
    both symbols agree."""
    if locale is not None and not isinstance(locale, PipelineLocale):
        raise TypeError(
            f"Expected `locale` to be a PipelineLocale or None, got {type(locale)}"
        )
    producer_str = _format_operation_types(producer, "producer")
    consumer_str = _format_operation_types(consumer, "consumer")
    pipeline_type_str = f"!lir.pipeline<{stage}, {producer_str} -> {consumer_str}"
    if locale is not None:
        pipeline_type_str += f", {locale._to_ir_text()}"
    if producer_report_valid:
        pipeline_type_str += ", producer_report_valid"
    return pipeline_type_str + ">"


def _build_pipeline(
    stage: int,
    producer: OperationTypeSpec,
    consumer: OperationTypeSpec,
    producer_arv_count: cute.Int32,
    consumer_arv_count: cute.Int32,
    arrival_mask: Optional[cute.Int16],
    locale: Optional[PipelineLocale],
    producer_report_valid: bool,
    loc: Optional[ir.Location],
    ip: Optional[ir.InsertionPoint],
) -> tuple[PipelineState, PipelineState, PipelineState]:
    if isinstance(producer_arv_count, int):
        producer_arv_count = cute.Int32(producer_arv_count)
    if isinstance(consumer_arv_count, int):
        consumer_arv_count = cute.Int32(consumer_arv_count)

    pipeline_type_str = _pipeline_type_str(
        stage,
        producer,
        consumer,
        locale,
        producer_report_valid,
    )

    if arrival_mask is not None:
        if isinstance(arrival_mask, int):
            arrival_mask = cute.Int16(arrival_mask)
        result = ir.Type.parse(pipeline_type_str)
        op = cutlass_lir_ir.CreatePipelineWithMaskOp(
            result,
            producer_arv_count.ir_value(),
            consumer_arv_count.ir_value(),
            arrival_mask.ir_value(),
            loc=loc,
            ip=ip,
        )
    else:
        result = ir.Type.parse(pipeline_type_str)
        op = cutlass_lir_ir.CreatePipelineOp(
            result,
            producer_arv_count.ir_value(),
            consumer_arv_count.ir_value(),
            loc=loc,
            ip=ip,
        )
    pipeline = op.result

    result = ir.Type.parse(f"!lir.pipeline_state<{stage}>")
    op = cutlass_lir_ir.CreatePipelineStateOp(result, pipeline, loc=loc, ip=ip)
    producer_state = op.result

    result = ir.Type.parse(f"!lir.pipeline_state<{stage}>")
    op = cutlass_lir_ir.CreatePipelineStateOp(result, pipeline, loc=loc, ip=ip)
    consumer_state = op.result

    return pipeline, producer_state, consumer_state


@dsl_user_op
def create_pipeline(
    stage: int,
    producer: OperationTypeSpec,
    consumer: OperationTypeSpec,
    producer_arv_count: cute.Int32,
    consumer_arv_count: cute.Int32,
    arrival_mask: Optional[cute.Int16] = None,
    *,
    locale: Optional[PipelineLocale] = None,
    producer_report_valid: bool = False,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
    **compat_kwargs: object,
) -> tuple[PipelineState, PipelineState, PipelineState]:
    """
    Creates an abstraction for a circular buffer of synchronization primitives
    indexed by stage count.

    Args:
        stage: Number of pipeline stages.
        producer: Producer operation type, or a non-empty sequence of them
            for a multi-producer pipeline (e.g. ``[store to smem, SM100_COPY_R2T]``).
        consumer: Consumer operation type, or a non-empty sequence of them
            for a multi-consumer pipeline. An MMA that reads the stage
            buffers may name the operand it reads,
            ``MmaOperation(kind, MmaOperand.A)`` (``SM100_MMA_1SM_SS<A>``) - enables optimized releases.
        producer_arv_count: Number of producer arrivals.
        consumer_arv_count: Number of consumer arrivals.
        arrival_mask: Optional arrival mask for multi-CTA synchronization
            (2SM or multicast). When provided, creates the pipeline with
            explicit mask-based barrier configuration.
        locale: Optional explicit pipeline synchronization locale. Use
            :class:`PipelineLocale` helpers instead of passing raw type grammar.
        producer_report_valid: Enable producer validity-check mode. This currently
            requires a TMA load producer.
    """
    arrival_mask = _normalize_create_pipeline_arrival_mask(arrival_mask, compat_kwargs)
    return _build_pipeline(
        stage,
        producer,
        consumer,
        producer_arv_count,
        consumer_arv_count,
        arrival_mask,
        locale,
        producer_report_valid,
        loc,
        ip,
    )


@dsl_user_op
def create_pipeline_with_mask(
    stage: int,
    producer: OperationTypeSpec,
    consumer: OperationTypeSpec,
    producer_arv_count: cute.Int32,
    consumer_arv_count: cute.Int32,
    arrival_mask: cute.Int16,
    *,
    locale: Optional[PipelineLocale] = None,
    producer_report_valid: bool = False,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> tuple[PipelineState, PipelineState, PipelineState]:
    """Backward-compatible wrapper. Prefer create_pipeline(..., arrival_mask=...)."""
    return _build_pipeline(
        stage,
        producer,
        consumer,
        producer_arv_count,
        consumer_arv_count,
        arrival_mask,
        locale,
        producer_report_valid,
        loc,
        ip,
    )



@dsl_user_op
def get_arrival_count(
    producer: OperationTypeSpec,
    consumer: OperationTypeSpec,
    *,
    side: str,
    # The `int` default is coerced to Int32 in the body (as elsewhere in this
    # file); the ignore is only for the literal-vs-Int32 default-value check.
    num_threads_per_cta: cute.Int32 = 1,  # type: ignore[assignment]
    op_subset: Optional[Sequence[OperationDescriptor]] = None,
    elect_one_sync: bool = False,
    elect_leader_cta: bool = False,
    fan_in: Optional[cute.Int32] = None,
    locale: Optional[PipelineLocale] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Int32:
    """
    Computes the mbarrier arrival-count contribution of one logical release
    for one side of a pipeline (see the ``lir.get_arrival_count`` op
    documentation for the full semantics). The result feeds
    ``create_pipeline`` as the producer or consumer arrival count, so
    clients no longer re-derive the count formula.

    The query names the pipeline only by the fields the count depends on: the
    producer/consumer operation types and the optional locale (both passed the
    same as to ``create_pipeline``). The stage count and any pipeline mode
    flags do not affect the count and are not query inputs. A refined
    ``MmaOperation`` is passed through as the pipeline type spells it; the
    operand does not change the count.

    Args:
        producer: Producer operation type(s) (as passed to ``create_pipeline``).
        consumer: Consumer operation type(s) (as passed to ``create_pipeline``).
        side: ``"producer"`` or ``"consumer"`` -- whose release is queried.
        num_threads_per_cta: Number of threads per CTA that issue the
            release op.
        op_subset: Subset of the side's operation types, for split
            producers/consumers where one release op covers part of the work.
            Absent covers the whole side.
        elect_one_sync: The release elects one thread per warp (mirrors the
            commit/release ops' flag); ``num_threads_per_cta`` must then be a
            multiple of the warp size.
        elect_leader_cta: Only the leader CTA of each CTA pair executes the
            release (mirrors the commit/release ops' flag).
        fan_in: Overrides the number of CTAs converging on the barrier where
            no value is derivable from the pipeline -- required for
            multicast-masked arrivals (pass the converging-issuer count, e.g.
            the structural multicast participant count).
        locale: Must match the value passed to ``create_pipeline`` for this
            pipeline. The locale changes the inferred signaling topology, so
            unlike a type-only pipeline mode flag it does affect the count;
            pass the same locale used to build the pipeline. When absent, the
            locale is inferred from the operation types, exactly as
            ``create_pipeline`` infers it.

    Returns the contribution of ONE logical arrival. Multiplicity belongs to
    the caller: invoke once per logical arrival that lands in one phase and
    sum the results.
    """
    if side not in ("producer", "consumer"):
        raise ValueError(f"side must be 'producer' or 'consumer', got {side!r}")
    if isinstance(num_threads_per_cta, int):
        num_threads_per_cta = cute.Int32(num_threads_per_cta)
    if isinstance(fan_in, int):
        fan_in = cute.Int32(fan_in)
    if locale is not None and not isinstance(locale, PipelineLocale):
        raise TypeError(
            f"Expected `locale` to be a PipelineLocale or None, got {type(locale)}"
        )

    producers_attr = _operation_type_array_attr(producer, "producer")
    consumers_attr = _operation_type_array_attr(consumer, "consumer")
    locale_attr = None
    if locale is not None:
        # The standalone locale attribute states per-edge signaling
        # topologies, while this API's PipelineLocale names barrier owners;
        # the owner-to-topology translation depends on the operation types
        # and lives in the pipeline TYPE parser. Route through it: parse the
        # exact pipeline type this query names (the stage count does not
        # affect the locale) and extract the stored locale. This also
        # guarantees the query's locale is the one ``create_pipeline`` would
        # build for the same arguments.
        pipeline_type = ir.Type.parse(_pipeline_type_str(1, producer, consumer, locale))
        locale_attr = cutlass_lir_ir.mbarrier_pipeline_get_locale(pipeline_type)
    side_attr = ir.Attribute.parse(f"#lir.pipeline_side<{side}>")
    subset_attr = None
    if op_subset is not None:
        subset_attr = ir.ArrayAttr.get(
            [_descriptor_attr(t) for t in _operation_descriptors(list(op_subset))]
        )

    op = cutlass_lir_ir.GetArrivalCountOp(
        producers_attr,
        consumers_attr,
        side_attr,
        num_threads_per_cta.ir_value(),
        locale=locale_attr,
        op_subset=subset_attr,
        elect_one_sync=elect_one_sync,
        elect_leader_cta=elect_leader_cta,
        fan_in=fan_in.ir_value() if fan_in is not None else None,
        loc=loc,
        ip=ip,
    )
    return cute.Int32(op.result)


@dsl_user_op
def pipeline_advance_iterator(
    pipe: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Advances a pipeline iterator to the next stage.
    """
    op = cutlass_lir_ir.PipelineAdvanceIteratorOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def create_pipeline_state_at(
    pipe: ir.Value,
    stage: int,
    stage_index: cute.Int32,
    phase: cute.Int32,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> PipelineState:
    """
    Materializes a pipeline state for an explicit stage index and phase.

    This is useful for retry agents that sweep stages out of iterator order.
    The operation only packages state; it does not synchronize.
    """
    if isinstance(stage_index, int):
        stage_index = cute.Int32(stage_index)
    if isinstance(phase, int):
        phase = cute.Int32(phase)

    result = ir.Type.parse(f"!lir.pipeline_state<{stage}>")
    op = cutlass_lir_ir.CreatePipelineStateAtOp(
        result,
        pipe,
        stage_index.ir_value(),
        phase.ir_value(),
        loc=loc,
        ip=ip,
    )
    return op.result


@dsl_user_op
def get_pipeline_produce_phase(
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Int32:
    """Return the producer phase carried by a pipeline state."""
    phase_type = ir.IntegerType.get_signless(32)
    op = cutlass_lir_ir.GetPipelineProducePhaseOp(
        pipelineState=state,
        results=[phase_type],
        loc=loc,
        ip=ip,
    )
    return cute.Int32(op.phase)


@dsl_user_op
def get_pipeline_consume_phase(
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Int32:
    """Return the consumer phase carried by a pipeline state."""
    phase_type = ir.IntegerType.get_signless(32)
    op = cutlass_lir_ir.GetPipelineConsumePhaseOp(
        pipelineState=state,
        results=[phase_type],
        loc=loc,
        ip=ip,
    )
    return cute.Int32(op.phase)


@dsl_user_op
def producer_acquire(
    pipe: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Acquires exclusive access to a pipeline.
    """
    op = cutlass_lir_ir.ProducerAcquireOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def producer_commit(
    pipe: ir.Value,
    state: ir.Value,
    *,
    elect_one_sync: Optional[bool] = None,
    elect_leader_cta: Optional[bool] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Commits results to a pipeline.
    """
    op = cutlass_lir_ir.ProducerCommitOp(
        pipe,
        state,
        elect_one_sync=elect_one_sync,
        elect_leader_cta=elect_leader_cta,
        loc=loc,
        ip=ip,
    )
    return op.result


@dsl_user_op
def consumer_wait(
    pipe: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Waits for a pipeline to transition to `full`.
    """
    op = cutlass_lir_ir.ConsumerWaitOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def consumer_release(
    pipe: ir.Value,
    state: ir.Value,
    *,
    elect_one_sync: Optional[bool] = None,
    elect_leader_cta: Optional[bool] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Releases a pipeline that has been consumed.
    """
    op = cutlass_lir_ir.ConsumerReleaseOp(
        pipe,
        state,
        elect_one_sync=elect_one_sync,
        elect_leader_cta=elect_leader_cta,
        loc=loc,
        ip=ip,
    )
    return op.result


@dsl_user_op
def consumer_release_elect_one_sync(
    pipe: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Releases a pipeline that has been consumed.
    """
    op = cutlass_lir_ir.ConsumerReleaseOp(
        pipe, state, elect_one_sync=True, loc=loc, ip=ip
    )
    return op.result


@dsl_user_op
def consumer_test_valid(
    pipe: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> tuple[Boolean, Boolean]:
    """
    Non-blockingly probes whether a consumer stage is ready and data-valid.

    For a normal pipeline this probes full-barrier readiness and returns
    ``(ready, true)``; there is no validity-report channel. For a
    ``producer_report_valid`` pipeline, ``valid`` reflects the v1 mbarrier report
    bit.
    """
    bool_ty = ir.IntegerType.get_signless(1)
    op = cutlass_lir_ir.ConsumerTestValidOp(
        pipe, state, results=[bool_ty, bool_ty], loc=loc, ip=ip
    )
    return Boolean(op.ready, loc=loc, ip=ip), Boolean(op.valid, loc=loc, ip=ip)


@dsl_user_op
def pipeline_tail(
    pipe: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Drains outstanding asynchronous pipeline work associated with the state.
    """
    op = cutlass_lir_ir.PipelineTailOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def consumer_tail(
    pipe: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Legacy alias for `pipeline_tail()`.
    """
    op = cutlass_lir_ir.PipelineTailOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def get_pipeline_produce_stage(
    pipeline: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> tuple[ir.Value, ir.Value]:
    """
    Gets a pipeline produce stage.
    """
    stage_token_type = ir.Type.parse(f"!lir.stage_token<{pipeline.type}>")
    stage_idx = ir.IntegerType.get_signless(32)
    op = cutlass_lir_ir.GetPipelineProduceStageOp(
        stage_token=stage_token_type,
        stage_index=stage_idx,
        pipeline=pipeline,
        pipelineState=state,
        loc=loc,
        ip=ip,
    )
    return op.stage_token, op.stage_index


@dsl_user_op
def get_pipeline_consume_stage(
    pipeline: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> tuple[ir.Value, ir.Value]:
    """
    Creates a pipeline consume stage.
    """
    stage_token_type = ir.Type.parse(f"!lir.stage_token<{pipeline.type}>")
    stage_idx = ir.IntegerType.get_signless(32)
    op = cutlass_lir_ir.GetPipelineConsumeStageOp(
        stage_token=stage_token_type,
        stage_index=stage_idx,
        pipeline=pipeline,
        pipelineState=state,
        loc=loc,
        ip=ip,
    )
    return op.stage_token, op.stage_index


@ir.register_value_caster(
    cutlass_lir_ir.CircularBufferPipelineStateType.get_static_typeid()
)
class CircularBufferPipelineState(ir.Value):
    def __init__(self, value: ir.Value) -> None:
        if isinstance(value, ir.Value):
            self.value = value
        else:
            raise TypeError(f"Expected ir.Value, got {type(value)}")
        super().__init__(value)

    @property
    @lru_cache_ir()
    def type(self) -> ir.Type:
        return self.value.type

    @classmethod
    def __new_from_mlir_values__(
        cls, values: list[ir.Value]
    ) -> "CircularBufferPipelineState":
        assert len(values) == 1, f"Expected 1 value, but got {len(values)}"
        return CircularBufferPipelineState(values[0])


@dsl_user_op
def create_circular_buffer_pipeline(
    pipeline: ir.Value,
    pipeline_state: PipelineState,
    stages: int,
    count_per_stage: int,
    count_per_iteration: int,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> CircularBufferPipelineState:
    """
    Creates a circular buffer abstraction layered on top of a lir.pipeline.

    Each pipeline stage is subdivided into `count_per_stage` units.
    Operations can advance the circular buffer position by `count_per_iteration` units
    at a time in a FIFO manner. The abstraction provides synchronized access to
    pipeline stages given the circular buffer position.

    Args:
        pipeline: The underlying pipeline object
        pipeline_state: Initial pipeline state
        stages: Number of pipeline stages
        count_per_stage: Number of units per pipeline stage
        count_per_iteration: Number of units per iteration (chunk size)
        loc: Source location
        ip: Insertion point

    Returns:
        CircularBufferPipelineState: The circular buffer pipeline state
    """
    result_type = ir.Type.parse(
        f"!lir.circular_buffer_pipeline_state<{stages}, {count_per_stage}, {count_per_iteration}>"
    )
    op = cutlass_lir_ir.CreateCircularBufferPipelineOp(
        result_type,
        pipeline,
        pipeline_state,
        loc=loc,
        ip=ip,
    )
    return op.result


@dsl_user_op
def circular_buffer_pipeline_consume(
    pipeline: ir.Value,
    circular_buffer_pipeline_state: CircularBufferPipelineState,
    *,
    elect_leader_cta: Optional[bool] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Synchronize pipeline stages needed for circular buffer consumption.

    Args:
        pipeline: The underlying pipeline object
        circular_buffer_pipeline_state: Current circular buffer pipeline state
        elect_leader_cta: When set, only the leader CTA performs the wait
        loc: Source location
        ip: Insertion point
    """
    cutlass_lir_ir.CircularBufferPipelineConsumeOp(
        pipeline,
        circular_buffer_pipeline_state,
        elect_leader_cta=elect_leader_cta,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def circular_buffer_pipeline_consumer_release(
    pipeline: ir.Value,
    circular_buffer_pipeline_state: CircularBufferPipelineState,
    *,
    elect_one_sync: Optional[bool] = None,
    elect_leader_cta: Optional[bool] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Release pipeline stages after circular buffer consumption.

    Args:
        pipeline: The underlying pipeline object
        circular_buffer_pipeline_state: Current circular buffer pipeline state
        elect_one_sync: When set, only a single thread performs the release
        elect_leader_cta: When set, only the leader CTA performs the release
        loc: Source location
        ip: Insertion point
    """
    cutlass_lir_ir.CircularBufferPipelineConsumerReleaseOp(
        pipeline,
        circular_buffer_pipeline_state,
        elect_one_sync=elect_one_sync,
        elect_leader_cta=elect_leader_cta,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def circular_buffer_pipeline_advance_iterator(
    pipeline: ir.Value,
    circular_buffer_pipeline_state: CircularBufferPipelineState,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> CircularBufferPipelineState:
    """
    Advance the circular buffer position.

    This operation advances the circular buffer position by `count_per_iteration`
    units.

    Args:
        pipeline: The underlying pipeline
        circular_buffer_pipeline_state: Current circular buffer pipeline state
        loc: Source location
        ip: Insertion point

    Returns:
        CircularBufferPipelineState: Updated circular buffer pipeline state with advanced offset
    """
    op = cutlass_lir_ir.CircularBufferPipelineAdvanceIteratorOp(
        pipeline,
        circular_buffer_pipeline_state,
        loc=loc,
        ip=ip,
    )
    return op.result


@dsl_user_op
def mbarrier_expect_tx(
    mbarPtr: ir.Value,
    txBytes: cute.Int32,
    ctaId: Optional[ir.Value] = None,
    elect_one_sync: bool = False,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Called by the consumer to block until asynchronous tasks have completed. Supports optional broadcast.
    """
    if isinstance(txBytes, int):
        txBytes = cute.Int32(txBytes)
    if ctaId != None:
        ctaId = ctaId.value
    _op = cutlass_lir_ir.MBarrierExpectTxOp(
        mbarPtr.value,
        txBytes.ir_value(),
        ctaId=ctaId,
        elect_one_sync=elect_one_sync,
        loc=loc,
        ip=ip,
    )
    return


def normalize_skip_wait_token(
    token: Optional[SkipWaitToken],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Optional[ir.Value]:
    """
    Normalizes a skip wait token to an ir.Value.
    """
    if token is None:
        return None
    if isinstance(token, bool):
        return Boolean(token).ir_value(loc=loc, ip=ip)
    if isinstance(token, ir.Value):
        return token
    if hasattr(token, "ir_value"):
        return token.ir_value(loc=loc, ip=ip)
    raise TypeError(f"skipWait token must lower to ir.Value, got {type(token)}")


@dsl_user_op
def producer_try_acquire(
    pipe: ir.Value,
    state: ir.Value,
    *,
    token: Optional[SkipWaitToken] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Boolean:
    """
    Tries to acquire a producer stage, non-blocking.
    """
    skip_wait = normalize_skip_wait_token(token, loc=loc, ip=ip)
    token_value = cutlass_lir_ir.ProducerTryAcquireOp(
        pipe, state, skipWait=skip_wait, loc=loc, ip=ip
    ).token
    return Boolean(token_value, loc=loc, ip=ip)


@dsl_user_op
def consumer_try_wait(
    pipe: ir.Value,
    state: ir.Value,
    *,
    token: Optional[SkipWaitToken] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Boolean:
    """
    Tries to wait for a consumer stage, non-blocking.
    """
    skip_wait = normalize_skip_wait_token(token, loc=loc, ip=ip)
    token_value = cutlass_lir_ir.ConsumerTryWaitOp(
        pipe, state, skipWait=skip_wait, loc=loc, ip=ip
    ).token
    return Boolean(token_value, loc=loc, ip=ip)
