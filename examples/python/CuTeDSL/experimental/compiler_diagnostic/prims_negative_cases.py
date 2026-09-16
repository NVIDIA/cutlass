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

"""CuTe Python DSL negative examples for ``CUTE_DSL_COMPILER_OPT=warnings{nvvm}``.

Each case is a tiny compile-only kernel that intentionally violates one CUTLASS
primitive synchronization protocol checked by ``warnings{nvvm}``. The
compiler owns diagnostic formatting; this example only catches expected compile
failures and prints diagnostics as-is.
"""

from __future__ import annotations

import argparse
import contextlib
import io
import os
import sys
from dataclasses import dataclass
from typing import Callable

import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute
from cutlass.base_dsl import Arch
from cutlass.base_dsl.compiler import CompilerDiagnosticError
from cutlass.base_dsl.env_manager import detect_gpu_arch
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
from cutlass.experimental import primitives as prims
from cutlass.runtime import make_fake_compact_array


_DIAG_ENV = "CUTE_DSL_COMPILER_OPT"
_DEFAULT_DIAG_OPT = "warnings{nvvm}"
_WAIT_TICKS = 10_000_000
_TMA_TILE_M = 128
_TMA_TILE_K = 64
_TMA_TILE_BYTES = _TMA_TILE_M * _TMA_TILE_K * 2
_TMA_THREADS = 128
_CTA2_TMA_DIAG_CLUSTER_SIZE = 4

ArchPredicate = Callable[[Arch], bool]
_SKIP_DIAG_REASON = (
    "requires an architecture-specific diagnostic target (sm_100/sm_110 family)"
)


@dataclass(frozen=True)
class DslNegativeCase:
    name: str
    compile_fn: Callable[[], None]
    expected_diagnostics: tuple[str, ...]
    expect_failure: bool = True
    arch_predicate: ArchPredicate | None = None
    skip_reason: str = ""


def _current_arch() -> Arch:
    return Arch.from_string(
        os.environ.get("CUTE_DSL_ARCH") or detect_gpu_arch("CUTE_DSL")
    )


def _supports_arch_specific_diagnostics(arch: Arch) -> bool:
    return arch.is_family_of(Arch.sm_100f) or arch.is_family_of(Arch.sm_110f)


def _ensure_nvvm_diag_enabled() -> None:
    os.environ.setdefault(_DIAG_ENV, _DEFAULT_DIAG_OPT)


def _compiler_options(*extra_options: str) -> str:
    parts = [os.environ.get(_DIAG_ENV, _DEFAULT_DIAG_OPT), *extra_options]
    return " ".join(part.strip() for part in parts if part and part.strip())


