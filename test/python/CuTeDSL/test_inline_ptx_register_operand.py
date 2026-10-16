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
End-to-end tests for ``inline_ptx(force_register_args=...)``.

A compile-time constant that reaches a read-only operand of ``nvvm.inline_ptx``
is given the immediate constraint ``n`` by the NVVM to LLVM conversion.  Some
PTX instructions accept only a register in a given operand slot
(``max.xorsign.abs.bf16x2`` is one), so such a constant is rejected by ptxas
with "Arguments mismatch for instruction 'max'".

``force_register_args`` names the read-only operands that must be moved into a
register first.  Every test here compiles and launches a real ``@cute.jit``
kernel, so the whole path runs: DSL tracing, the NVVM to LLVM conversion, PTX
generation, ptxas and the launch.  Asserting on the IR text instead would pin
the shape of the fix without ever establishing that ptxas accepts the
instruction, which is the failure being fixed.
"""

from __future__ import annotations

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass import Int32, Int64
from cutlass.cute.arch.nvvm_wrappers import inline_ptx
from cutlass.cute.runtime import from_dlpack

_PTX_MAX_XORSIGN_ABS_BF16X2 = "max.xorsign.abs.bf16x2 {$w0}, {$r0}, {$r1};"

THREADS = 32

# bf16 bit patterns for +0, -0, +1, -1, +2, -2, +0.5, -0.5; all are exactly
# representable, so the expected result is exact rather than approximate.
_BF16_BITS = (0x0000, 0x8000, 0x3F80, 0xBF80, 0x4000, 0xC000, 0x3F00, 0xBF00)


def _carrier(lo: int, hi: int) -> int:
    """Pack two bf16 values into the i32 carrier ``max.xorsign.abs.bf16x2`` reads."""
    return (lo & 0xFFFF) | ((hi & 0xFFFF) << 16)


def _sample_carriers(count: int) -> list[int]:
    return [_carrier(_BF16_BITS[i % 8], _BF16_BITS[(i + 3) % 8]) for i in range(count)]


def _expected_carriers(count: int) -> list[int]:
    """With ``a == +0``, ``max.xorsign.abs`` returns ``b`` unchanged."""
    return _sample_carriers(count)


def _as_int32(values: list[int]) -> list[int]:
    """Reinterpret the carriers' raw bits as the signed values torch stores."""
    return [value - (1 << 32) if value >= (1 << 31) else value for value in values]


@cute.kernel
def _max_kernel(g_in: cute.Tensor, g_out: cute.Tensor, force: cutlass.Constexpr):
    tid = cute.arch.thread_idx()[0]
    b = g_in[tid]
    if cutlass.const_expr(force):
        r = inline_ptx(
            _PTX_MAX_XORSIGN_ABS_BF16X2,
            write_only_types=[Int32],
            read_only_args=[Int32(0), b],
            force_register_args=(0,),
        )
    else:
        r = inline_ptx(
            _PTX_MAX_XORSIGN_ABS_BF16X2,
            write_only_types=[Int32],
            read_only_args=[Int32(0), b],
        )
    g_out[tid] = r


@cute.jit
def _run_max(g_in: cute.Tensor, g_out: cute.Tensor, force: cutlass.Constexpr):
    _max_kernel(g_in, g_out, force).launch(grid=(1, 1, 1), block=(THREADS, 1, 1))


@cute.kernel
def _mov_kernel(g_out: cute.Tensor):
    tid = cute.arch.thread_idx()[0]
    g_out[tid] = inline_ptx(
        "mov.b64 {$w0}, {$r0};",
        write_only_types=[Int64],
        read_only_args=[Int64(7)],
        force_register_args=(0,),
    )


@cute.jit
def _run_mov(g_out: cute.Tensor):
    _mov_kernel(g_out).launch(grid=(1, 1, 1), block=(THREADS, 1, 1))


class TestInlinePtxForceRegisterArgs(unittest.TestCase):
    def setUp(self):
        if not torch.cuda.is_available():
            self.skipTest("these tests compile and launch real kernels")

    def test_constant_in_a_register_only_slot_runs(self):
        """The case from the issue: a compile-time constant ptxas rejects as an immediate.

        Before the opt-in the compile fails with "Arguments mismatch for
        instruction 'max'", so reaching the assertion at all is half the result.
        """
        x = torch.tensor(_as_int32(_sample_carriers(THREADS)), dtype=torch.int32, device="cuda")
        out = torch.zeros(THREADS, dtype=torch.int32, device="cuda")

        _run_max(from_dlpack(x), from_dlpack(out), True)

        self.assertEqual(out.cpu().tolist(), _as_int32(_expected_carriers(THREADS)))

    def test_forced_int64_operand_runs(self):
        """A wider operand takes the same path; the materialization is a mov.b64."""
        out = torch.zeros(THREADS, dtype=torch.int64, device="cuda")

        _run_mov(from_dlpack(out))

        self.assertEqual(out.cpu().tolist(), [7] * THREADS)

    def test_out_of_range_index_is_rejected(self):
        with self.assertRaises(IndexError):
            inline_ptx(
                _PTX_MAX_XORSIGN_ABS_BF16X2,
                write_only_types=[Int32],
                read_only_args=[Int32(0)],
                force_register_args=(1,),
            )

    def test_negative_index_is_rejected(self):
        with self.assertRaises(IndexError):
            inline_ptx(
                _PTX_MAX_XORSIGN_ABS_BF16X2,
                write_only_types=[Int32],
                read_only_args=[Int32(0)],
                force_register_args=(-1,),
            )

    def test_bare_int_is_rejected(self):
        """A bare int is a common mistake; it must not be read as a sequence of indices."""
        with self.assertRaises(TypeError):
            inline_ptx(
                _PTX_MAX_XORSIGN_ABS_BF16X2,
                write_only_types=[Int32],
                read_only_args=[Int32(0), Int32(7)],
                force_register_args=0,
            )

    def test_non_integer_entry_is_rejected(self):
        with self.assertRaises(TypeError):
            inline_ptx(
                _PTX_MAX_XORSIGN_ABS_BF16X2,
                write_only_types=[Int32],
                read_only_args=[Int32(0)],
                force_register_args=("0",),
            )


if __name__ == "__main__":
    unittest.main()
