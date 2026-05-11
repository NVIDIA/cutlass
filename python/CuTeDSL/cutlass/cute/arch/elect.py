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

from typing import Optional

from cutlass.cutlass_dsl import BaseDSL, dsl_user_op

import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir.dialects import nvvm, scf
from cutlass._mlir import ir

from ..typing import Int, Int32


@dsl_user_op
def make_warp_uniform(
    value: Int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32:
    """
    Provides a compiler hint indicating that the specified value is invariant across all threads in the warp,
    which may enable performance optimizations.

    :param value: The integer value to be marked as warp-uniform.
    :type value:  Int
    :return:      The input value, marked as warp-uniform.
    :rtype:       Int32
    """
    return Int32(
        _cute_nvgpu_ir.arch_make_warp_uniform(
            Int32(value).ir_value(loc=loc, ip=ip), loc=loc, ip=ip
        )
    )


class IfOpRegion:
    """
    A context manager for if Op.
    Automatically inserts `scf.yield([])` when exiting the context.
    """

    def __init__(
        self,
        block: ir.Block,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        self.block = block
        self.insert_point = ir.InsertionPoint(self.block)
        self.loc = loc
        self.ip = ip

    def __enter__(self) -> ir.BlockArgumentList:
        self.insert_point.__enter__()
        return self.block.arguments

    def __exit__(
        self,
        exc_type: Optional[type[BaseException]],
        exc_value: Optional[BaseException],
        traceback: object,
    ) -> None:
        scf.yield_([], loc=self.loc, ip=self.ip)
        self.insert_point.__exit__(exc_type, exc_value, traceback)


@dsl_user_op
def elect_one(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> IfOpRegion:
    """
    Elects one thread within a warp to execute single-threaded operations.

    This function uses the PTX ``elect.sync`` instruction to select exactly one thread
    per warp to execute the code within its context. All other threads in the warp skip
    the block and reconverge after it.

    See the PTX ISA documentation on `elect.sync <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-elect-sync>`__.

    **When to Use elect_one:**

    ``elect_one()`` is **required** for operations that must be executed by a single thread
    for correctness, including:

    - **Barrier initialization and transaction setup** (``mbarrier_init``, ``mbarrier_expect_tx``,
      ``mbarrier_arrive_and_expect_tx``)
    - **tcgen05 commit operations** (``tcgen05.commit``) - DSL does NOT
      automatically guard these, unlike C++ which uses ``elect_one_sync()`` internally
    - **Single-thread state setup**

    **When NOT to Use elect_one:**

    Do NOT use ``elect_one()`` for operations that already handle single-threaded execution internally:

    - **TMA copy operations** (``cute.copy`` with TMA atoms) - TMA partitioning ensures only one
      thread within a warp issues the operation automatically. Wrapping in ``elect_one()`` can cause GPU deadlock.

    .. code-block:: python

        # CORRECT: Initialize barrier with elect_one
        with elect_one():
            cute.arch.mbarrier_init(barrier_ptr, arrival_count)
            cute.arch.mbarrier_expect_tx(barrier_ptr, num_bytes)

        # CORRECT: tcgen05.commit requires elect_one in DSL
        with elect_one():
            tcgen05.commit(barrier_ptr, None, cta_group)

        # CORRECT: TMA copy does not need elect_one
        cute.copy(
            tma_atom,
            gmem_tensor,  # TMA handles single-thread internally
            smem_tensor,
            tma_bar_ptr=barrier_ptr
        )

    **PTX Programming Model:**

    In the PTX programming model, certain cluster-scoped and CTA-scoped operations must be
    issued by a single thread to maintain correctness. The ``elect.sync`` instruction provides
    a warp-uniform way to select this thread with proper synchronization.

    :return: A context manager that executes its block on exactly one thread per warp
    :rtype: IfOpRegion

    .. seealso::
       - :func:`cute.arch.mbarrier_init` - Requires elect_one
       - :func:`cute.arch.mbarrier_expect_tx` - Requires elect_one
       - :func:`cute.arch.mbarrier_arrive_and_expect_tx` - Requires elect_one
       - PTX ISA documentation on ``elect.sync``
       - Tutorial example: ``examples/blackwell/tutorial_tma/tma_v0.py``
    """
    from cutlass.base_dsl.arch import Arch

    BaseDSL._get_dsl().check_arch(lambda arch: arch >= Arch.sm_90)
    is_thread_leader = nvvm.elect_sync()
    if_op = scf.IfOp(is_thread_leader, loc=loc, ip=ip)
    return IfOpRegion(if_op.then_block, loc=loc, ip=ip)