@cute.kernel
def _unguarded_count1_arrive_kernel() -> None:
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8)

    if prims.elect_sync():
        prims.mbarrier_init(mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    prims.mbarrier_arrive(mbar, count=1)
    prims.mbarrier_try_wait_parity(mbar, 0, time_limit=_WAIT_TICKS)


@cute.jit
def _host_unguarded_count1_arrive(stream) -> None:  # noqa: ANN001
    _unguarded_count1_arrive_kernel().launch(
        grid=(1, 1, 1), block=(32, 1, 1), stream=stream
    )


def compile_unguarded_count1_arrive() -> None:
    cute.compile(
        _host_unguarded_count1_arrive,
        make_fake_stream(),
        options=_compiler_options(),
    )


@cute.kernel
def _expect_tx_without_complete_tx_kernel() -> None:
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8)

    if prims.elect_sync():
        prims.mbarrier_init(mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    if prims.elect_sync():
        prims.mbarrier_arrive_expect_tx(mbar, 16_384)
    prims.mbarrier_try_wait_parity(mbar, 0, time_limit=_WAIT_TICKS)


@cute.jit
def _host_expect_tx_without_complete_tx(stream) -> None:  # noqa: ANN001
    _expect_tx_without_complete_tx_kernel().launch(
        grid=(1, 1, 1), block=(32, 1, 1), stream=stream
    )


def compile_expect_tx_without_complete_tx() -> None:
    cute.compile(
        _host_expect_tx_without_complete_tx,
        make_fake_stream(),
        options=_compiler_options(),
    )



@cute.kernel
def _relinquish_inside_elect_sync_kernel() -> None:
    tmem_addr = cutlass.Array(
        cutlass.Int32, 1, space=cutlass.AddressSpace.smem, alignment=4
    )

    if prims.elect_sync():
        prims.tcgen05_alloc(tmem_addr, 32, group=prims.CTAGroup.CTA_1)
        prims.tcgen05_relinquish_alloc_permit(group=prims.CTAGroup.CTA_1)


@cute.jit
def _host_relinquish_inside_elect_sync(stream) -> None:  # noqa: ANN001
    _relinquish_inside_elect_sync_kernel().launch(
        grid=(1, 1, 1), block=(32, 1, 1), stream=stream
    )


def compile_relinquish_inside_elect_sync() -> None:
    cute.compile(
        _host_relinquish_inside_elect_sync,
        make_fake_stream(),
        options=_compiler_options(),
    )


@cute.kernel
def _commit_without_elect_sync_kernel() -> None:
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8)

    if prims.elect_sync():
        prims.mbarrier_init(mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    prims.tcgen05_commit(mbar, group=prims.CTAGroup.CTA_1)


@cute.jit
def _host_commit_without_elect_sync(stream) -> None:  # noqa: ANN001
    _commit_without_elect_sync_kernel().launch(
        grid=(1, 1, 1), block=(32, 1, 1), stream=stream
    )


def compile_commit_without_elect_sync() -> None:
    cute.compile(
        _host_commit_without_elect_sync,
        make_fake_stream(),
        options=_compiler_options(),
    )


@cute.kernel
def _pre_signal_dynamic_parity_kernel() -> None:
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8)

    if prims.elect_sync():
        prims.mbarrier_init(mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    if prims.elect_sync():
        prims.mbarrier_arrive(mbar, count=1)

    for i in cutlass.range(0, 2, 1):
        parity = cutlass.Int32(1) ^ cutlass.Int32(i)
        prims.mbarrier_try_wait_parity(mbar, parity, time_limit=_WAIT_TICKS)


@cute.jit
def _host_pre_signal_dynamic_parity(stream) -> None:  # noqa: ANN001
    _pre_signal_dynamic_parity_kernel().launch(
        grid=(1, 1, 1), block=(32, 1, 1), stream=stream
    )


def compile_pre_signal_dynamic_parity() -> None:
    cute.compile(
        _host_pre_signal_dynamic_parity,
        make_fake_stream(),
        options=_compiler_options(),
    )


@cute.kernel
def _partial_warp_elect_sync_bulk_copy_kernel(gmem: cutlass.Array) -> None:
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8)
    smem_dst = cutlass.Array(
        cutlass.Int32, 4, space=cutlass.AddressSpace.smem, alignment=16
    )

    if prims.elect_sync():
        prims.cp_async_bulk_shared_cluster_global(smem_dst, gmem, mbar, 16)


@cute.jit
def _host_partial_warp_elect_sync_bulk_copy(
    gmem: cutlass.Array, stream
) -> None:  # noqa: ANN001
    _partial_warp_elect_sync_bulk_copy_kernel(gmem).launch(
        grid=(1, 1, 1), block=(4, 1, 1), stream=stream
    )


def compile_partial_warp_elect_sync_bulk_copy() -> None:
    gmem = make_fake_compact_array(
        cutlass.Int32,
        (4,),
        assumed_align=16,
    )
    cute.compile(
        _host_partial_warp_elect_sync_bulk_copy,
        gmem,
        make_fake_stream(),
        options=_compiler_options(),
    )


