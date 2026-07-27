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

import enum
import inspect
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any, Optional, Union, cast
import warnings

import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass.base_dsl.arch import Arch
from cutlass.cute.arch.constants import WARP_SIZE
from cutlass.cutlass_dsl import CuTeDSL, Boolean, Int32, Int64, if_generate, dsl_user_op
from cutlass.utils import SmemAllocator, SmemPartition


##############################################################################
# Pipeline util
##############################################################################


@dsl_user_op
def alloc_reserved_mbarrier(
    num_stages: int,
    *,
    multiplier: int = 2,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Pointer:
    """Allocate shared memory for pipeline mbarriers at reserved low address in smem.

    Allocates `num_stages * multiplier` elements of `Int64` (8-byte aligned).
    Reserved placement keeps this storage at the low address of the smem region
    so it remains valid if shared memory is later resized , which can release
    memory outside the reserved block. Pipeline classes (e.g. `PipelineAsync`,
    `PipelineOrder`) use this when `barrier_storage=None` to create their
    mbarrier storage.

    :param num_stages: Number of pipeline stages (barrier slots needed per "side");
        total elements allocated is `num_stages * multiplier`.
    :type num_stages: int
    :param multiplier: Number of barrier arrays to reserve space for; default 2
        for pipelines that use separate full and empty barriers.
    :type multiplier: int
    :param loc: Optional source location for emitted IR.
    :param ip: Optional insertion point for emitted IR.
    :return: Pointer to the allocated shared memory, suitable for use as
        `barrier_storage` in pipeline `create()` methods.
    :rtype: cute.Pointer
    """
    barrier_storage = SmemAllocator().allocate_array(
        Int64,
        num_stages * multiplier,
        byte_alignment=8,
        partition=SmemPartition.RESERVED,
        loc=loc,
        ip=ip,
    )
    return barrier_storage


##############################################################################
# Agent class
##############################################################################


class Agent(enum.Enum):
    """
    Agent indicates what is participating in the pipeline synchronization.
    """

    # Arbitrary grouping of N threads
    Thread = enum.auto()
    # A collection of 32 threads executing in lockstep
    Warp = enum.auto()
    # A collection of threads participating in a threadblock
    ThreadBlock = enum.auto()
    # A collection of threads across a cluster
    ThreadBlockCluster = enum.auto()


##############################################################################
# CooperativeGroup class
##############################################################################


class CooperativeGroup:
    """
    CooperativeGroup contains size restrictions for an Agent.
    """

    def __init__(
        self,
        agent: Agent,
        size: Union[int, Int32] = 1,
        alignment: Optional[int] = None,
    ):
        if alignment is not None:
            warnings.warn(
                "The 'alignment' parameter of CooperativeGroup's constructor is "
                "deprecated and will be removed in a subsequent release, please "
                "remove it from your code.",
                DeprecationWarning,
                stacklevel=2,
            )

        if agent in [
            Agent.Thread,
            Agent.Warp,
            Agent.ThreadBlock,
            Agent.ThreadBlockCluster,
        ]:
            if isinstance(size, int) and size <= 0:
                raise ValueError(
                    "Error: The number of threads in a CooperativeGroup must be "
                    "greater than 0."
                )
        else:
            raise ValueError("Unsupported agent type")

        # Size indicates how many agents are participating in this CooperativeGroup
        self.size = size
        # Agent indicates the type of thread grouping
        self.agent = agent


@dsl_user_op
def _get_thread_arrive_count(
    group: "CooperativeGroup",
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[int, Int32]:
    """Compute the total number of threads represented by ``group``.

    :param group: ``CooperativeGroup`` describing the agent type and count.
    :return: Number of threads in the cooperative group.
    :raises NotImplementedError: If ``group.agent`` is not one of the
        supported agents (Thread / Warp / ThreadBlock / ThreadBlockCluster).
    """
    if group.agent is Agent.Thread:
        return group.size
    elif group.agent is Agent.Warp:
        return group.size * WARP_SIZE
    elif group.agent is Agent.ThreadBlock:
        bdim_x, bdim_y, bdim_z = cute.arch.block_dim(loc=loc, ip=ip)
        return group.size * bdim_x * bdim_y * bdim_z
    elif group.agent is Agent.ThreadBlockCluster:
        bdim_x, bdim_y, bdim_z = cute.arch.block_dim(loc=loc, ip=ip)
        return (
            group.size
            * cute.arch.cluster_size(loc=loc, ip=ip)
            * bdim_x
            * bdim_y
            * bdim_z
        )
    raise NotImplementedError(
        f"Error: Unsupported agent type for arrive count: {group.agent}"
    )


##############################################################################
# PipelineOp class
##############################################################################


class PipelineOp(enum.Enum):
    """
    PipelineOp assigns an operation to an agent corresponding to a specific hardware feature.
    """

    # async-threads
    AsyncThread = enum.auto()
    # Blackwell (SM100a) MMA instruction
    TCGen05Mma = enum.auto()
    # Tensor Memory Accelerator load
    TmaLoad = enum.auto()
    # Cluster launch cancel response load
    ClcLoad = enum.auto()
    # TMA Store consuming smem produced by AsyncThread
    TmaStore = enum.auto()
    # Composite of multiple PipelineOps
    Composite = enum.auto()
    # Async load without TMA
    AsyncLoad = enum.auto()

def _get_pipeline_op(type_str: int | PipelineOp) -> PipelineOp:
    return PipelineOp(type_str)


class MbarrierLayout(enum.Enum):
    """Layout of mbarrier used for synchronization."""

    # Transactional mbarrier
    V0 = enum.auto()

##############################################################################
# SyncObject class
##############################################################################


class SyncObject(ABC):
    """Abstract base class for hardware synchronization primitives.

    This class defines the interface for different types of hardware synchronization
    mechanisms including shared memory barriers, named barriers, and fences.
    """

    @abstractmethod
    def arrive(self, *args: Any, **kwargs: Any) -> None:
        pass

    @abstractmethod
    def wait(self, *args: Any, **kwargs: Any) -> None:
        pass

    @abstractmethod
    def arrive_and_wait(self) -> None:
        pass

    @abstractmethod
    def arrive_and_drop(self) -> None:
        pass

    @abstractmethod
    def get_barrier(self) -> Union[cute.Pointer, int, None]:
        pass

    @abstractmethod
    def max(self) -> Union[int, None]:
        pass


##############################################################################
# MbarrierArray class
##############################################################################


class MbarrierArray(SyncObject):
    """
    MbarrierArray implements an abstraction for an array of smem barriers.
    """

    @dsl_user_op
    def __init__(
        self,
        barrier_storage: cute.Pointer,
        num_stages: int,
        agent: tuple[PipelineOp, CooperativeGroup],
        tx_count: int = 0,
        mbarrier_layout: MbarrierLayout = MbarrierLayout.V0,
        name: str = "",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        self.barrier_storage = barrier_storage
        self.tx_count = tx_count
        self.num_stages = num_stages
        self.op_type, self.cg = agent
        self.arrive_count = _get_thread_arrive_count(self.cg, loc=loc, ip=ip)
        self.mbarrier_layout = mbarrier_layout
        self.name = name

        if self.num_stages <= 0:
            raise ValueError("Error: Mbarrier stage count must be greater than 0.")
        if isinstance(self.arrive_count, int) and self.arrive_count <= 0:
            raise ValueError("Error: Mbarrier arrive count must be greater than 0.")
        if self.op_type is PipelineOp.TmaLoad and self.tx_count < 0:
            raise ValueError(
                "Error: Mbarrier tx count must not be less than 0 for TMA ops."
            )
        # Store mbarrier base pointer
        self.mbarrier_base = self.barrier_storage

        # Mbarrier initialization in constructor
        self.mbarrier_init(loc=loc, ip=ip)

    def recast_to_new_op_type(self, new_op_type: PipelineOp) -> "MbarrierArray":
        """
        Creates a copy of MbarrierArray with a different op_type without re-initializing barriers
        """
        # Create new instance without initialization
        new_mbarrier_array = object.__new__(MbarrierArray)

        # Copy all attributes directly
        new_mbarrier_array.barrier_storage = self.barrier_storage
        new_mbarrier_array.op_type = new_op_type
        new_mbarrier_array.cg = self.cg
        new_mbarrier_array.num_stages = self.num_stages
        new_mbarrier_array.tx_count = self.tx_count
        new_mbarrier_array.arrive_count = self.arrive_count
        new_mbarrier_array.mbarrier_base = self.mbarrier_base
        new_mbarrier_array.mbarrier_layout = self.mbarrier_layout
        new_mbarrier_array.name = self.name
        return new_mbarrier_array

    def _mbar_scope(self, op: str) -> Any:
        """Return a Scope context manager for barrier identification.

        Format: ``name:op`` (e.g. ``smem_kv:wait``, ``tmem_sp0:arrive``).
        Profiling tools group by the ``name`` prefix and classify by the ``op`` suffix.

        Usage::

            with self._mbar_scope("wait"):
                cute.arch.mbarrier_wait(...)
        """
        if not getattr(self, "name", None):
            from contextlib import nullcontext

            return nullcontext()
        from cutlass.utils.profiling import Scope

        return Scope(f"{self.name}:{op}")

    # Mbarrier initialization
    @dsl_user_op
    def mbarrier_init(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """
        Initializes an array of mbarriers using warp 0.
        """
        def then_body() -> None:
            use_uniform_mbarrier_init = True
            if use_uniform_mbarrier_init:
                with cute.arch.elect_one(loc=loc, ip=ip):
                    for index in range(self.num_stages):
                        cute.arch.mbarrier_init(
                            self.get_barrier(index, loc=loc, ip=ip),
                            self.arrive_count,
                            loc=loc,
                            ip=ip,
                        )
        warp_idx = cute.arch.warp_idx(loc=loc, ip=ip)
        warp_idx = cute.arch.make_warp_uniform(warp_idx, loc=loc, ip=ip)

        if_generate(warp_idx == 0, then_body, loc=loc, ip=ip)

    @dsl_user_op
    def arrive(
        self,
        index: int,
        dst: int,
        cta_group: Optional[cute.nvgpu.tcgen05.CtaGroup] = None,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Select the arrive corresponding to this MbarrierArray's PipelineOp.

        :param index: Index of the mbarrier in the array to arrive on
        :type index: int
        :param dst: Destination parameter for selective arrival, which can be either a mask or destination cta rank.
            When None, both ``TCGen05Mma`` and ``AsyncThread`` will arrive on their local mbarrier.
            - For ``TCGen05Mma``, ``dst`` serves as a multicast mask (e.g., 0b1011 allows arrive signal to be multicast to CTAs
            in the cluster with rank = 0, 1, and 3).
            - For ``AsyncThread``, ``dst`` serves as a destination cta rank (e.g., 3 means threads will arrive on
            the mbarrier with rank = 3 in the cluster).
        :type dst: int | None
        :param cta_group: CTA group for ``TCGen05Mma``, defaults to None for other op types
        :type cta_group: ``cute.nvgpu.tcgen05.CtaGroup``, optional
        """
        with self._mbar_scope("arrive"):
            if self.op_type is PipelineOp.AsyncThread:
                self.arrive_mbarrier(index, dst, loc=loc, ip=ip)
            elif self.op_type is PipelineOp.TCGen05Mma:
                assert cta_group is not None, (
                    "Error: CTA group must be provided for TCGen05Mma."
                )
                self.arrive_tcgen05mma(index, dst, cta_group, loc=loc, ip=ip)
            elif self.op_type in [PipelineOp.TmaLoad]:
                # TMA operation signals local mbarrier only
                self.arrive_and_expect_tx(index, self.tx_count, loc=loc, ip=ip)
            elif self.op_type in [PipelineOp.ClcLoad]:
                # Multiple threads in CTA 0 each signal a different remote CTA in cluster's mbarrier
                self.arrive_and_expect_tx_with_dst(
                    index, self.tx_count, dst, loc=loc, ip=ip
                )
            elif self.op_type is PipelineOp.AsyncLoad:
                self.arrive_cp_async_mbarrier(index, loc=loc, ip=ip)
            else:
                assert False, (
                    f"Error: MbarrierArray is not supported for PipelineOp: {_get_pipeline_op(self.op_type)}."
                )

    @dsl_user_op
    def arrive_mbarrier(
        self,
        index: int,
        dst_rank: Optional[int] = None,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        if dst_rank is None:
            cute.arch.mbarrier_arrive(
                self.get_barrier(index, loc=loc, ip=ip), loc=loc, ip=ip
            )
        else:
            cute.arch.mbarrier_arrive(
                self.get_barrier(index, loc=loc, ip=ip), dst_rank, loc=loc, ip=ip
            )

    @dsl_user_op
    def arrive_cp_async_mbarrier(
        self,
        index: int,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        cute.arch.cp_async_mbarrier_arrive_noinc(
            self.get_barrier(index, loc=loc, ip=ip), loc=loc, ip=ip
        )

    @dsl_user_op
    def arrive_tcgen05mma(
        self,
        index: int,
        mask: Optional[int],
        cta_group: cute.nvgpu.tcgen05.CtaGroup,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        if mask is None:
            with cute.arch.elect_one(loc=loc, ip=ip):
                cute.nvgpu.tcgen05.commit(
                    self.get_barrier(index, loc=loc, ip=ip), loc=loc, ip=ip
                )
        else:
            with cute.arch.elect_one(loc=loc, ip=ip):
                cute.nvgpu.tcgen05.commit(
                    self.get_barrier(index, loc=loc, ip=ip),
                    mask,
                    cta_group,
                    loc=loc,
                    ip=ip,
                )

    @dsl_user_op
    def arrive_and_expect_tx(
        self,
        index: int,
        tx_count: int,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        with cute.arch.elect_one(loc=loc, ip=ip):
            cute.arch.mbarrier_arrive_and_expect_tx(
                self.get_barrier(index, loc=loc, ip=ip), tx_count, loc=loc, ip=ip
            )

    @dsl_user_op
    def arrive_and_expect_tx_with_dst(
        self,
        index: int,
        tx_count: int,
        dst: Optional[int] = None,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        cute.arch.mbarrier_arrive_and_expect_tx(
            self.get_barrier(index, loc=loc, ip=ip), tx_count, dst, loc=loc, ip=ip
        )

    @dsl_user_op
    def try_wait(
        self,
        index: int,
        phase: int,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Boolean:
        with self._mbar_scope("try_wait"):
            return cute.arch.mbarrier_try_wait(
                self.get_barrier(index, loc=loc, ip=ip), phase, loc=loc, ip=ip
            )

    @dsl_user_op
    def test_wait(
        self,
        index: int,
        phase: int,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Boolean:
        return cute.arch.mbarrier_test_wait(
            self.get_barrier(index, loc=loc, ip=ip), phase, loc=loc, ip=ip
        )

    @dsl_user_op
    def wait(
        self,
        index: int,
        phase: int,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """
        Wait on mbarrier.

        :param index: Index of the mbarrier in the array
        :param phase: Phase/parity to wait for (0 or 1)
        """
        with self._mbar_scope("wait"):
            cute.arch.mbarrier_wait(
                self.get_barrier(index, loc=loc, ip=ip), phase, loc=loc, ip=ip
            )

    @dsl_user_op
    def arrive_and_wait(
        self,
        index: int,
        phase: int,
        dst: int,
        cta_group: Optional[cute.nvgpu.tcgen05.CtaGroup] = None,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        arrive(index, dst, cta_group, loc=loc, ip=ip)
        wait(index, phase, loc=loc, ip=ip)

    @dsl_user_op
    def arrive_and_drop(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        raise NotImplementedError("Error: Not yet supported.")

    @dsl_user_op
    def get_barrier(
        self,
        index: int,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> cute.Pointer:
        return self.mbarrier_base + index

    def max(self) -> int:
        # Transactional barriers have a maximum arrive count of (2^20 - 1).
        return (1 << 20) - 1

    def __extract_mlir_values__(self) -> list[object]:
        return [self.barrier_storage]

    def __new_from_mlir_values__(self, values: list[object]) -> "MbarrierArray":
        new_mbarrier_array = object.__new__(MbarrierArray)
        barrier_ptr = cast(cute.Pointer, values[0])
        new_mbarrier_array.barrier_storage = barrier_ptr
        new_mbarrier_array.op_type = self.op_type
        new_mbarrier_array.cg = self.cg
        new_mbarrier_array.num_stages = self.num_stages
        new_mbarrier_array.tx_count = self.tx_count
        new_mbarrier_array.arrive_count = self.arrive_count
        new_mbarrier_array.mbarrier_base = barrier_ptr
        new_mbarrier_array.mbarrier_layout = self.mbarrier_layout
        new_mbarrier_array.name = self.name
        return new_mbarrier_array


# Set explicit signature for Sphinx documentation to avoid issues with @dsl_user_op decorator
MbarrierArray.__init__.__signature__ = inspect.Signature(  # type: ignore[attr-defined]
    [
        inspect.Parameter("self", inspect.Parameter.POSITIONAL_OR_KEYWORD),
    ]
)


##############################################################################
# NamedBarrier class
##############################################################################


@dataclass(frozen=True)
class NamedBarrier(SyncObject):
    """
    NamedBarrier is an abstraction for named barriers managed by hardware.
    There are 16 named barriers available, with barrier_ids 0-15.

    See the `PTX documentation <https://https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-bar>`__.
    """

    barrier_id: Union[int, Int32]
    num_threads: Union[int, Int32]

    def __post_init__(self) -> None:
        if isinstance(self.barrier_id, int):
            if self.barrier_id < 0 or self.barrier_id >= 16:
                raise ValueError("Error: NamedBarrier ID must be in [0,15].")
            if self.barrier_id == 0:
                warnings.warn("NamedBarrier ID 0 is used by sync_threads, avoid using.")

    @dsl_user_op
    def arrive(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """
        The aligned flavor of arrive is used when all threads in the CTA will execute the
        same instruction. See PTX documentation.
        """
        cute.arch.barrier_arrive(
            barrier_id=self.barrier_id,
            number_of_threads=self.num_threads,
            aligned=True,
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def arrive_unaligned(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """
        The unaligned flavor of arrive can be used with an arbitrary number of threads in the CTA.
        """
        cute.arch.barrier_arrive(
            barrier_id=self.barrier_id,
            number_of_threads=self.num_threads,
            aligned=False,
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def wait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """
        NamedBarriers do not have a standalone wait like mbarriers, only an arrive_and_wait.
        If synchronizing two warps in a producer/consumer pairing, the arrive count would be
        32 using mbarriers but 64 using NamedBarriers. Only threads from either the producer
        or consumer are counted for mbarriers, while all threads participating in the sync
        are counted for NamedBarriers.
        """
        warnings.warn(
            "NamedBarrier wait also arrives on the barrier. Routing call to NamedBarrier.arrive_and_wait()."
        )
        self.arrive_and_wait(loc=loc, ip=ip)

    @dsl_user_op
    def wait_unaligned(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        cute.arch.barrier(
            barrier_id=self.barrier_id,
            number_of_threads=self.num_threads,
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def arrive_and_wait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        cute.arch.barrier(
            barrier_id=self.barrier_id,
            number_of_threads=self.num_threads,
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def arrive_and_drop(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        raise NotImplementedError("Error: Not supported.")

    @dsl_user_op
    def sync(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        self.arrive_and_wait()

    @dsl_user_op
    def get_barrier(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Union[int, Int32]:
        return self.barrier_id

    def max(self) -> int:
        # Transaction barriers have a maximum arrive count of 4095 (2^12 - 1).
        return 4095


##############################################################################
# TmaStoreFence class
##############################################################################


class TmaStoreFence(SyncObject):
    """
    TmaStoreFence is used for a multi-stage epilogue buffer.
    """

    def __init__(self, num_stages: int = 0) -> None:
        if num_stages <= 0:
            raise ValueError("Mbarrier stage count must be greater than 0.")

        self.num_stages = num_stages

    @dsl_user_op
    def arrive(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        cute.arch.cp_async_bulk_commit_group(loc=loc, ip=ip)

    @dsl_user_op
    def wait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        cute.arch.cp_async_bulk_wait_group(
            self.num_stages - 1, read=True, loc=loc, ip=ip
        )

    @dsl_user_op
    def arrive_and_wait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        self.arrive(loc=loc, ip=ip)
        self.wait(loc=loc, ip=ip)

    @dsl_user_op
    def arrive_and_drop(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        raise NotImplementedError("Error: Not supported.")

    # TmaStoreFence doesn't have mbarriers
    @dsl_user_op
    def get_barrier(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        assert False, (
            "Error: TmaStoreFence doesn't use mbarriers and cannot return a barrier."
        )

    def max(self) -> None:
        raise NotImplementedError("Error: Not supported.")

    @dsl_user_op
    def tail(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        cute.arch.cp_async_bulk_wait_group(0, read=True, loc=loc, ip=ip)


##############################################################################
# PipelineUserType class
##############################################################################


class PipelineUserType(enum.Enum):
    Producer = enum.auto()
    Consumer = enum.auto()
    ProducerConsumer = enum.auto()


##############################################################################
# PipelineState class
##############################################################################


class PipelineState:
    """
    Pipeline state contains an index and phase bit corresponding to the current position in the circular buffer.
    """

    def __init__(self, stages: int, count: Int32, index: Int32, phase: Int32):
        self._stages = stages
        self._count = count
        self._index = index
        self._phase = phase

    @dsl_user_op
    @cute.jit
    def clone(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "PipelineState":
        return PipelineState(self._stages, self._count, self._index, self._phase)

    @property
    @cute.jit
    def index(self) -> Int32:
        return self._index

    @property
    @cute.jit
    def count(self) -> Int32:
        return self._count

    @property
    def stages(self) -> int:
        return self._stages

    @property
    @cute.jit
    def phase(self) -> Int32:
        return self._phase

    @dsl_user_op
    @cute.jit
    def reset_count(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        self._count = Int32(0, loc=loc, ip=ip)

    @dsl_user_op
    @cute.jit
    def advance(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        self._index += 1
        self._count += 1

        def then_body(index: Int32, phase: Int32) -> tuple[Int32, Int32]:
            new_index = Int32(0, loc=loc, ip=ip)
            new_phase = phase ^ 1
            return new_index, new_phase  # type: ignore[return-value]

        def else_body(index: Int32, phase: Int32) -> tuple[Int32, Int32]:
            return index, phase

        self._index, self._phase = if_generate(  # type: ignore[assignment, misc]
            self._index == self.stages,
            then_body,
            else_body,
            [self.index, self.phase],
            [Int32, Int32],
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    @cute.jit
    def reverse(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        self._index -= 1
        self._count -= 1

        def then_body(index: Int32, phase: Int32) -> tuple[Int32, Int32]:
            new_index = Int32(self.stages - 1, loc=loc, ip=ip)
            new_phase = phase ^ 1
            return new_index, new_phase  # type: ignore[return-value]

        def else_body(index: Int32, phase: Int32) -> tuple[Int32, Int32]:
            return index, phase

        self._index, self._phase = if_generate(  # type: ignore[assignment, misc]
            self._index == -1,
            then_body,
            else_body,
            [self.index, self.phase],
            [Int32, Int32],
            loc=loc,
            ip=ip,
        )

    def __get_mlir_types__(self) -> list[ir.Type]:
        return [self.count.type, self.index.type, self.phase.type]

    def __extract_mlir_values__(self) -> list[ir.Value]:
        return [self.count.ir_value(), self.index.ir_value(), self.phase.ir_value()]

    # This can be overridden by derived classes
    def __new_from_mlir_values__(self, values: list[ir.Value]) -> "PipelineState":
        return PipelineState(
            self.stages, Int32(values[0]), Int32(values[1]), Int32(values[2])
        )


@dsl_user_op
def make_pipeline_state(
    type: PipelineUserType,
    stages: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> PipelineState:
    """
    Creates a pipeline state. Producers are assumed to start with an empty buffer and have a flipped phase bit of 1.
    """
    if type in (PipelineUserType.Producer, PipelineUserType.ProducerConsumer):
        return PipelineState(
            stages,
            Int32(0, loc=loc, ip=ip),
            Int32(0, loc=loc, ip=ip),
            Int32(1, loc=loc, ip=ip),
        )
    elif type in (PipelineUserType.Consumer, PipelineUserType.ProducerConsumer):
        return PipelineState(
            stages,
            Int32(0, loc=loc, ip=ip),
            Int32(0, loc=loc, ip=ip),
            Int32(0, loc=loc, ip=ip),
        )
    else:
        assert False, (
            "Error: invalid PipelineUserType specified for make_pipeline_state."
        )



##############################################################################
# Helper functions
##############################################################################


@dsl_user_op
def pipeline_init_arrive(
    cluster_shape_mn: Optional[cute.Layout] = None,
    is_relaxed: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Fences the mbarrier_init and sends an arrive if using clusters.
    """

    # If using clusters, send nonblocking arrives. Otherwise, do nothing
    # because sync_threads() doesn't have a nonblocking arrive.

    cute.arch.mbarrier_init_fence(loc=loc, ip=ip)

    if cluster_shape_mn is not None and cute.size(cluster_shape_mn, loc=loc, ip=ip) > 1:
        if is_relaxed:
            # Fences memory operations issued before the arrive
            cute.arch.cluster_arrive_relaxed(loc=loc, ip=ip)
        else:
            # Skips the memory barrier
            cute.arch.cluster_arrive(loc=loc, ip=ip)


@dsl_user_op
def pipeline_init_wait(
    cluster_shape_mn: Optional[cute.Layout] = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Syncs the threadblock or cluster
    """

    if cluster_shape_mn is None or cute.size(cluster_shape_mn, loc=loc, ip=ip) == 1:
        # If not using clusters, sync the threadblock
        agent_sync(Agent.ThreadBlock, loc=loc, ip=ip)
    else:
        # If using clusters, wait on the cluster
        cute.arch.cluster_wait(loc=loc, ip=ip)


@dsl_user_op
def _sync(
    group: Agent,
    is_relaxed: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    warnings.warn("_sync is deprecated. Please use agent_sync instead.")
    agent_sync(group, is_relaxed, loc=loc, ip=ip)


@dsl_user_op
def agent_sync(
    group: Agent,
    is_relaxed: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Syncs all threads within an agent.
    """
    if group is Agent.Thread:
        raise NotImplementedError("Error: Not supported.")
    elif group is Agent.ThreadBlock:
        cute.arch.sync_threads(loc=loc, ip=ip)
    elif group is Agent.ThreadBlockCluster:
        if is_relaxed:
            cute.arch.cluster_arrive_relaxed(loc=loc, ip=ip)
        else:
            cute.arch.cluster_arrive(loc=loc, ip=ip)
        cute.arch.cluster_wait(loc=loc, ip=ip)
    else:
        assert False, (
            "Error: No explicit sync instruction exists. Please use barriers (named / mbarrier) instead."
        )


# NamedBarrier free functions
@dsl_user_op
def arrive(
    barrier_id: int,
    num_threads: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    The aligned flavor of arrive is used when all threads in the CTA will execute the
    same instruction. See PTX documentation.
    """
    cute.arch.barrier_arrive(
        barrier_id=barrier_id,
        number_of_threads=num_threads,
        aligned=True,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def arrive_unaligned(
    barrier_id: int,
    num_threads: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    The unaligned flavor of arrive can be used with an arbitrary number of threads in the CTA.
    """
    cute.arch.barrier_arrive(
        barrier_id=barrier_id,
        number_of_threads=num_threads,
        aligned=False,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def wait(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> None:
    """
    NamedBarriers do not have a standalone wait like mbarriers, only an arrive_and_wait.
    If synchronizing two warps in a producer/consumer pairing, the arrive count would be
    32 using mbarriers but 64 using NamedBarriers. Only threads from either the producer
    or consumer are counted for mbarriers, while all threads participating in the sync
    are counted for NamedBarriers.
    """
    warnings.warn(
        "NamedBarrier wait also arrives on the barrier. Routing call to NamedBarrier.arrive_and_wait()."
    )
    arrive_and_wait(loc=loc, ip=ip)


@dsl_user_op
def wait_unaligned(
    barrier_id: int,
    num_threads: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    warnings.warn(
        "NamedBarrier wait also arrives on the barrier. Routing call to NamedBarrier.arrive_and_wait()."
    )
    cute.arch.barrier(
        barrier_id=barrier_id, number_of_threads=num_threads, loc=loc, ip=ip
    )


@dsl_user_op
def arrive_and_wait(
    barrier_id: int,
    num_threads: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    cute.arch.barrier(
        barrier_id=barrier_id, number_of_threads=num_threads, loc=loc, ip=ip
    )


@dsl_user_op
def sync(
    barrier_id: int = 0,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    cute.arch.barrier(barrier_id=barrier_id, loc=loc, ip=ip)
