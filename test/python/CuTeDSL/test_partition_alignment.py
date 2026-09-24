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

"""Alignment proofs for partitioned 128-bit copies, including padded rows."""
import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def copy_rows(src: cute.Tensor, dst: cute.Tensor, stride: cutlass.Int32,
              offset: cutlass.Constexpr, dynamic: cutlass.Constexpr,
              assume_aligned: cutlass.Constexpr):
    if cutlass.const_expr(dynamic):
        if cutlass.const_expr(assume_aligned):
            stride = cute.assume(stride, divby=4)
        layout = cute.make_layout((2, 4), stride=(stride, 1))
    else:
        layout = src.layout
    source = cute.make_tensor(src.iterator + offset, layout)
    atom = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), cutlass.Float32,
                              num_bits_per_copy=128)
    tiled = cute.make_tiled_copy_tv(atom, cute.make_layout((2, 1)),
                                   cute.make_layout((1, 4)))
    thread = tiled.get_slice(cute.arch.thread_idx()[0])
    cute.copy(tiled, thread.partition_S(source), thread.partition_D(dst))


@cute.jit
def launch(src: cute.Tensor, dst: cute.Tensor, stride: cutlass.Int32,
           offset: cutlass.Constexpr, dynamic: cutlass.Constexpr,
           assume_aligned: cutlass.Constexpr):
    copy_rows(src, dst, stride, offset, dynamic, assume_aligned).launch(
        grid=(1, 1, 1), block=(2, 1, 1)
    )


def tensors(stride: int):
    storage = torch.arange(144, device="cuda", dtype=torch.float32)
    src = storage.as_strided((2, 4), (stride, 1))
    dst = torch.empty((2, 4), device="cuda", dtype=torch.float32)
    return storage, dst, from_dlpack(src, assumed_align=16), from_dlpack(dst, assumed_align=16)


@unittest.skipUnless(torch.cuda.is_available(), "requires CUDA")
class TestPartitionAlignment(unittest.TestCase):
    def test_aligned_static_rows_and_offsets(self):
        for stride, offset in ((64, 0), (68, 0), (64, 4)):
            with self.subTest(stride=stride, offset=offset):
                storage, dst, a, b = tensors(stride)
                compiled = cute.compile(launch, a, b, stride, offset, False, False)
                compiled(a, b, stride)
                expected = storage[offset:].as_strided((2, 4), (stride, 1))
                self.assertTrue(torch.equal(dst, expected))

    def test_checked_dynamic_stride(self):
        for stride in (64, 68):
            with self.subTest(stride=stride):
                storage, dst, a, b = tensors(stride)
                self.assertEqual(stride % 4, 0)
                compiled = cute.compile(launch, a, b, stride, 0, True, True)
                compiled(a, b, stride)
                self.assertTrue(torch.equal(dst, storage.as_strided((2, 4), (stride, 1))))

    def test_rejects_misaligned_partition(self):
        for stride, offset, dynamic in ((65, 0, False), (64, 1, False), (64, 0, True)):
            with self.subTest(stride=stride, offset=offset, dynamic=dynamic):
                storage, dst, a, b = tensors(stride)
                with self.assertRaisesRegex(cutlass.DSLRuntimeError, "ptr alignment"):
                    cute.compile(launch, a, b, stride, offset, dynamic, False)


if __name__ == "__main__":
    unittest.main()