@cute.kernel
def _cta2_tma_multicast_cluster4_leader_mbar_kernel(
    tma_src_desc: cutlass.GridConstant[cuda.TensorMap],
) -> None:
    smem = cutlass.Array(
        cutlass.Float16,
        _TMA_TILE_M * _TMA_TILE_K,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)

    warp_idx = cute.arch.warp_idx()
    cta_rank = cute.arch.block_idx_in_cluster()
    is_leader = cta_rank == cutlass.Int32(0)
    n_ctas = cute.arch.cluster_size()
    multicast_mask = (cutlass.Int32(1) << n_ctas) - cutlass.Int32(1)
    leader_txcount = cutlass.Int32(_TMA_TILE_BYTES) * n_ctas

    if is_leader:
        if warp_idx == 0:
            if prims.elect_sync():
                prims.mbarrier_init(mbar, 1)

    prims.fence_mbarrier_init()
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    if is_leader:
        if warp_idx == 0:
            if prims.elect_sync():
                prims.mbarrier_arrive_expect_tx(mbar, leader_txcount)
            if prims.elect_sync():
                prims.cp_async_bulk_tensor_shared_cluster_global(
                    smem,
                    tma_src_desc.get_ptr(),
                    (cutlass.Int32(0), cutlass.Int32(0)),
                    mbar,
                    [],
                    multicast_mask=multicast_mask,
                    group=prims.CTAGroup.CTA_2,
                )

    if is_leader:
        if warp_idx == 0:
            while not prims.mbarrier_try_wait_parity(mbar, 0, time_limit=_WAIT_TICKS):
                pass


