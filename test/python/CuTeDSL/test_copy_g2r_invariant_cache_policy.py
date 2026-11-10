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
Regression tests for issue #3726.

``cute.copy(atom, src, dst, cache_policy=policy)`` used to silently drop the L2
cache policy when ``atom`` was a ``CopyG2ROp`` atom created with
``invariant=True``: the IR still carried ``cute_nvgpu.atom.set_value<cache_policy>``,
but the lowering emitted a plain non-coherent load (``ld.global.nc``) with no
``L2::cache_hint``. The same copy with ``invariant=False`` lowered to
``ld.global.L2::cache_hint``.

The Python side now fails loudly instead of silently dropping the policy:
attaching a ``cache_policy`` to an invariant G2R atom raises a ``ValueError``
that names both options and the two ways out.

These tests require a CUDA device (they trace and, for the compile cases,
launch a kernel), so they are skipped when no GPU is available.
"""

import unittest

import torch

import cutlass
from cutlass import BFloat16, Float32, Int64, cute
from cutlass.cute.runtime import from_dlpack


def _has_cuda() -> bool:
    return torch.cuda.is_available()


def _make_kernel(invariant: bool, use_policy: bool):
    """Return a ``@cute.jit`` launcher for a G2R copy of 16 bf16 per thread.

    ``use_policy`` selects which kernel shape is traced (with or without an L2
    cache policy passed to ``cute.copy``); ``invariant`` is the flag the copy
    atom is created with. The policy branch is resolved at factory time so the
    traced kernel body contains no dynamic control flow.
    """

    @cute.kernel
    def k_policy(mX: cute.Tensor, mY: cute.Tensor):
        tidx, _, _ = cute.arch.thread_idx()
        policy = cute.arch.inline_ptx(
            "createpolicy.fractional.L2::evict_first.b64 {$w0}, {$r0};",
            write_only_types=[Int64],
            read_only_args=[Float32(1.0)],
        )
        load = cute.make_copy_atom(
            cute.nvgpu.CopyG2ROp(),
            BFloat16,
            num_bits_per_copy=256,
            invariant=invariant,
        )
        src = cute.make_tensor((mX.iterator + tidx * 16).align(32), cute.make_layout(16))
        r = cute.make_rmem_tensor((16,), BFloat16)
        cute.copy(load, src, r, cache_policy=policy)
        dst = cute.make_tensor(mY.iterator + tidx * 16, cute.make_layout(16))
        cute.autovec_copy(r, dst)

    @cute.kernel
    def k_plain(mX: cute.Tensor, mY: cute.Tensor):
        tidx, _, _ = cute.arch.thread_idx()
        load = cute.make_copy_atom(
            cute.nvgpu.CopyG2ROp(),
            BFloat16,
            num_bits_per_copy=256,
            invariant=invariant,
        )
        src = cute.make_tensor((mX.iterator + tidx * 16).align(32), cute.make_layout(16))
        r = cute.make_rmem_tensor((16,), BFloat16)
        cute.copy(load, src, r)
        dst = cute.make_tensor(mY.iterator + tidx * 16, cute.make_layout(16))
        cute.autovec_copy(r, dst)

    kernel = k_policy if use_policy else k_plain

    @cute.jit
    def launch(mX: cute.Tensor, mY: cute.Tensor):
        kernel(mX, mY).launch(grid=[1, 1, 1], block=[32, 1, 1])

    return launch


def _run(launch, n: int = 512) -> None:
    x = torch.randn(n, dtype=torch.bfloat16, device="cuda")
    y = torch.empty_like(x)
    launch(from_dlpack(x, assumed_align=32), from_dlpack(y, assumed_align=32))
    torch.cuda.synchronize()
    assert torch.equal(x, y)


@unittest.skipUnless(_has_cuda(), "requires a CUDA device")
class TestCopyG2RInvariantCachePolicy(unittest.TestCase):
    def test_invariant_with_policy_raises(self):
        # The core regression: invariant=True + cache_policy must fail loudly
        # instead of silently dropping the policy.
        launch = _make_kernel(invariant=True, use_policy=True)
        with self.assertRaises(ValueError) as ctx:
            _run(launch)
        msg = str(ctx.exception)
        self.assertIn("cache_policy", msg)
        self.assertIn("invariant=True", msg)
        self.assertIn("CopyG2ROp", msg)

    def test_invariant_without_policy_compiles(self):
        # invariant=True with no policy is still legal and lowers to ld.global.nc.
        _run(_make_kernel(invariant=True, use_policy=False))

    def test_noninvariant_with_policy_compiles(self):
        # invariant=False + policy is the supported path (ld.global.L2::cache_hint).
        _run(_make_kernel(invariant=False, use_policy=True))


if __name__ == "__main__":
    unittest.main()
