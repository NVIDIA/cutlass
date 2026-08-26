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
from cutlass import base_dsl
from cutlass.cutlass_dsl import (
    BaseDSL,
    T,
    if_generate,
    while_generate,
    dsl_user_op,
    yield_out,
)
from typing import Literal, overload

from cutlass._mlir import ir
from cutlass._mlir.dialects import nvvm as _nvvm, llvm
from cutlass._mlir.ir import AttrBuilder
from ..typing import Optional, Pointer, Int, Boolean, Int32, AddressSpace


def _mbarrier_primary_result_type(has_report: bool) -> ir.Type:
    fields = [T.bool(), T.bool()]
    if has_report:
        fields.append(T.i32())
    return llvm.StructType.get_literal(fields)


@overload
def _extract_mbarrier_primary_result(
    result: ir.Value,
    has_report: Literal[False],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> tuple[Boolean, Boolean]: ...


@overload
def _extract_mbarrier_primary_result(
    result: ir.Value,
    has_report: Literal[True],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> tuple[Boolean, Boolean, Int32]: ...


@overload
def _extract_mbarrier_primary_result(
    result: ir.Value,
    has_report: bool,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> tuple[Boolean, Boolean] | tuple[Boolean, Boolean, Int32]: ...


def _extract_mbarrier_primary_result(
    result: ir.Value,
    has_report: bool,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> tuple[Boolean, Boolean] | tuple[Boolean, Boolean, Int32]:
    wait_complete = Boolean(llvm.extractvalue(T.bool(), result, [0], loc=loc, ip=ip))
    report_seen = Boolean(llvm.extractvalue(T.bool(), result, [1], loc=loc, ip=ip))

    if has_report:
        report = Int32(llvm.extractvalue(T.i32(), result, [2], loc=loc, ip=ip))
        return wait_complete, report_seen, report
    return wait_complete, report_seen


####################################################################################################
#
# Mbarrier management utilities
#
####################################################################################################


@dsl_user_op
def mbarrier_init(
    mbar_ptr: Pointer,
    cnt: Int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Initializes a mbarrier with the specified thread arrival count.

    **Single-Thread Execution Required**: This operation **must** be executed by only one thread
    per CTA. Use :func:`cute.arch.elect_one` to ensure proper synchronization:

    .. code-block:: python

        with cute.arch.elect_one():
            cute.arch.mbarrier_init(barrier_ptr, arrival_count)

    **PTX Mapping**: This operation maps to the PTX
    ``mbarrier.init.shared::cta.b64`` form,
    which must be issued by a single thread for correctness.

    :param mbar_ptr: A pointer to the mbarrier in SMEM
    :type mbar_ptr:  Pointer
    :param cnt:      The arrival count of the mbarrier
    :type cnt:       Int

    .. seealso::
       - :func:`cute.arch.elect_one` - Required wrapper for single-thread execution
       - :func:`cute.arch.mbarrier_expect_tx` - Also requires elect_one
       - PTX ISA documentation on ``mbarrier.init``
    """

    _nvvm.mbarrier_init(
        mbar_ptr.to_llvm_ptr(loc=loc, ip=ip),
        Int32(cnt).ir_value(loc=loc, ip=ip),
        loc=loc,
        ip=ip,
    )



@dsl_user_op
def mbarrier_init_fence(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> None:
    """
    A fence operation that applies to the mbarrier initializations.
    """
    BaseDSL._get_dsl().check_arch(lambda arch: arch >= base_dsl.Arch.sm_90)

    _nvvm.fence_mbarrier_init(loc=loc, ip=ip)


@dsl_user_op
def mbarrier_arrive_and_expect_tx(
    mbar_ptr: Pointer,
    bytes: Int,
    peer_cta_rank_in_cluster: Optional[Int] = None,
    relaxed: bool = False,
    scope: _nvvm.MemScopeKind = _nvvm.MemScopeKind.CTA,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Arrives on a mbarrier and expects a specified number of transaction bytes.

    Each thread that executes this operation increases the mbarrier tx-count by
    the specified byte count and then performs an arrive-on operation, which
    decrements the pending arrival count by 1.

    To ensure proper synchronization, most calls to this function should be wrapped in :func:`cute.arch.elect_one`.

    .. code-block:: python

        with cute.arch.elect_one():
            cute.arch.mbarrier_arrive_and_expect_tx(barrier_ptr, num_transaction_bytes)

    This is a combined operation that both declares transaction bytes and arrives at
    the barrier. It is commonly used with TMA operations in pipelined
    kernels.

    See the PTX ISA documentation on `mbarrier.arrive.expect_tx <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-mbarrier-arrive-expect-tx>`__.

    :param mbar_ptr:                 A pointer to the mbarrier in SMEM
    :type mbar_ptr:                  Pointer
    :param bytes:                    The number of transaction bytes
    :type bytes:                     Int
    :param peer_cta_rank_in_cluster: An optional CTA rank in cluster. If provided, the pointer to
                                     the mbarrier is converted to a remote address in the peer CTA's
                                     SMEM.
    :param relaxed:                  If True, the arrive operation has relaxed semantics and does not provide
                                     any ordering or visibility guarantees.
    :param scope:                    Scope of threads participating in the arrive/wait operations.

    .. seealso::
       - :func:`cute.arch.elect_one` - Required wrapper for single-thread execution
       - :func:`cute.arch.mbarrier_init` - Also requires elect_one
       - :func:`cute.arch.mbarrier_expect_tx` - Expect_tx without arrive
    """
    BaseDSL._get_dsl().check_arch(lambda arch: arch >= base_dsl.Arch.sm_90)

    mbar_llvm_ptr = mbar_ptr.to_llvm_ptr(loc=loc, ip=ip)
    if peer_cta_rank_in_cluster is not None:
        mbar_cluster_type = llvm.PointerType.get(AddressSpace.dsmem)
        mbar_llvm_ptr = _nvvm.mapa(
            mbar_cluster_type,
            mbar_llvm_ptr,
            Int32(peer_cta_rank_in_cluster).ir_value(loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )

    _nvvm.mbarrier_arrive_expect_tx(
        mbar_llvm_ptr,
        Int32(bytes).ir_value(loc=loc, ip=ip),
        scope=scope,
        relaxed=relaxed,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def mbarrier_expect_tx(
    mbar_ptr: Pointer,
    bytes: Int,
    peer_cta_rank_in_cluster: Optional[Int] = None,
    *,
    scope: Optional[_nvvm.MemScopeKind] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Expects a specified number of transaction bytes without an arrive.

    Each thread that executes this operation increases the mbarrier tx-count by
    the specified byte count.

    To ensure proper synchronization, most calls to this function should be wrapped in :func:`cute.arch.elect_one`.

    .. code-block:: python

        with cute.arch.elect_one():
            cute.arch.mbarrier_expect_tx(barrier_ptr, num_transaction_bytes)

    This is commonly used with TMA operations to set the expected transaction size before
    issuing a TMA load.

    See the PTX ISA documentation on `mbarrier.expect_tx <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-mbarrier-expect-tx>`__.

    :param mbar_ptr:                 A pointer to the mbarrier in SMEM
    :type mbar_ptr:                  Pointer
    :param bytes:                    The number of transaction bytes
    :type bytes:                     Int
    :param peer_cta_rank_in_cluster: An optional CTA rank in cluster. If provided, the pointer to
                                     the mbarrier is converted to a remote address in the peer CTA's
                                     SMEM.
    :param scope:                    Scope of threads participating in the mbarrier operation.
                                     Defaults to CTA for local barriers and CLUSTER for remote CTA targets.

    .. seealso::
       - :func:`cute.arch.elect_one` - Recommended wrapper for single-thread execution
       - :func:`cute.arch.mbarrier_init` - initialize mbarrier
       - :func:`cute.arch.mbarrier_arrive_and_expect_tx` - Combined arrive and expect_tx
    """
    BaseDSL._get_dsl().check_arch(lambda arch: arch >= base_dsl.Arch.sm_90)

    mbar_llvm_ptr = mbar_ptr.to_llvm_ptr(loc=loc, ip=ip)
    if scope is None:
        scope = (
            _nvvm.MemScopeKind.CLUSTER
            if peer_cta_rank_in_cluster is not None
            else _nvvm.MemScopeKind.CTA
        )
    if peer_cta_rank_in_cluster is not None:
        mbar_cluster_type = llvm.PointerType.get(AddressSpace.dsmem)
        mbar_llvm_ptr = _nvvm.mapa(
            mbar_cluster_type,
            mbar_llvm_ptr,
            Int32(peer_cta_rank_in_cluster).ir_value(loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )

    _nvvm.mbarrier_expect_tx(
        mbar_llvm_ptr,
        Int32(bytes).ir_value(loc=loc, ip=ip),
        scope=scope,
        loc=loc,
        ip=ip,
    )



@dsl_user_op
def mbarrier_wait(
    mbar_ptr: Pointer,
    phase: Int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Waits on a mbarrier with a specified phase.

    :param mbar_ptr: A pointer to the mbarrier in SMEM
    :type mbar_ptr:  Pointer
    :param phase:    The phase to wait for (either 0 or 1)
    :type phase:     Int
    """
    BaseDSL._get_dsl().check_arch(lambda arch: arch >= base_dsl.Arch.sm_90)

    timeout_ns = 10_000_000

    # Using intrinsics is recommended by NVVM compiler for production; the prep
    # pass expands this to an explicit retry loop over nvvm.mbarrier.try_wait.
    _nvvm.mbarrier_try_wait_parity(
        mbar_ptr.to_llvm_ptr(loc=loc, ip=ip),
        Int32(phase).ir_value(loc=loc, ip=ip),
        Int32(timeout_ns).ir_value(loc=loc, ip=ip),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def mbarrier_try_wait(
    mbar_ptr: Pointer,
    phase: Int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Boolean:
    """
    Attempts to wait on a mbarrier with a specified phase. This uses PTX
    ``mbarrier.try_wait``, which may suspend the executing thread if the phase
    is incomplete.

    :param mbar_ptr: A pointer to the mbarrier in SMEM
    :type mbar_ptr:  Pointer
    :param phase:    The phase to wait for (either 0 or 1)
    :type phase:     Int
    :return:         A boolean value indicating whether the wait operation was successful
    :rtype:          Boolean
    """
    BaseDSL._get_dsl().check_arch(lambda arch: arch >= base_dsl.Arch.sm_90)

    return Boolean(
        _nvvm.mbarrier_wait_parity(
            mbar_ptr.to_llvm_ptr(loc=loc, ip=ip),
            Int32(phase).ir_value(loc=loc, ip=ip),
            _nvvm.MBarrierWaitKind.TRY,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def mbarrier_test_wait(
    mbar_ptr: Pointer,
    phase: Int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Boolean:
    """
    Tests if a mbarrier with a specified phase is complete.

    :param mbar_ptr: A pointer to the mbarrier in SMEM
    :type mbar_ptr:  Pointer
    :param phase:    The phase to wait for (either 0 or 1)
    :type phase:     Int
    :return:         A boolean value indicating whether the wait operation was successful
    :rtype:          Boolean
    """
    BaseDSL._get_dsl().check_arch(lambda arch: arch >= base_dsl.Arch.sm_90)

    return Boolean(
        _nvvm.mbarrier_wait_parity(
            mbar_ptr.to_llvm_ptr(loc=loc, ip=ip),
            Int32(phase).ir_value(loc=loc, ip=ip),
            _nvvm.MBarrierWaitKind.TEST,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def mbarrier_conditional_try_wait(
    cond: Boolean,
    mbar_ptr: Pointer,
    phase: Int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Boolean:
    """
    Conditionally attempts to wait on a mbarrier with a specified phase using
    PTX ``mbarrier.try_wait`` semantics.

    :param cond:     A boolean predicate
    :param mbar_ptr: A pointer to the mbarrier in SMEM
    :type mbar_ptr:  Pointer
    :param phase:    The phase to wait for (either 0 or 1)
    :type phase:     Int
    :return:         A boolean value indicating whether the wait operation was successful
    :rtype:          Boolean
    """
    BaseDSL._get_dsl().check_arch(lambda arch: arch >= base_dsl.Arch.sm_90)
    return if_generate(  # type: ignore[return-value]
        cond,
        lambda: mbarrier_try_wait(mbar_ptr, phase, loc=loc, ip=ip),
        lambda: Boolean(True).ir_value(loc=loc, ip=ip),
        None,
        [Boolean],
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def mbarrier_arrive(
    mbar_ptr: Pointer,
    peer_cta_rank_in_cluster: Optional[Int] = None,
    arrive_count: Int = 1,
    *,
    relaxed: bool = False,
    scope: Optional[_nvvm.MemScopeKind] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Arrives on an mbarrier.

    :param mbar_ptr:                 A pointer to the mbarrier in SMEM
    :type mbar_ptr:                  Pointer
    :param peer_cta_rank_in_cluster: An optional CTA rank in cluster. If provided, the pointer to
                                     the mbarrier is converted to a remote address in the peer CTA's
                                     SMEM.
    :param scope:                    Scope of threads participating in the mbarrier operation.
                                     Defaults to CTA, including for remote CTA targets.
    """
    mbar_llvm_ptr = mbar_ptr.to_llvm_ptr(loc=loc, ip=ip)
    if scope is None:
        # Remote CTA arrivals should be cluster-scoped for formal cross-CTA
        # memory-model ordering. Keep the historical CTA default because
        # existing retry-sync protocols rely only on the barrier count and
        # current hardware/compiler behavior, and cluster scope is measurably
        # slower there. Pass scope=CLUSTER for DSMEM data handoff protocols.
        scope = _nvvm.MemScopeKind.CTA
    if peer_cta_rank_in_cluster is not None:
        BaseDSL._get_dsl().check_arch(lambda arch: arch >= base_dsl.Arch.sm_90)

        mbar_cluster_type = llvm.PointerType.get(AddressSpace.dsmem)
        mbar_llvm_ptr = _nvvm.mapa(
            mbar_cluster_type,
            mbar_llvm_ptr,
            Int32(peer_cta_rank_in_cluster).ir_value(loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )

    _nvvm.mbarrier_arrive(
        mbar_llvm_ptr,
        count=Int32(arrive_count).ir_value(loc=loc, ip=ip),
        scope=scope,
        relaxed=relaxed,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cp_async_mbarrier_arrive_noinc(
    mbar_ptr: Pointer,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Arrives on an mbarrier for async load **without incrementing** the arrival count
    (``cp.async.mbarrier.arrive.noinc.shared::cta.b64``).
    Used in the warp-specialized kernel when the non-TMA load warp(producer) is not the same
    as the math/epilogue warp(consumer).

    :param mbar_ptr: A pointer to the mbarrier in SMEM
    :type mbar_ptr:  Pointer
    """
    BaseDSL._get_dsl().check_arch(lambda arch: arch >= base_dsl.Arch.sm_90)

    mbar_llvm_ptr = mbar_ptr.to_llvm_ptr(loc=loc, ip=ip)
    _nvvm.cp_async_mbarrier_arrive(mbar_llvm_ptr, noinc=True, loc=loc, ip=ip)
