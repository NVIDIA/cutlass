# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""Run me to see ERROR renders and compilation FAIL:

    python show_error.py

The kernel does an UNGUARDED arrive on a count=1 mbarrier: every active thread
arrives, over-arriving the barrier. That is a proven defect, so it is an ERROR.

The nvvm correctness checker runs when nvvm diagnostics are requested
(warnings{nvvm} or remarks{nvvm}); there is no separate "error" flag. Once
the checker runs, an error is ALWAYS shown and FAILS compilation, regardless of
which severity filter enabled it:

    error[nvvm-diag:C3/C4]: mbarrier arrive reaches a count=1 barrier ...

This file also includes a ``@dsl_user_op`` helper that builds invalid IR to show
the internal DSL verifier error renderer:

    error[INTERNAL]: The compiler could not build valid IR ...
"""

import sys

import cutlass
import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass._mlir.dialects import arith
from cutlass._mlir_helpers.op import dsl_user_op
from cutlass.base_dsl.compiler import CompilerDiagnosticError
from cutlass.base_dsl.common import DSLRuntimeError
from cutlass.cute.runtime import make_fake_stream
from cutlass.experimental import primitives as prims

_WAIT_TICKS = 10_000_000


@cute.kernel
def unguarded_count1_arrive_kernel() -> None:
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8)

    # init expects exactly 1 arrival per phase
    if prims.elect_sync():
        prims.mbarrier_init(mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # BUG: not guarded by a single-issuer predicate -> all 32 threads arrive.
    prims.mbarrier_arrive(mbar, count=1)
    prims.mbarrier_try_wait_parity(mbar, 0, time_limit=_WAIT_TICKS)


@cute.jit
def host(stream) -> None:  # noqa: ANN001
    unguarded_count1_arrive_kernel().launch(
        grid=(1, 1, 1), block=(32, 1, 1), stream=stream
    )


@dsl_user_op
def add_mismatched_types(*, loc=None) -> None:  # noqa: ANN001
    i32 = ir.IntegerType.get_signless(32)
    i64 = ir.IntegerType.get_signless(64)
    a = arith.constant(i32, 1, loc=loc)
    b = arith.constant(i64, 2, loc=loc)
    arith.addi(a, b, loc=loc)


@cute.jit
def build() -> None:
    add_mismatched_types()


def show_nvvm_error() -> bool:
    print(
        ">>> cute.compile(host, options='warnings{nvvm}')   # runs the checker\n",
        flush=True,
    )
    try:
        cute.compile(host, make_fake_stream(), options="warnings{nvvm}")
    except CompilerDiagnosticError as exc:
        print(exc, file=sys.stderr, flush=True)
        print("\n>>> compilation FAILED with error[nvvm-diag:C3/C4] above", flush=True)
        return True
    print(">>> unexpected: compile succeeded (the error checker did not fire)")
    return False


def show_internal_error() -> bool:
    print(
        "\n>>> build()   # @dsl_user_op verifier error\n",
        flush=True,
    )
    try:
        build()
    except DSLRuntimeError as exc:
        print(exc, file=sys.stderr, flush=True)
        print(
            "\n>>> compilation FAILED with error[INTERNAL] verifier error above",
            flush=True,
        )
        return True
    print(">>> unexpected: compile succeeded")
    return False


def main() -> int:
    if not show_nvvm_error():
        return 1
    if not show_internal_error():
        return 1
    print("\n>>> finished error diagnostic demos")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
