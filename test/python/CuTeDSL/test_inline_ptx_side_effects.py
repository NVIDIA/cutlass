# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
Unit tests for ``cute.arch.inline_ptx(has_side_effects=...)``.

A call with ``has_side_effects=False`` is pure, so the compiler merges two
identical calls and deletes one whose result is unused. The default keeps
every call. The tests read the PTX of small kernels, so they need a CUDA GPU
and skip without one.
"""

import unittest
from unittest import mock

import torch

import cutlass
import cutlass.cute as cute
from cutlass import Boolean, Float32, Int32
from cutlass.cute.runtime import from_dlpack
from cutlass.cutlass_dsl import CuTeDSL

_EX2 = "ex2.approx.ftz.f32 {$w0}, {$r0};"


def _ex2(x, pure):
    return cute.arch.inline_ptx(
        _EX2,
        write_only_types=[Float32],
        read_only_args=[x],
        has_side_effects=not pure,
    )


@cute.kernel
def _twice(t: cute.Tensor, pure: cutlass.Constexpr[bool]):
    tidx, _, _ = cute.arch.thread_idx()
    x = t[tidx]
    t[tidx] = _ex2(x, pure) + _ex2(x, pure)


@cute.kernel
def _unused(t: cute.Tensor, pure: cutlass.Constexpr[bool]):
    tidx, _, _ = cute.arch.thread_idx()
    _ex2(t[tidx], pure)
    t[tidx] = t[tidx] + Float32(1.0)


@cute.kernel
def _two_outputs(t: cute.Tensor, s: cute.Tensor, f: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    total, as_float = cute.arch.inline_ptx(
        "{ add.s32 {$w0}, {$r0}, {$r1}; cvt.rn.f32.s32 {$w1}, {$r0}; }",
        write_only_types=[Int32, Float32],
        read_only_args=[t[tidx], Int32(100)],
        has_side_effects=False,
    )
    s[tidx] = total
    f[tidx] = as_float


@cute.jit
def _launch(kernel: cutlass.Constexpr, t: cute.Tensor, pure: cutlass.Constexpr[bool]):
    kernel(t, pure).launch(grid=[1, 1, 1], block=[32, 1, 1])


@cute.jit
def _launch_two_outputs(t: cute.Tensor, s: cute.Tensor, f: cute.Tensor):
    _two_outputs(t, s, f).launch(grid=[1, 1, 1], block=[32, 1, 1])


@cute.kernel
def _with_predicate(t: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    t[tidx] = cute.arch.inline_ptx(
        _EX2,
        write_only_types=[Float32],
        read_only_args=[t[tidx]],
        predicate=Boolean(True),
        has_side_effects=False,
    )


@cute.kernel
def _with_read_write(t: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    cute.arch.inline_ptx(
        "add.f32 {$rw0}, {$rw0}, {$r0};",
        read_only_args=[t[tidx]],
        read_write_args=[t[tidx]],
        write_only_types=[Float32],
        has_side_effects=False,
    )


@cute.kernel
def _without_outputs(t: cute.Tensor):
    cute.arch.inline_ptx("nanosleep.u32 1;", has_side_effects=False)


@cute.jit
def _launch_one(kernel: cutlass.Constexpr, t: cute.Tensor):
    kernel(t).launch(grid=[1, 1, 1], block=[32, 1, 1])


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class TestInlinePtxSideEffects(unittest.TestCase):
    def setUp(self):
        patcher = mock.patch.object(CuTeDSL._get_dsl().envar, "keep_ptx", True)
        patcher.start()
        self.addCleanup(patcher.stop)
        self.x = torch.full((32,), 3.0, dtype=torch.float32, device="cuda")
        self.t = from_dlpack(self.x)

    def ex2_count(self, kernel, pure):
        compiled = cute.compile(_launch, kernel, self.t, pure)
        return compiled, compiled.artifacts.PTX.count("ex2.approx")

    def test_pure_calls_are_merged(self):
        compiled, count = self.ex2_count(_twice, pure=True)
        self.assertEqual(count, 1)
        compiled(self.t)
        torch.testing.assert_close(self.x, torch.full_like(self.x, 16.0))

    def test_volatile_calls_are_kept(self):
        _, count = self.ex2_count(_twice, pure=False)
        self.assertEqual(count, 2)

    def test_unused_pure_call_is_deleted(self):
        _, count = self.ex2_count(_unused, pure=True)
        self.assertEqual(count, 0)

    def test_unused_volatile_call_is_kept(self):
        _, count = self.ex2_count(_unused, pure=False)
        self.assertEqual(count, 1)

    def test_pure_call_with_two_outputs(self):
        src = torch.arange(32, dtype=torch.int32, device="cuda")
        s = torch.zeros_like(src)
        f = torch.zeros(32, dtype=torch.float32, device="cuda")
        args = [from_dlpack(a) for a in (src, s, f)]
        cute.compile(_launch_two_outputs, *args)(*args)
        torch.testing.assert_close(s, src + 100)
        torch.testing.assert_close(f, src.float())

    def test_pure_call_rejects_predicate(self):
        with self.assertRaisesRegex(Exception, "takes no predicate"):
            cute.compile(_launch_one, _with_predicate, self.t)

    def test_pure_call_rejects_read_write_args(self):
        with self.assertRaisesRegex(Exception, "takes no predicate or read_write_args"):
            cute.compile(_launch_one, _with_read_write, self.t)

    def test_pure_call_needs_outputs(self):
        with self.assertRaisesRegex(Exception, "needs write_only_types"):
            cute.compile(_launch_one, _without_outputs, self.t)


if __name__ == "__main__":
    unittest.main()
