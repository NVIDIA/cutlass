# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from functools import partial
from typing import Optional, Tuple, Union, Callable, TYPE_CHECKING
from typing_extensions import deprecated

from cutlass.cutlass_dsl import T, dsl_user_op, cutlass_arith

import cutlass.cutlass_dsl as cutlass_dsl

from cutlass._mlir import ir
from cutlass._mlir.dialects import arith, llvm, nvvm, vector

if TYPE_CHECKING:
    from cutlass.tensor import TensorSSA

# Forward nvvm enums
from cutlass._mlir.dialects.nvvm import (
    ProxyKind,
    SharedSpace,
    Tcgen05WaitKind,
    SetMaxRegisterAction,
    RoundingModeKind,
)

from ..core import size

from ..typing import (
    Int,
    Boolean,
    Int8,
    Int16,
    Uint16,
    Int32,
    Uint32,
    Int64,
    Float16,
    Float32,
    BFloat16,
    Numeric,
    as_numeric,
)

WARP_SIZE = 32
FULL_MASK = 0xFFFFFFFF


@dsl_user_op
def lane_idx(*, loc=None, ip=None) -> Int32:
    """
    Returns the lane index of the current thread within the warp.
    """
    return Int32(nvvm.read_ptx_sreg_laneid(T.i32(), loc=loc, ip=ip))


@dsl_user_op
def warp_idx(*, loc=None, ip=None) -> Int32:
    """
    Returns the warp index within a CTA.
    """
    warp_size = 32
    tid_x = Int32(nvvm.read_ptx_sreg_tid_x(T.i32(), loc=loc, ip=ip))
    tid_y = Int32(nvvm.read_ptx_sreg_tid_y(T.i32(), loc=loc, ip=ip))
    tid_z = Int32(nvvm.read_ptx_sreg_tid_z(T.i32(), loc=loc, ip=ip))
    ntid_x = Int32(nvvm.read_ptx_sreg_ntid_x(T.i32(), loc=loc, ip=ip))
    ntid_y = Int32(nvvm.read_ptx_sreg_ntid_y(T.i32(), loc=loc, ip=ip))
    tid = tid_x + tid_y * ntid_x + tid_z * ntid_x * ntid_y
    return tid // warp_size


