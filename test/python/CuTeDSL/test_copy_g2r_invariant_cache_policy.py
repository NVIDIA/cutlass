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
Unit tests for ``cache_policy`` on ``CopyG2ROp`` Atoms created with ``invariant=True``.

An invariant G2R copy lowers to ``ld.global.nc`` with no cache qualifier, so an
L2 ``cache_policy`` passed to ``cute.copy`` used to be silently dropped
(NVIDIA/cutlass#3726). It must raise instead, while both halves keep working on
their own: an invariant copy without a policy, and a policy on a non-invariant
copy.
"""

import unittest

import cutlass.cute as cute
from cutlass import Float32, Int32, Int64
from cutlass.cute.runtime import make_fake_tensor


def _evict_first_policy():
    return cute.arch.inline_ptx(
        "createpolicy.fractional.L2::evict_first.b64 {$w0}, {$r0};",
        write_only_types=[Int64],
        read_only_args=[Float32(1.0)],
    )


def _make_g2r_atom(invariant: bool):
    return cute.make_copy_atom(
        cute.nvgpu.CopyG2ROp(), Int32, num_bits_per_copy=256, invariant=invariant
    )


def _make_g2r_copy(*, invariant: bool, with_policy: bool):
    # Two kernel bodies rather than a Python ``if`` inside one kernel: the DSL
    # traces both arms of an in-kernel branch, which would defeat the point.
    if with_policy:

        @cute.kernel
        def kernel(src: cute.Tensor, dst: cute.Tensor):
            regs = cute.make_rmem_tensor(8, Int32)
            cute.copy(_make_g2r_atom(invariant), src, regs, cache_policy=_evict_first_policy())
            cute.autovec_copy(regs, dst)

    else:

        @cute.kernel
        def kernel(src: cute.Tensor, dst: cute.Tensor):
            regs = cute.make_rmem_tensor(8, Int32)
            cute.copy(_make_g2r_atom(invariant), src, regs)
            cute.autovec_copy(regs, dst)

    @cute.jit
    def entry(src: cute.Tensor, dst: cute.Tensor):
        kernel(src, dst).launch(grid=(1, 1, 1), block=(1, 1, 1))

    return entry


class TestCopyG2RInvariantCachePolicy(unittest.TestCase):
    def setUp(self):
        self.t = make_fake_tensor(Int32, (8,), stride=(1,), assumed_align=32)

    def test_invariant_with_cache_policy_is_rejected(self):
        with self.assertRaises(Exception) as cm:
            cute.compile(_make_g2r_copy(invariant=True, with_policy=True), self.t, self.t)
        msg = str(cm.exception)
        self.assertIn("cache_policy", msg)
        self.assertIn("invariant=True", msg)
        self.assertIn("CopyG2ROp", msg)

    def test_invariant_without_cache_policy_compiles(self):
        cute.compile(_make_g2r_copy(invariant=True, with_policy=False), self.t, self.t)

    def test_cache_policy_without_invariant_compiles(self):
        cute.compile(_make_g2r_copy(invariant=False, with_policy=True), self.t, self.t)


if __name__ == "__main__":
    unittest.main()