@cute.jit
def _host_cta2_tma_multicast_cluster4_leader_mbar(
    src: cute.Tensor, stream
) -> None:  # noqa: ANN001
    tma_src_desc = cuda.create_tensor_map_tiled(
        global_address=src.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[_TMA_TILE_K, _TMA_TILE_M],
        global_strides=[_TMA_TILE_K * 2 // 16],
        box_dims=[_TMA_TILE_K, _TMA_TILE_M],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    _cta2_tma_multicast_cluster4_leader_mbar_kernel(tma_src_desc).launch(
        grid=(_CTA2_TMA_DIAG_CLUSTER_SIZE, 1, 1),
        block=(_TMA_THREADS, 1, 1),
        cluster=(_CTA2_TMA_DIAG_CLUSTER_SIZE, 1, 1),
        stream=stream,
    )


def compile_cta2_tma_multicast_cluster4_leader_mbar() -> None:
    fake_src = make_fake_compact_tensor(
        cutlass.Float16,
        (_TMA_TILE_M, _TMA_TILE_K),
        stride_order=(1, 0),
        assumed_align=16,
    )
    cute.compile(
        _host_cta2_tma_multicast_cluster4_leader_mbar,
        fake_src,
        make_fake_stream(),
        options=_compiler_options(),
    )


NEGATIVE_CASES: tuple[DslNegativeCase, ...] = (
    DslNegativeCase(
        name="unguarded_count1_arrive",
        compile_fn=compile_unguarded_count1_arrive,
        expected_diagnostics=("mbarrier arrive reaches a count=1 barrier",),
    ),
    DslNegativeCase(
        name="expect_tx_without_complete_tx",
        compile_fn=compile_expect_tx_without_complete_tx,
        expected_diagnostics=(
            "mbarrier.arrive.expect_tx may not have a matching completion source",
        ),
        expect_failure=False,
    ),
    DslNegativeCase(
        name="relinquish_inside_elect_sync",
        compile_fn=compile_relinquish_inside_elect_sync,
        expected_diagnostics=("tcgen05.relinquish_alloc_permit is inside elect.sync",),
        arch_predicate=_supports_arch_specific_diagnostics,
        skip_reason=_SKIP_DIAG_REASON,
    ),
    DslNegativeCase(
        name="commit_without_elect_sync",
        compile_fn=compile_commit_without_elect_sync,
        expected_diagnostics=("tcgen05.commit is not guarded by elect.sync",),
        expect_failure=False,
        arch_predicate=_supports_arch_specific_diagnostics,
        skip_reason=_SKIP_DIAG_REASON,
    ),
    DslNegativeCase(
        name="pre_signal_dynamic_parity",
        compile_fn=compile_pre_signal_dynamic_parity,
        expected_diagnostics=("loop-body wait with loop-derived parity",),
        expect_failure=False,
    ),
    DslNegativeCase(
        name="partial_warp_elect_sync_bulk_copy",
        compile_fn=compile_partial_warp_elect_sync_bulk_copy,
        expected_diagnostics=("full-mask elect.sync guards",),
        expect_failure=False,
    ),
    DslNegativeCase(
        name="cta2_tma_multicast_cluster4_leader_mbar",
        compile_fn=compile_cta2_tma_multicast_cluster4_leader_mbar,
        expected_diagnostics=(
            "cta_group::2 TMA multicast completes only within CTA pairs",
        ),
        expect_failure=False,
        arch_predicate=_supports_arch_specific_diagnostics,
        skip_reason=_SKIP_DIAG_REASON,
    ),
)


def _case_by_name(name: str) -> DslNegativeCase:
    for case in NEGATIVE_CASES:
        if case.name == name:
            return case
    raise KeyError(name)


def _has_expected_diagnostic(text: str, case: DslNegativeCase) -> bool:
    return all(expected in text for expected in case.expected_diagnostics)


def _print_captured_stderr(text: str) -> None:
    if text:
        print(text, file=sys.stderr, end="" if text.endswith("\n") else "\n")


def run_case(case: DslNegativeCase, *, raw: bool) -> bool:
    print(f"===== {case.name} =====", flush=True)
    if case.arch_predicate is not None:
        arch = _current_arch()
        if not case.arch_predicate(arch):
            print(f"SKIP {case.name}: {case.skip_reason}; got {arch}")
            return True

    captured_stderr = io.StringIO()
    try:
        with contextlib.redirect_stderr(captured_stderr):
            case.compile_fn()
    except CompilerDiagnosticError as exc:
        _print_captured_stderr(captured_stderr.getvalue())
        diagnostic = exc.raw_error if raw else str(exc)
        print(diagnostic, file=sys.stderr)
        if not case.expect_failure:
            print(f"FAIL {case.name}: compile failed unexpectedly", file=sys.stderr)
            return False
        if not _has_expected_diagnostic(diagnostic, case):
            expected = ", ".join(case.expected_diagnostics)
            print(f"FAIL {case.name}: missing expected diagnostic {expected}")
            return False
        print(f"PASS {case.name}")
        return True
    except Exception as exc:  # noqa: BLE001 - report all runner failures.
        _print_captured_stderr(captured_stderr.getvalue())
        print(exc, file=sys.stderr)
        print(f"FAIL {case.name}: unexpected exception", file=sys.stderr)
        return False

    diagnostic = captured_stderr.getvalue()
    _print_captured_stderr(diagnostic)
    if case.expect_failure:
        print(f"FAIL {case.name}: expected compile failure", file=sys.stderr)
        return False
    if case.expected_diagnostics and not _has_expected_diagnostic(diagnostic, case):
        expected = ", ".join(case.expected_diagnostics)
        print(
            f"FAIL {case.name}: missing expected diagnostic {expected}",
            file=sys.stderr,
        )
        return False

    print(f"PASS {case.name}")
    return True


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--case",
        choices=[case.name for case in NEGATIVE_CASES],
        action="append",
        help="Run only the named case. May be repeated.",
    )
    parser.add_argument(
        "--raw",
        action="store_true",
        help="Print raw compiler output for expected compile failures.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    _ensure_nvvm_diag_enabled()

    cases = (
        tuple(_case_by_name(name) for name in args.case)
        if args.case
        else NEGATIVE_CASES
    )

    failures = [case.name for case in cases if not run_case(case, raw=args.raw)]
    if failures:
        print(f"failed cases: {', '.join(failures)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