@dsl_user_op
def thread_idx(*, loc=None, ip=None) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the thread index within a CTA.
    """
    return (
        Int32(nvvm.read_ptx_sreg_tid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_tid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_tid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def block_dim(*, loc=None, ip=None) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the number of threads in each dimension of the CTA.
    """
    return (
        Int32(nvvm.read_ptx_sreg_ntid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_ntid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_ntid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def block_idx(*, loc=None, ip=None) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the CTA identifier within a grid.
    """
    return (
        Int32(nvvm.read_ptx_sreg_ctaid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_ctaid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_ctaid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def grid_dim(*, loc=None, ip=None) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the number of CTAs in each dimension of the grid.
    """
    return (
        Int32(nvvm.read_ptx_sreg_nctaid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_nctaid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_nctaid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def cluster_idx(*, loc=None, ip=None) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the cluster identifier within a grid.
    """
    return (
        Int32(nvvm.read_ptx_sreg_clusterid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_clusterid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_clusterid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def cluster_dim(*, loc=None, ip=None) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the number of clusters in each dimension of the grid.
    """
    return (
        Int32(nvvm.read_ptx_sreg_nclusterid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_nclusterid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_nclusterid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def block_in_cluster_idx(*, loc=None, ip=None) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the CTA index within a cluster across all dimensions.
    """
    return (
        Int32(nvvm.read_ptx_sreg_cluster_ctaid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_cluster_ctaid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_cluster_ctaid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def block_in_cluster_dim(*, loc=None, ip=None) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the dimensions of the cluster.
    """
    return (
        Int32(nvvm.read_ptx_sreg_cluster_nctaid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_cluster_nctaid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_cluster_nctaid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def cluster_size(*, loc=None, ip=None) -> Int32:
    """
    Returns the number of CTA within the cluster.
    """
    return Int32(nvvm.read_ptx_sreg_cluster_nctarank(T.i32(), loc=loc, ip=ip))


@dsl_user_op
def block_idx_in_cluster(*, loc=None, ip=None) -> Int32:
    """
    Returns the linearized identifier of the CTA within the cluster.
    """
    return Int32(nvvm.read_ptx_sreg_cluster_ctarank(T.i32(), loc=loc, ip=ip))


@dsl_user_op
def shuffle_sync_op(
    value: Union[Numeric, "TensorSSA"],
    offset: Int,
    mask: Int = FULL_MASK,
    mask_and_clamp: Int = WARP_SIZE - 1,
    kind: nvvm.ShflKind = nvvm.ShflKind.idx,
    *,
    loc=None,
    ip=None,
) -> Union[Numeric, "TensorSSA"]:
    """
    Shuffles a value within the threads of a warp.

    :param value:          The value to shuffle
    :type value:           Numeric or TensorSSA
    :param mask:           A mask describing the threads participating in this operation
    :type mask:            Int
    :param offset:         A source lane or a source lane offset depending on kind
    :type offset:          Int
    :param mask_and_clamp: An integer containing two packed values specifying a mask for logically
                           splitting warps into sub-segments and an upper bound for clamping the
                           source lane index.
    :type mask_and_clamp:  Int
    :param kind:           The kind of shuffle, can be idx, up, down, or bfly
    :type kind:            ShflKind
    :return:               The shuffled value
    :rtype:                Numeric
    """
    from ..tensor import TensorSSA

    if isinstance(value, TensorSSA):
        bit_width = value.dtype.width * size(value.shape)
        if bit_width == 32:
            i32_val = llvm.bitcast(
                T.i32(), value.ir_value(loc=loc, ip=ip), loc=loc, ip=ip
            )
            i32_res = nvvm.shfl_sync(
                T.i32(),
                Int32(mask).ir_value(loc=loc, ip=ip),
                i32_val,
                Int32(offset).ir_value(loc=loc, ip=ip),
                Int32(mask_and_clamp).ir_value(loc=loc, ip=ip),
                kind,
                loc=loc,
                ip=ip,
            )
            result_vec = llvm.bitcast(value.type, i32_res, loc=loc, ip=ip)
            return TensorSSA(result_vec, value.shape, value.dtype)
        else:
            raise ValueError(f"shuffle_sync only supports 32 bit, but got {value.type}")

    if not isinstance(value, Numeric):
        value = as_numeric(value)

    if value.width > 64:
        raise ValueError("shuffle_sync only supports values up to 64 bits")

    orig_type = type(value)

    if value.width < 32:
        if value.dtype.is_float:
            value = value.to(Float32)
        else:
            if value.signed:
                value = value.to(Int32)
            else:
                value = value.to(Uint32)
        return orig_type(
            nvvm.shfl_sync(
                type(value).mlir_type,
                Int32(mask).ir_value(loc=loc, ip=ip),
                value.ir_value(loc=loc, ip=ip),
                Int32(offset).ir_value(loc=loc, ip=ip),
                Int32(mask_and_clamp).ir_value(loc=loc, ip=ip),
                kind,
                loc=loc,
                ip=ip,
            )
        )
    elif value.width == 32:
        return orig_type(
            nvvm.shfl_sync(
                type(value).mlir_type,
                Int32(mask).ir_value(loc=loc, ip=ip),
                value.ir_value(loc=loc, ip=ip),
                Int32(offset).ir_value(loc=loc, ip=ip),
                Int32(mask_and_clamp).ir_value(loc=loc, ip=ip),
                kind,
                loc=loc,
                ip=ip,
            )
        )
    else:
        if value.width != 64:
            raise ValueError(
                "shuffle_sync only supports 64 bits values when the bit width is larger than 32"
            )
        value = llvm.bitcast(
            T.i64(), value.to(ir.Value, loc=loc, ip=ip), loc=loc, ip=ip
        )
        # extract low 32 bits
        low_32_bits = llvm.trunc(
            T.i32(), value, llvm.IntegerOverflowFlags.none, loc=loc, ip=ip
        )
        # extract high 32 bits
        high_32_bits = llvm.lshr(
            value, Int64(32).ir_value(loc=loc, ip=ip), loc=loc, ip=ip
        )
        high_32_bits = llvm.trunc(
            T.i32(), high_32_bits, llvm.IntegerOverflowFlags.none, loc=loc, ip=ip
        )

        low_32_bits_shfl = nvvm.shfl_sync(
            T.i32(),
            Int32(mask).ir_value(loc=loc, ip=ip),
            low_32_bits,
            Int32(offset).ir_value(loc=loc, ip=ip),
            Int32(mask_and_clamp).ir_value(loc=loc, ip=ip),
            kind,
            loc=loc,
            ip=ip,
        )
        high_32_bits_shfl = nvvm.shfl_sync(
            T.i32(),
            Int32(mask).ir_value(loc=loc, ip=ip),
            high_32_bits,
            Int32(offset).ir_value(loc=loc, ip=ip),
            Int32(mask_and_clamp).ir_value(loc=loc, ip=ip),
            kind,
            loc=loc,
            ip=ip,
        )

        # combine low and high 32 bits
        low_64_bit = llvm.zext(T.i64(), low_32_bits_shfl, loc=loc, ip=ip)
        high_64_bit = llvm.zext(T.i64(), high_32_bits_shfl, loc=loc, ip=ip)
        shlf_res = llvm.shl(
            high_64_bit,
            Int64(32).ir_value(loc=loc, ip=ip),
            llvm.IntegerOverflowFlags.none,
            loc=loc,
            ip=ip,
        )
        shlf_res = llvm.or_(shlf_res, low_64_bit, loc=loc, ip=ip)
        shlf_res = llvm.bitcast(orig_type.mlir_type, shlf_res, loc=loc, ip=ip)
        return orig_type(shlf_res)


shuffle_sync = partial(shuffle_sync_op, kind=nvvm.ShflKind.idx)
shuffle_sync_up = partial(shuffle_sync_op, kind=nvvm.ShflKind.up)
shuffle_sync_down = partial(shuffle_sync_op, kind=nvvm.ShflKind.down)
shuffle_sync_bfly = partial(shuffle_sync_op, kind=nvvm.ShflKind.bfly)


@dsl_user_op
def warp_reduction(
    val: Numeric, op: Callable, *, threads_in_group: int = 32, loc=None, ip=None
) -> Numeric:
    """warp reduction of a Numeric value(e.g.Float32) by shuffle_sync_bfly, accepts custom binary operator.
    The threads_in_group is the number of threads reduction group in a warp.
    E.g. 32 means the whole warp reduced in one group. 8 means the warp is divided into 4 thread groups, each group has 8 threads in reduction.


    :param val: register value
    :type val: cutlass.Numeric
    :param op: binary operator
    :type op: Callable
    :param threads_in_group: the number of threads reduction group in a warp
    :type threads_in_group: int
    :return: reduced value
    :rtype: cutlass.Numeric
    """
    offset = threads_in_group // 2

    while offset > 0:
        val = op(
            val,
            shuffle_sync_bfly(
                val, offset=offset, mask=-1, mask_and_clamp=31, loc=loc, ip=ip
            ),
        )
        offset = offset // 2
    return val


warp_reduction_max = partial(
    warp_reduction,
    op=lambda x, y: fmax(x, y) if isinstance(x, Float32) else cutlass_dsl.max(x, y),
)
warp_reduction_sum = partial(warp_reduction, op=lambda x, y: x + y)


@dsl_user_op
def barrier(*, barrier_id=None, number_of_threads=None, loc=None, ip=None) -> None:
    """
    Creates a barrier, optionally named.
    """
    if barrier_id is not None:
        barrier_id = Int32(barrier_id).ir_value(loc=loc, ip=ip)

    if number_of_threads is not None:
        number_of_threads = Int32(number_of_threads).ir_value(loc=loc, ip=ip)

    nvvm.barrier(
        barrier_id=barrier_id, number_of_threads=number_of_threads, loc=loc, ip=ip
    )


@dsl_user_op
def barrier_arrive(
    *, barrier_id=None, number_of_threads=None, loc=None, ip=None
) -> None:
    if barrier_id is not None:
        barrier_id = Int32(barrier_id).ir_value(loc=loc, ip=ip)

    if number_of_threads is None:
        raise ValueError(
            "barrier_arrive needs pass number_of_threads to arrive the barrier",
        )
    number_of_threads = Int32(number_of_threads).ir_value(loc=loc, ip=ip)

    nvvm.barrier_arrive(
        barrier_id=barrier_id, number_of_threads=number_of_threads, loc=loc, ip=ip
    )


@dsl_user_op
def sync_threads(*, loc=None, ip=None) -> None:
    """
    Synchronizes all threads within a CTA.
    """
    nvvm.barrier(loc=loc, ip=ip)


@dsl_user_op
def sync_warp(mask: Int = FULL_MASK, *, loc=None, ip=None) -> None:
    """
    Performs a warp-wide sync with an optional mask.
    """
    nvvm.bar_warp_sync(Int32(mask).ir_value(loc=loc, ip=ip), loc=loc, ip=ip)


@dsl_user_op
def fence_acq_rel_cta(*, loc=None, ip=None) -> None:
    """
    Fence operation with acquire-release semantics.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-membar>`__.
    """
    nvvm.fence_acq_rel_cta(loc=loc, ip=ip)


@dsl_user_op
def fence_acq_rel_cluster(*, loc=None, ip=None) -> None:
    """
    Fence operation with acquire-release semantics.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-membar>`__.
    """
    nvvm.fence_acq_rel_cluster(loc=loc, ip=ip)


@dsl_user_op
def fence_acq_rel_gpu(*, loc=None, ip=None) -> None:
    """
    Fence operation with acquire-release semantics.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-membar>`__.
    """
    nvvm.fence_acq_rel_gpu(loc=loc, ip=ip)


@dsl_user_op
def fence_acq_rel_sys(*, loc=None, ip=None) -> None:
    """
    Fence operation with acquire-release semantics.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-membar>`__.
    """
    nvvm.fence_acq_rel_sys(loc=loc, ip=ip)


@dsl_user_op
def cp_async_commit_group(*, loc=None, ip=None) -> None:
    """
    Commits all prior initiated but uncommitted cp.async instructions.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-commit-group>`__.
    """
    nvvm.cp_async_commit_group(loc=loc, ip=ip)


@dsl_user_op
def cp_async_wait_group(n, *, loc=None, ip=None) -> None:
    """
    Waits till only a specified numbers of cp.async groups are pending.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-wait-group-cp-async-wait-all>`__.
    """
    nvvm.cp_async_wait_group(n, loc=loc, ip=ip)


@dsl_user_op
def cp_async_bulk_commit_group(*, loc=None, ip=None) -> None:
    """
    Commits all prior initiated but uncommitted cp.async.bulk instructions.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk-commit-group>`__.
    """
    nvvm.cp_async_bulk_commit_group(loc=loc, ip=ip)


@dsl_user_op
def cp_async_bulk_wait_group(group, *, read=None, loc=None, ip=None) -> None:
    """
    Waits till only a specified numbers of cp.async.bulk groups are pending.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk-wait-group>`__.
    """
    nvvm.cp_async_bulk_wait_group(group, read=read, loc=loc, ip=ip)


@dsl_user_op
def cluster_wait(*, loc=None, ip=None) -> None:
    """
    A cluster-wide wait operation.
    """
    nvvm.cluster_wait(loc=loc, ip=ip)


@dsl_user_op
def cluster_arrive(*, aligned=None, loc=None, ip=None) -> None:
    """
    A cluster-wide arrive operation.
    """
    nvvm.cluster_arrive(aligned=aligned, loc=loc, ip=ip)


@dsl_user_op
def cluster_arrive_relaxed(*, aligned=None, loc=None, ip=None) -> None:
    """
    A cluster-wide arrive operation with relaxed semantics.
    """
    nvvm.cluster_arrive_relaxed(aligned=aligned, loc=loc, ip=ip)


@dsl_user_op
def fence_proxy(
    kind: ProxyKind,
    *,
    space: Optional[SharedSpace] = None,
    use_intrinsic=None,
    loc=None,
    ip=None,
) -> None:
    nvvm.fence_proxy(
        kind=kind, space=space, use_intrinsic=use_intrinsic, loc=loc, ip=ip
    )


@dsl_user_op
def vote_ballot_sync(
    pred: Boolean, mask: Int = FULL_MASK, *, loc=None, ip=None
) -> Int32:
    """Performs a ballot operation across the warp.

    It copies the predicate from each thread in mask into the corresponding bit position of
    destination register d, where the bit position corresponds to the thread's lane id.

    :param pred: The predicate value for the current thread
    :type pred: Boolean
    :param mask: A 32-bit integer mask specifying which threads participate, defaults to all threads (0xFFFFFFFF)
    :type mask: Int, optional
    :return: A 32-bit integer where each bit represents a thread's predicate value
    :rtype: Int32

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-vote-sync>`__.
    """
    return Int32(
        nvvm.vote_ballot_sync(
            T.i32(),
            Int32(mask).ir_value(loc=loc, ip=ip),
            Boolean(pred).ir_value(loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def vote_sync_op(
    pred: Boolean, kind: str, mask: Int = FULL_MASK, *, loc=None, ip=None
) -> Union[Int32, Boolean]:
    return_type = Boolean
    return_type_str = "pred"
    return return_type(
        llvm.inline_asm(
            T.bool(),
            [
                Boolean(pred).ir_value(loc=loc, ip=ip),
                Int32(mask).ir_value(loc=loc, ip=ip),
            ],
            f"""{{\n\t
            .reg .pred ps;\n\t
            .reg .pred pd;\n\t
            setp.ne.b32 ps, $1, 0;\n\t
            vote.sync.{kind}.{return_type_str} pd, ps, $2;\n\t
            selp.b32 $0, 1, 0, pd;\n\t
            }}""",
            "=r,r,i",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def vote_any_sync(
    pred: Boolean, mask: Int = FULL_MASK, *, loc=None, ip=None
) -> Boolean:
    """True if source predicate is True for any non-exited threads in mask. Negate the source
    predicate to compute .not_all.

    :param pred: The predicate value for the current thread
    :type pred: Boolean
    :param mask: A 32-bit integer mask specifying which threads participate, defaults to all
                threads (0xFFFFFFFF)
    :type mask: Int, optional
    :return: A boolean value indicating if the source predicate is True for all non-exited
            threads in mask
    :rtype: Boolean

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-vote-sync>`__.
    """
    return vote_sync_op(pred, "any", mask, loc=loc, ip=ip)


@dsl_user_op
def vote_all_sync(
    pred: Boolean, mask: Int = FULL_MASK, *, loc=None, ip=None
) -> Boolean:
    """True if source predicate is True for all non-exited threads in mask. Negate the source
    predicate to compute .none.

    :param pred: The predicate value for the current thread
    :type pred: Boolean
    :param mask: A 32-bit integer mask specifying which threads participate, defaults to all
                threads (0xFFFFFFFF)
    :type mask: Int, optional
    :return: A boolean value indicating if the source predicate is True for all non-exited
            threads in mask
    :rtype: Boolean

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-vote-sync>`__.
    """
    return vote_sync_op(pred, "all", mask, loc=loc, ip=ip)


@dsl_user_op
def vote_uni_sync(
    pred: Boolean, mask: Int = FULL_MASK, *, loc=None, ip=None
) -> Boolean:
    """True f source predicate has the same value in all non-exited threads in mask. Negating
    the source predicate also computes .uni

    :param pred: The predicate value for the current thread
    :type pred: Boolean
    :param mask: A 32-bit integer mask specifying which threads participate, defaults to all
                threads (0xFFFFFFFF)
    :type mask: Int, optional
    :return: A boolean value indicating if the source predicate is True for all non-exited
            threads in mask
    :rtype: Boolean
    """
    return vote_sync_op(pred, "uni", mask, loc=loc, ip=ip)


@dsl_user_op
def popc(value: Numeric, *, loc=None, ip=None) -> Numeric:
    """
    Performs a population count operation.
    """
    if not isinstance(value, Numeric):
        value = as_numeric(value)
    return type(value)(llvm.intr_ctpop(value.ir_value(loc=loc, ip=ip), loc=loc, ip=ip))


@dsl_user_op
def fence_view_async_tmem_op(
    kind: Tcgen05WaitKind,
    *,
    loc=None,
    ip=None,
) -> None:
    """
    Perform a fence operation on the async TMEM load or store.

    .. note::
        This function is only available on sm_100a and above.
        The fence is required to synchronize the TMEM load/store
        and let the pipeline release or commit the buffer.

        Take a mma2acc pipeline as an example of LOAD fence, the ACC tensor is from TMEM.
        ```
        # Start to copy ACC from TMEM to register
        cute.copy(tmem_load, tACC, rACC)
        fence_view_async_tmem_load()
        # After fence, we can ensure the TMEM buffer is consumed totally.
        # Release the buffer to let the MMA know it can overwrite the buffer.
        mma2accum_pipeline.consumer_release(curr_consumer_state)
        ```
        Take a TS GEMM kernel as an example of STORE fence, the A tensor is from TMEM.
        ```
        # Start to copy A from register to TMEM
        cute.copy(tmem_store, rA, tA)
        fence_view_async_tmem_store()
        # After fence, we can ensure the TMEM buffer is ready.
        # Commit the buffer to let the MMA know it can start to load A.
        tmem_mma_pipeline.producer_commit(curr_producer_state)
        ```


    :param kind: The kind of fence operation to perform including LOAD and STORE.
    :type kind: Tcgen05WaitKind
    """
    nvvm.tcgen05_wait(kind, loc=loc, ip=ip)


fence_view_async_tmem_load = partial(
    fence_view_async_tmem_op, kind=Tcgen05WaitKind.LOAD
)
fence_view_async_tmem_store = partial(
    fence_view_async_tmem_op, kind=Tcgen05WaitKind.STORE
)


@dsl_user_op
def fence_view_async_shared(
    *,
    loc=None,
    ip=None,
) -> None:
    """
    Perform a fence operation on the async shared memory load or store.

    .. note::
        This function is only available on sm_90 or higher.
        The fence is required to synchronize the shared memory load/store
        and let the pipeline release or commit the buffer.

        This function is usually used for async execution unit (like TMA, UMMA) after the load/store operations.
    """
    nvvm.fence_proxy(
        nvvm.ProxyKind.async_shared, space=nvvm.SharedSpace.shared_cta, loc=loc, ip=ip
    )


@dsl_user_op
def warpgroup_reg_realloc_op(
    reg_count: int,
    kind: SetMaxRegisterAction,
    *,
    loc=None,
    ip=None,
) -> None:
    nvvm.setmaxregister(reg_count, kind, loc=loc, ip=ip)


warpgroup_reg_alloc = partial(
    warpgroup_reg_realloc_op, kind=SetMaxRegisterAction.increase
)
warpgroup_reg_dealloc = partial(
    warpgroup_reg_realloc_op, kind=SetMaxRegisterAction.decrease
)


@dsl_user_op
def calc_packed_f32x2_op(
    src_a: Tuple[Float32, Float32],
    src_b: Tuple[Float32, Float32],
    src_c: Optional[Tuple[Float32, Float32]],
    calc_func: Callable,
    *,
    rnd=RoundingModeKind.RZ,
    ftz=True,
    loc=None,
    ip=None,
) -> Tuple[Float32, Float32]:
    vec_type = ir.VectorType.get([2], Float32.mlir_type, loc=loc)
    vec_src_a = vector.from_elements(
        vec_type,
        tuple(as_numeric(a).ir_value(loc=loc, ip=ip) for a in src_a),
        loc=loc,
        ip=ip,
    )
    vec_src_b = vector.from_elements(
        vec_type,
        tuple(as_numeric(b).ir_value(loc=loc, ip=ip) for b in src_b),
        loc=loc,
        ip=ip,
    )
    if src_c is not None:
        vec_src_c = vector.from_elements(
            vec_type,
            tuple(as_numeric(c).ir_value(loc=loc, ip=ip) for c in src_c),
            loc=loc,
            ip=ip,
        )
        vec_res = calc_func(
            vec_type, vec_src_a, vec_src_b, vec_src_c, rnd=rnd, ftz=ftz, loc=loc, ip=ip
        )
    else:
        vec_res = calc_func(
            vec_type, vec_src_a, vec_src_b, rnd=rnd, ftz=ftz, loc=loc, ip=ip
        )

    res0 = Float32(
        vector.extract(
            vec_res, dynamic_position=[], static_position=[0], loc=loc, ip=ip
        )
    )
    res1 = Float32(
        vector.extract(
            vec_res, dynamic_position=[], static_position=[1], loc=loc, ip=ip
        )
    )
    return res0, res1


fma_packed_f32x2 = partial(calc_packed_f32x2_op, calc_func=nvvm.fma_packed_f32x2)
mul_packed_f32x2 = partial(
    calc_packed_f32x2_op, src_c=None, calc_func=nvvm.mul_packed_f32x2
)
add_packed_f32x2 = partial(
    calc_packed_f32x2_op, src_c=None, calc_func=nvvm.add_packed_f32x2
)

@dsl_user_op
def fmax(
    a: Union[float, Float32], b: Union[float, Float32], *, loc=None, ip=None
) -> Float32:

    return Float32(
        nvvm.fmax(
            T.f32(),
            Float32(a).ir_value(loc=loc, ip=ip),
            Float32(b).ir_value(loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )
    )

@dsl_user_op
def rcp_approx(a: Union[float, Float32], *, loc=None, ip=None):
    return Float32(
        nvvm.rcp_approx_ftz_f(
            T.f32(), Float32(a).ir_value(loc=loc, ip=ip), loc=loc, ip=ip
        )
    )


@dsl_user_op
@deprecated(
    "cute.arch.exp2 is deprecated, use cute.math.exp2 with `fastmath=True` instead"
)
def exp2(a: Union[float, Float32], *, loc=None, ip=None) -> Float32:
    return Float32(
        llvm.inline_asm(
            T.f32(),
            [Float32(a).ir_value(loc=loc, ip=ip)],
            "ex2.approx.ftz.f32 $0, $1;",
            "=f,f",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )
    )


# Convert 1 int8 value to 1 bfloat16 value
@dsl_user_op
def cvt_i8_bf16(src_i8, *, loc=None, ip=None):
    src_i16 = llvm.zext(Int16.mlir_type, src_i8, loc=loc, ip=ip)
    val_i16 = llvm.inline_asm(
        Uint16.mlir_type,
        [
            src_i16,
        ],
        """{\n\t
            .reg .b16 r;\n\t
            .reg .b8 s;\n\t
            mov.b16 {s,_}, $1;\n\t
            cvt.rn.bf16.s8 r, s;\n\t
            mov.b16 $0, r;\n\t
        }""",
        "=h,h",
    )
    val_bf16 = llvm.bitcast(BFloat16.mlir_type, val_i16, loc=loc, ip=ip)
    return val_bf16


# Convert vector of 2 float values to vector of 2 bfloat16 values with satfinite rounding
@dsl_user_op
def cvt_f32x2_bf16x2(src_vec2, *, loc=None, ip=None):
    src0 = vector.extractelement(
        src_vec2, position=arith.constant(Int32.mlir_type, 0, loc=loc, ip=ip)
    )
    src1 = vector.extractelement(
        src_vec2, position=arith.constant(Int32.mlir_type, 1, loc=loc, ip=ip)
    )
    rst = llvm.inline_asm(
        T.i32(),
        [
            Float32(src1).ir_value(loc=loc, ip=ip),
            Float32(src0).ir_value(loc=loc, ip=ip),
        ],
        "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;",
        "=r,f,f",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    vec_type = ir.VectorType.get([2], BFloat16.mlir_type, loc=loc)
    vec_bf16x2 = llvm.bitcast(vec_type, rst, loc=loc, ip=ip)
    return vec_bf16x2


# Convert 1 float32 value to 1 bfloat16 value
@dsl_user_op
def cvt_f32_bf16(src_f32, *, loc=None, ip=None):
    bf16_val = llvm.inline_asm(
        BFloat16.mlir_type,
        [
            src_f32,
        ],
        "cvt.rn.bf16.f32 $0, $1;",
        "=h,f",
    )
    return bf16_val


# Convert vector of 4 int8 values to vector of 4 float32 values
@dsl_user_op
def cvt_i8x4_to_f32x4(src_vec4, *, loc=None, ip=None):
    zero = arith.constant(Int32.mlir_type, 0, loc=loc, ip=ip)
    mask4 = (
        arith.constant(Int32.mlir_type, 0x00000001, loc=loc, ip=ip),
        arith.constant(Int32.mlir_type, 0x00000100, loc=loc, ip=ip),
        arith.constant(Int32.mlir_type, 0x00010000, loc=loc, ip=ip),
        arith.constant(Int32.mlir_type, 0x01000000, loc=loc, ip=ip),
    )
    src_i32 = llvm.bitcast(Int32.mlir_type, src_vec4, loc=loc, ip=ip)
    rst0 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32,
            mask4[0],
            zero,
        ],
        "dp4a.s32.s32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    rst1 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32,
            mask4[1],
            zero,
        ],
        "dp4a.s32.s32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    rst2 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32,
            mask4[2],
            zero,
        ],
        "dp4a.s32.s32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    rst3 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32,
            mask4[3],
            zero,
        ],
        "dp4a.s32.s32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    res0 = llvm.inline_asm(
        Float32.mlir_type,
        [
            rst0,
        ],
        "cvt.rn.f32.s32 $0, $1;",
        "=f,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    res1 = llvm.inline_asm(
        Float32.mlir_type,
        [
            rst1,
        ],
        "cvt.rn.f32.s32 $0, $1;",
        "=f,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    res2 = llvm.inline_asm(
        Float32.mlir_type,
        [
            rst2,
        ],
        "cvt.rn.f32.s32 $0, $1;",
        "=f,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    res3 = llvm.inline_asm(
        Float32.mlir_type,
        [
            rst3,
        ],
        "cvt.rn.f32.s32 $0, $1;",
        "=f,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    vec_f32x4_type = ir.VectorType.get([4], Float32.mlir_type, loc=loc)
    vec_f32x4 = vector.from_elements(
        vec_f32x4_type, [res0, res1, res2, res3], loc=loc, ip=ip
    )
    return vec_f32x4


# Convert vector of 2 int8 values to vector of 2 float32 values
@dsl_user_op
def cvt_i8x2_to_f32x2(src_vec2, *, loc=None, ip=None):
    zero = arith.constant(Int32.mlir_type, 0, loc=loc, ip=ip)
    mask2 = (
        arith.constant(Int32.mlir_type, 0x00000001, loc=loc, ip=ip),
        arith.constant(Int32.mlir_type, 0x00000100, loc=loc, ip=ip),
    )
    src_i16 = llvm.bitcast(Int16.mlir_type, src_vec2, loc=loc, ip=ip)
    src_i32_pad16b = llvm.zext(Int32.mlir_type, src_i16, loc=loc, ip=ip)
    rst0 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32_pad16b,
            mask2[0],
            zero,
        ],
        "dp4a.s32.s32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    rst1 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32_pad16b,
            mask2[1],
            zero,
        ],
        "dp4a.s32.s32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    res0 = llvm.inline_asm(
        Float32.mlir_type,
        [
            rst0,
        ],
        "cvt.rn.f32.s32 $0, $1;",
        "=f,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    res1 = llvm.inline_asm(
        Float32.mlir_type,
        [
            rst1,
        ],
        "cvt.rn.f32.s32 $0, $1;",
        "=f,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    vec_f32x2_type = ir.VectorType.get([2], Float32.mlir_type, loc=loc)
    vec_f32x2 = vector.from_elements(vec_f32x2_type, [res0, res1], loc=loc, ip=ip)
    return vec_f32x2


# Permute bytes from register pair.
@dsl_user_op
def prmt(src, src_reg_shifted, prmt_indices, *, loc=None, ip=None):
    return llvm.inline_asm(
        T.i32(),
        [
            Int32(src).ir_value(loc=loc, ip=ip),
            Int32(src_reg_shifted).ir_value(loc=loc, ip=ip),
            Int32(prmt_indices).ir_value(loc=loc, ip=ip),
        ],
        "prmt.b32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )


# Convert 1 int4 value to 1 bfloat16 value
@dsl_user_op
def cvt_i4_bf16(src_i4, *, loc=None, ip=None):
    # i4 -> i32 -> f32 -> bf
    src_i32 = llvm.zext(Int32.mlir_type, src_i4, loc=loc, ip=ip)
    src_f32 = llvm.sitofp(Float32.mlir_type, src_i32, loc=loc, ip=ip)
    bf16_val = cvt_f32_bf16(src_f32, loc=loc, ip=ip)
    return bf16_val


# Convert multiple int4 values to bfloat16 values.
# The number of elements to be converted must be be even as specified by num_elts.
# Int4 values are packed into int32 values with upper bits filled with 0 if there are less than 4 int4 values.
# Results bfloat16 values are also packed into int32 values.
@dsl_user_op
def cvt_i4_to_bf16_impl(src_i32, num_elts, *, loc=None, ip=None):
    c4 = arith.constant(Int32.mlir_type, 4, loc=loc, ip=ip)
    src_shr4 = llvm.lshr(src_i32, c4, loc=loc, ip=ip)
    xor_mask0 = arith.constant(Int32.mlir_type, 0x08080808, loc=loc, ip=ip)
    and_mask = arith.constant(Int32.mlir_type, 0x0F0F0F0F, loc=loc, ip=ip)
    imm_lut = arith.constant(Int32.mlir_type, 0x0000006A, loc=loc, ip=ip)
    src_i32 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32,
            and_mask,
            xor_mask0,
            imm_lut,
        ],
        "lop3.b32 $0, $1, $2, $3, $4;",
        "=r,r,n,n,n",
    )
    xor_mask1 = arith.constant(Int32.mlir_type, 0x88080808, loc=loc, ip=ip)
    src_shr4 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_shr4,
            and_mask,
            xor_mask1,
            imm_lut,
        ],
        "lop3.b32 $0, $1, $2, $3, $4;",
        "=r,r,n,n,n",
    )
    prmt_indices = [
        arith.constant(Int32.mlir_type, imme, loc=loc, ip=ip)
        for imme in [
            0x0000F4F0,
            0x0000F5F1,
            0x0000F6F2,
            0x0000F7F3,
        ]
    ]
    num_i32_elts = num_elts // 2
    rsts = []
    for i in range(num_i32_elts):
        rst = llvm.inline_asm(
            Int32.mlir_type,
            [
                src_i32,
                src_shr4,
                prmt_indices[i],
            ],
            "prmt.b32 $0, $1, $2, $3;",
            "=r,r,r,r",
        )
        rsts.append(rst)
    mask_clear_top_bit = arith.constant(Int32.mlir_type, 0xFF7FFFFF, loc=loc, ip=ip)
    rsts[-1] = llvm.inline_asm(
        Int32.mlir_type,
        [
            rsts[-1],
            mask_clear_top_bit,
        ],
        "and.b32 $0, $1, $2;",
        "=r,r,r",
    )
    mul = arith.constant(Int32.mlir_type, 0x83808380, loc=loc, ip=ip)
    bias = arith.constant(Int32.mlir_type, 0xC308C308, loc=loc, ip=ip)
    for i in range(num_i32_elts):
        rsts[i] = llvm.inline_asm(
            Int32.mlir_type,
            [
                rsts[i],
                mul,
                bias,
            ],
            "fma.rn.bf16x2 $0, $1, $2, $3;",
            "=r,r,r,r",
        )
    # pack rsts into a vector
    vec_type = ir.VectorType.get([num_i32_elts], Int32.mlir_type, loc=loc)
    vec_rsts = vector.from_elements(vec_type, rsts, loc=loc, ip=ip)
    return vec_rsts


# Convert 2 int4 values to 2 bfloat16 values
@dsl_user_op
def cvt_i4x2_to_bf16x2(src_vec2, *, loc=None, ip=None):
    # pack 2 int4 into 1 int32 value and fill upper bits with 0
    src_i8 = llvm.bitcast(Int8.mlir_type, src_vec2, loc=loc, ip=ip)
    src_i32 = llvm.zext(Int32.mlir_type, src_i8, loc=loc, ip=ip)
    rst_i32 = cvt_i4_to_bf16_impl(src_i32, 2, loc=loc, ip=ip)
    vec_bf16x2_type = ir.VectorType.get([2], BFloat16.mlir_type, loc=loc)
    vec_bf16x2 = llvm.bitcast(vec_bf16x2_type, rst_i32, loc=loc, ip=ip)
    return vec_bf16x2


# Convert 4 int4 values to 4 bfloat16 values
@dsl_user_op
def cvt_i4x4_to_bf16x4(src_vec4, *, loc=None, ip=None):
    # pack 4 int4 into 1 int32 value and fill upper bits with 0
    src_i16 = llvm.bitcast(Int16.mlir_type, src_vec4, loc=loc, ip=ip)
    src_i32 = llvm.zext(Int32.mlir_type, src_i16, loc=loc, ip=ip)
    rst_i32 = cvt_i4_to_bf16_impl(src_i32, 4, loc=loc, ip=ip)
    vec_bf16x4_type = ir.VectorType.get([4], BFloat16.mlir_type, loc=loc)
    vec_bf16x4 = llvm.bitcast(vec_bf16x4_type, rst_i32, loc=loc, ip=ip)
    return vec_bf16x4


# Convert 8 int4 values to 8 bfloat16 values
@dsl_user_op
def cvt_i4x8_to_bf16x8(src_vec8, *, loc=None, ip=None):
    # pack 8 int4 into 1 int32 value and fill upper bits with 0
    src_i32 = llvm.bitcast(Int32.mlir_type, src_vec8, loc=loc, ip=ip)
    rst_i32 = cvt_i4_to_bf16_impl(src_i32, 8, loc=loc, ip=ip)
    vec_bf16x8_type = ir.VectorType.get([8], BFloat16.mlir_type, loc=loc)
    vec_bf16x8 = llvm.bitcast(vec_bf16x8_type, rst_i32, loc=loc, ip=ip)
    return vec_bf16x8


@dsl_user_op
def log2_of_pow2_int(a: Int32, *, loc=None, ip=None) -> Int32:
    tmp = llvm.inline_asm(
        Int32.mlir_type,
        [a.ir_value(loc=loc, ip=ip)],
        "brev.b32 $0, $1;",
        "=r,r",
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    return Int32(
        llvm.inline_asm(
            Int32.mlir_type,
            [tmp],
            "bfind.shiftamt.u32 $0, $1;",
            "=r,r",
            has_side_effects=False,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )
    )


@dsl_user_op
@deprecated(
    "cute.arch.exp is deprecated, use cute.math.exp with `fastmath=True` instead"
)
def exp(a: Union[float, Float32], *, loc=None, ip=None) -> Float32:
    LOG2_E = 1.4426950408889634
    return exp2(a * LOG2_E, loc=loc, ip=ip)


@dsl_user_op
@deprecated(
    "cute.arch.exp_packed_f32x2 is deprecated, use cute.arch.mul_packed_f32x2 and cute.math.exp2 with `fastmath=True` instead"
)
def exp_packed_f32x2(
    a: Tuple[Float32, Float32], *, loc=None, ip=None
) -> Tuple[Float32, Float32]:
    LOG2_E = Float32(1.4426950408889634)
    b = mul_packed_f32x2(a, (LOG2_E, LOG2_E), loc=loc, ip=ip)
    return exp2(b[0], loc=loc, ip=ip), exp2(b[1], loc=loc, ip=ip)


@dsl_user_op
def griddepcontrol_wait(*, loc=None, ip=None) -> None:
    """
    This instruction is used to wait for the previous kernel's grid ending
    (all blocks of the previous kernel have finished and memflushed), i.e.,
    the instruction after this instruction will not be issued until the previous
    grid has finished.
    """
    llvm.inline_asm(
        res=None,
        operands_=[],
        asm_string="griddepcontrol.wait;",
        constraints="",
        has_side_effects=True,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def griddepcontrol_launch_dependents(*, loc=None, ip=None) -> None:
    """
    Issuing the launch_dependents instruction hints a dependent kernel to launch earlier.
    launch_dependents doesn't impact the functionality but the performance:
    Launching a dependent kernel too early can compete with current kernels,
    while launching too late can lead to a long latency.
    """
    llvm.inline_asm(
        res=None,
        operands_=[],
        asm_string="griddepcontrol.launch_dependents;",
        constraints="",
        has_side_effects=True,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )



@dsl_user_op
def cvt_f4e2m1_f16(src, *, loc=None, ip=None):
    # 0 padding for upper 4 bits
    zero = arith.constant(src.type, 0, loc=loc, ip=ip)
    vec2 = vector.from_elements(
        ir.VectorType.get([2], src.type, loc=loc), [src, zero], loc=loc, ip=ip
    )
    rst_vec2 = cvt_f4e2m1x2_to_f16x2(vec2, loc=loc, ip=ip)
    # only the 1st element is valid
    rst = vector.extract(
        rst_vec2, dynamic_position=[], static_position=[0], loc=loc, ip=ip
    )
    return rst


# Convert 2 float4e2m1 values to 2 float16 values
@dsl_user_op
def cvt_f4e2m1x2_to_f16x2(src_vec2, *, loc=None, ip=None):
    # pack 2 float4e2m1 into 1 int8 value and fill upper bits with 0
    src_i8 = llvm.bitcast(Int8.mlir_type, src_vec2, loc=loc, ip=ip)
    src_i16 = llvm.zext(Int16.mlir_type, src_i8, loc=loc, ip=ip)
    rst_i32 = llvm.inline_asm(
        Int32.mlir_type,
        [src_i16],
        """{\n\t
            .reg .b8 b;\n\t
            mov.b16 {b,_}, $1;\n\t
            cvt.rn.f16x2.e2m1x2 $0, b;\n\t
        }""",
        "=r,h",
    )
    vec_f16x2_type = ir.VectorType.get([2], Float16.mlir_type, loc=loc)
    vec_f16x2 = llvm.bitcast(vec_f16x2_type, rst_i32, loc=loc, ip=ip)
    return vec_f16x2


# Convert 4 float4e2m1 values to 4 float16 values
@dsl_user_op
def cvt_f4e2m1x4_to_f16x4(src_vec4, *, loc=None, ip=None):
    # pack 4 float4e2m1 into 1 int16 value
    src_i16 = llvm.bitcast(Int16.mlir_type, src_vec4, loc=loc, ip=ip)
    rst_i32x2 = llvm.inline_asm(
        llvm.StructType.get_literal([T.i32(), T.i32()]),
        [src_i16],
        """{\n\t
            .reg .b8 b0, b1;\n\t
            mov.b16 {b0, b1}, $2;\n\t
            cvt.rn.f16x2.e2m1x2 $0, b0;\n\t
            cvt.rn.f16x2.e2m1x2 $1, b1;\n\t
        }""",
        "=r,=r,h",
    )
    res0 = llvm.extractvalue(T.i32(), rst_i32x2, [0])
    res1 = llvm.extractvalue(T.i32(), rst_i32x2, [1])
    vec_f32x2_type = ir.VectorType.get([2], Int32.mlir_type, loc=loc)
    vec_f32x2 = vector.from_elements(vec_f32x2_type, [res0, res1], loc=loc, ip=ip)
    vec_f16x4_type = ir.VectorType.get([4], Float16.mlir_type, loc=loc)
    vec_f16x4 = llvm.bitcast(vec_f16x4_type, vec_f32x2, loc=loc, ip=ip)
    return vec_f16x4


# Convert 8 float4e2m1 values to 8 float16 values
@dsl_user_op
def cvt_f4e2m1x8_to_f16x8(src_vec8, *, loc=None, ip=None):
    # pack 8 float4e2m1 into 1 int32 value and fill upper bits with 0
    src_i32 = llvm.bitcast(Int32.mlir_type, src_vec8, loc=loc, ip=ip)
    rst_i32x4 = llvm.inline_asm(
        llvm.StructType.get_literal([T.i32(), T.i32(), T.i32(), T.i32()]),
        [src_i32],
        """{\n\t
            .reg .b8 b0, b1, b2, b3;\n\t
            mov.b32 {b0, b1, b2, b3}, $4;\n\t
            cvt.rn.f16x2.e2m1x2 $0, b0;\n\t
            cvt.rn.f16x2.e2m1x2 $1, b1;\n\t
            cvt.rn.f16x2.e2m1x2 $2, b2;\n\t
            cvt.rn.f16x2.e2m1x2 $3, b3;\n\t
        }""",
        "=r,=r,=r,=r,r",
    )
    res0 = llvm.extractvalue(T.i32(), rst_i32x4, [0])
    res1 = llvm.extractvalue(T.i32(), rst_i32x4, [1])
    res2 = llvm.extractvalue(T.i32(), rst_i32x4, [2])
    res3 = llvm.extractvalue(T.i32(), rst_i32x4, [3])
    vec_f32x4_type = ir.VectorType.get([4], Int32.mlir_type, loc=loc)
    vec_f32x4 = vector.from_elements(
        vec_f32x4_type, [res0, res1, res2, res3], loc=loc, ip=ip
    )
    vec_f16x8_type = ir.VectorType.get([8], Float16.mlir_type, loc=loc)
    vec_f16x8 = llvm.bitcast(vec_f16x8_type, vec_f32x4, loc=loc, ip=ip)
    return vec_f16x8
