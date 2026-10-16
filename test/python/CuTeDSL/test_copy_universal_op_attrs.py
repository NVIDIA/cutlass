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
Unit tests for memory attributes passed to ``make_copy_atom``.

``CopyUniversalOp`` carries no memory attributes. A request such as
``l1c_evict_priority=...`` used to be silently dropped (the copy was emitted
as a plain ``ld.global``/``st.global``); it must raise instead so that users
move to the specialized ``CopyG2ROp``/``CopyR2GOp``/``CopyS2ROp``/``CopyR2SOp``,
which do honour the attribute.
"""

import unittest
import warnings

import cutlass.cute as cute
import cutlass.utils.distributed as distributed
from cutlass import Int32
from cutlass.cute.runtime import make_fake_tensor

_NO_ALLOCATE = cute.nvgpu.CacheEvictionPriority.NO_ALLOCATE


def _make_universal_copy(**atom_kwargs):
    @cute.kernel
    def kernel(src: cute.Tensor, dst: cute.Tensor):
        regs = cute.make_rmem_tensor(8, Int32)
        atom = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), Int32, num_bits_per_copy=256, **atom_kwargs
        )
        cute.copy(atom, src, regs)
        cute.copy(atom, regs, dst)

    @cute.jit
    def entry(src: cute.Tensor, dst: cute.Tensor):
        kernel(src, dst).launch(grid=(1, 1, 1), block=(1, 1, 1))

    return entry


def _make_specialized_copy(**atom_kwargs):
    @cute.kernel
    def kernel(src: cute.Tensor, dst: cute.Tensor):
        regs = cute.make_rmem_tensor(8, Int32)
        g2r = cute.make_copy_atom(
            cute.nvgpu.CopyG2ROp(), Int32, num_bits_per_copy=256, **atom_kwargs
        )
        r2g = cute.make_copy_atom(
            cute.nvgpu.CopyR2GOp(), Int32, num_bits_per_copy=256, **atom_kwargs
        )
        cute.copy(g2r, src, regs)
        cute.copy(r2g, regs, dst)

    @cute.jit
    def entry(src: cute.Tensor, dst: cute.Tensor):
        kernel(src, dst).launch(grid=(1, 1, 1), block=(1, 1, 1))

    return entry


def _make_ld_bypass():
    @cute.kernel
    def kernel(src: cute.Tensor, dst: cute.Tensor):
        vals = distributed.ld_bypass(src)
        regs = cute.make_rmem_tensor(8, Int32)
        regs.store(vals)
        cute.autovec_copy(regs, dst)

    @cute.jit
    def entry(src: cute.Tensor, dst: cute.Tensor):
        kernel(src, dst).launch(grid=(1, 1, 1), block=(1, 1, 1))

    return entry


class TestCopyUniversalOpAttrs(unittest.TestCase):
    def setUp(self):
        self.t = make_fake_tensor(Int32, (8,), stride=(1,), assumed_align=32)

    def _assert_rejected(self, **atom_kwargs):
        with self.assertRaises(Exception) as cm:
            cute.compile(_make_universal_copy(**atom_kwargs), self.t, self.t)
        msg = str(cm.exception)
        (name,) = atom_kwargs
        self.assertIn("CopyUniversalOp", msg)
        self.assertIn(name, msg)
        self.assertIn("CopyG2ROp", msg)

    def test_plain_universal_copy_still_compiles(self):
        cute.compile(_make_universal_copy(), self.t, self.t)

    def test_universal_rejects_l1c_evict_priority(self):
        self._assert_rejected(l1c_evict_priority=_NO_ALLOCATE)

    def test_universal_rejects_memory_order(self):
        self._assert_rejected(memory_order=cute.nvgpu.MemoryOrder.VOLATILE)

    def test_universal_rejects_memory_scope(self):
        self._assert_rejected(memory_scope=cute.nvgpu.MemoryScope.SYS)

    def test_universal_rejects_invariant(self):
        self._assert_rejected(invariant=True)

    def test_specialized_ops_accept_l1c_evict_priority(self):
        cute.compile(
            _make_specialized_copy(l1c_evict_priority=_NO_ALLOCATE), self.t, self.t
        )

    def test_ld_bypass_compiles(self):
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", DeprecationWarning)
            cute.compile(_make_ld_bypass(), self.t, self.t)


if __name__ == "__main__":
    unittest.main()
