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

import unittest

import cutlass
from cutlass import cute
import cutlass.utils
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import from_dlpack
import torch


@cute.kernel
def reduce_kernel(out: cute.Tensor, count: cutlass.Constexpr):
    lane = cute.arch.thread_idx()[0]
    block = cute.arch.block_idx()[0]
    shared = cutlass.utils.SmemAllocator().allocate_tensor(
        cutlass.Float32, cute.make_layout(count), 16
    )
    for i in range(lane, count, 32):
        shared[i] = cutlass.Float32(i % 17 + block + 1)
    cute.arch.fence_proxy(kind="async.shared", space="cta")
    cute.arch.sync_threads()
    if lane == 0:
        atom = cute.make_copy_atom(
            cpasync.CopyReduceBulkS2GOp(), cutlass.Float32, num_bits_per_copy=count * 32
        )
        tiled = cute.make_tiled_copy(atom, atom.layout_src_tv, (count,))
        thread = tiled.get_slice(0)
        cute.copy(tiled, thread.partition_S(shared), thread.partition_D(out))
        cute.arch.cp_async_bulk_commit_group()
        cute.arch.cp_async_bulk_wait_group(0)


@cute.jit
def launch(out: cute.Tensor, count: cutlass.Constexpr, blocks: cutlass.Constexpr):
    reduce_kernel(out, count).launch(grid=(blocks, 1, 1), block=(32, 1, 1))


@cute.jit
def make_invalid_atom(dtype: cutlass.Constexpr, bits: cutlass.Constexpr):
    cute.make_copy_atom(cpasync.CopyReduceBulkS2GOp(), dtype, num_bits_per_copy=bits)


@cute.kernel
def invalid_layout_kernel(out: cute.Tensor, mode: cutlass.Constexpr):
    shared = cutlass.utils.SmemAllocator().allocate_tensor(
        cutlass.Float32, cute.make_layout(8), 16
    )
    if cute.arch.thread_idx()[0] == 0:
        if cutlass.const_expr(mode == "stride"):
            src = cute.make_tensor(shared.iterator, cute.make_layout(4, stride=2))
        else:
            src = cute.make_tensor(shared.iterator + 1, cute.make_layout(4))
        atom = cute.make_copy_atom(
            cpasync.CopyReduceBulkS2GOp(), cutlass.Float32, num_bits_per_copy=128
        )
        tiled = cute.make_tiled_copy(atom, atom.layout_src_tv, (4,))
        thread = tiled.get_slice(0)
        cute.copy(tiled, thread.partition_S(src), thread.partition_D(out))


@cute.jit
def launch_invalid(out: cute.Tensor, mode: cutlass.Constexpr):
    invalid_layout_kernel(out, mode).launch(grid=(1, 1, 1), block=(32, 1, 1))


class TestCopyReduceBulkS2G(unittest.TestCase):
    def test_add_f32_on_gpu(self):
        for count in (4, 32, 128, 1024):
            for blocks in (1, 4):
                with self.subTest(count=count, blocks=blocks):
                    out = torch.full((count,), 3.0, device="cuda")
                    tensor = from_dlpack(out, assumed_align=16)
                    fn = cute.compile(launch, tensor, count, blocks)
                    fn(tensor)
                    expected = (3 + blocks * (torch.arange(count, device="cuda") % 17 + 1)
                                + blocks * (blocks - 1) // 2)
                    torch.testing.assert_close(out, expected.float(), rtol=0, atol=0)

    def test_rejects_unsupported_type_and_size(self):
        for dtype, bits in ((cutlass.Float16, 128), (cutlass.Float32, 96)):
            with self.subTest(dtype=dtype, bits=bits):
                with self.assertRaisesRegex(ValueError, "requires Float32"):
                    cute.compile(make_invalid_atom, dtype, bits)

    def test_rejects_stride_and_offset(self):
        tensor = from_dlpack(torch.empty(4, device="cuda"), assumed_align=16)
        for mode in ("stride", "offset"):
            with self.subTest(mode=mode):
                with self.assertRaisesRegex(ValueError, "contiguous, 16-byte-aligned"):
                    cute.compile(launch_invalid, tensor, mode)


if __name__ == "__main__":
    unittest.main()
