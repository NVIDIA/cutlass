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

"""Unit tests for the non tensor-map bulk reduction CopyOp."""

import unittest

import torch

import cutlass
from cutlass import cute
from cutlass._mlir.dialects.cute_nvgpu import ReductionKind
from cutlass._mlir.dialects.nvvm import ReductionOp as NvvmReductionOp
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import from_dlpack

# name -> (DSL type, torch type, bytes per element)
DTYPES = {
    "f32": (cutlass.Float32, torch.float32, 4),
    "f16": (cutlass.Float16, torch.float16, 2),
    "bf16": (cutlass.BFloat16, torch.bfloat16, 2),
    "f64": (cutlass.Float64, torch.float64, 8),
}


@cute.kernel
def reduce_kernel(out: cute.Tensor, count: cutlass.Constexpr, dtype: cutlass.Constexpr):
    lane = cute.arch.thread_idx()[0]
    block = cute.arch.block_idx()[0]
    shared = cutlass.utils.SmemAllocator().allocate_tensor(dtype, cute.make_layout(count), 16)
    for i in range(lane, count, 32):
        shared[i] = dtype(i % 17 + block + 1)
    cute.arch.fence_proxy(kind="async.shared", space="cta")
    cute.arch.sync_threads()
    if lane == 0:
        atom = cute.make_copy_atom(
            cpasync.CopyReduceBulkS2GOp(), dtype, num_bits_per_copy=count * dtype.width
        )
        tiled = cute.make_tiled_copy(atom, atom.layout_src_tv, (count,))
        thread = tiled.get_slice(0)
        cute.copy(tiled, thread.partition_S(shared), thread.partition_D(out))
        cute.arch.cp_async_bulk_commit_group()
        cute.arch.cp_async_bulk_wait_group(0)


@cute.jit
def launch(out: cute.Tensor, count: cutlass.Constexpr, blocks: cutlass.Constexpr, dtype: cutlass.Constexpr):
    reduce_kernel(out, count, dtype).launch(grid=(blocks, 1, 1), block=(32, 1, 1))


@cute.jit
def make_atom(kind: cutlass.Constexpr, dtype: cutlass.Constexpr, bits: cutlass.Constexpr):
    return cute.make_copy_atom(cpasync.CopyReduceBulkS2GOp(kind), dtype, num_bits_per_copy=bits)


@cute.jit
def make_atom_default(dtype: cutlass.Constexpr, bits: cutlass.Constexpr):
    return cute.make_copy_atom(cpasync.CopyReduceBulkS2GOp(), dtype, num_bits_per_copy=bits)


@cute.kernel
def invalid_copy_kernel(dst: cute.Tensor, dst_other: cute.Tensor, mode: cutlass.Constexpr):
    lane = cute.arch.thread_idx()[0]
    shared = cutlass.utils.SmemAllocator().allocate_tensor(cutlass.Float32, cute.make_layout(8), 16)
    shared16 = cutlass.utils.SmemAllocator().allocate_tensor(cutlass.Float16, cute.make_layout(8), 16)
    for i in range(lane, 8, 32):
        shared[i] = cutlass.Float32(1)
        shared16[i] = cutlass.Float16(1)
    cute.arch.fence_proxy(kind="async.shared", space="cta")
    cute.arch.sync_threads()
    if lane == 0:
        if cutlass.const_expr(mode == "stride"):
            src = cute.make_tensor(shared.iterator, cute.make_layout(8, stride=2))
            dtype, bits, target = cutlass.Float32, 256, dst
        elif cutlass.const_expr(mode == "offset"):
            src = cute.make_tensor(shared.iterator + 1, cute.make_layout(8))
            dtype, bits, target = cutlass.Float32, 256, dst
        elif cutlass.const_expr(mode == "dtype"):
            # same 16-bit width, different arithmetic format
            src = cute.make_tensor(shared16.iterator, cute.make_layout(8))
            dtype, bits, target = cutlass.Float16, 128, dst_other
        else:
            src = cute.make_tensor(shared.iterator, cute.make_layout(8))
            dtype, bits, target = cutlass.Float32, 256, dst
        atom = cute.make_copy_atom(cpasync.CopyReduceBulkS2GOp(), dtype, num_bits_per_copy=bits)
        tiled = cute.make_tiled_copy(atom, atom.layout_src_tv, (8,))
        thread = tiled.get_slice(0)
        if cutlass.const_expr(mode == "pred"):
            cute.copy(tiled, thread.partition_S(src), thread.partition_D(target), pred=thread.partition_S(src))
        elif cutlass.const_expr(mode == "unroll"):
            cute.copy(tiled, thread.partition_S(src), thread.partition_D(target), unroll_factor=1)
        elif cutlass.const_expr(mode == "kwargs"):
            cute.copy(tiled, thread.partition_S(src), thread.partition_D(target), cache_policy=1)
        else:
            cute.copy(tiled, thread.partition_S(src), thread.partition_D(target))


@cute.jit
def launch_invalid(dst: cute.Tensor, dst_other: cute.Tensor, mode: cutlass.Constexpr):
    invalid_copy_kernel(dst, dst_other, mode).launch(grid=(1, 1, 1), block=(32, 1, 1))


class TestCopyReduceBulkS2G(unittest.TestCase):
    def test_add_accumulates_for_every_supported_dtype(self):
        for name, (dtype, ttorch, bytes_per_element) in DTYPES.items():
            for count in (16 // bytes_per_element, 64, 512):
                for blocks in (1, 4):
                    with self.subTest(dtype=name, count=count, blocks=blocks):
                        out = torch.full((count,), 3.0, device="cuda", dtype=ttorch)
                        tensor = from_dlpack(out, assumed_align=16)
                        fn = cute.compile(launch, tensor, count, blocks, dtype)
                        fn(tensor)
                        ones = torch.arange(count, device="cuda", dtype=torch.float64) % 17 + 1
                        expected = (3.0 + blocks * ones + blocks * (blocks - 1) / 2).to(ttorch)
                        torch.testing.assert_close(out, expected, rtol=0, atol=0)

    def test_reduction_kind_contract(self):
        cute.compile(make_atom, NvvmReductionOp.ADD, cutlass.Float32, 128)
        with self.assertRaisesRegex(ValueError, "supports ReductionKind.ADD only"):
            cute.compile(make_atom, ReductionKind.MIN, cutlass.Float32, 128)
        with self.assertRaisesRegex(TypeError, "of type cute.ReductionKind"):
            cute.compile(make_atom, 1, cutlass.Float32, 128)

    def test_rejects_unsupported_dtype_and_copy_bits(self):
        for dtype in (cutlass.Int32, cutlass.Float8E4M3FN):
            with self.subTest(dtype=dtype):
                with self.assertRaisesRegex(ValueError, "supports Float16, BFloat16"):
                    cute.compile(make_atom_default, dtype, 128)
        for bits in (64, 96):
            with self.subTest(bits=bits):
                with self.assertRaisesRegex(ValueError, "positive multiple of 128"):
                    cute.compile(make_atom_default, cutlass.Float32, bits)

    def test_rejects_layout_and_operand_violations(self):
        dst = from_dlpack(torch.zeros(8, device="cuda"), assumed_align=16)
        dst_other = from_dlpack(torch.zeros(8, device="cuda", dtype=torch.bfloat16), assumed_align=16)
        for mode in ("stride", "offset", "dtype"):
            with self.subTest(mode=mode):
                with self.assertRaisesRegex(ValueError, "one contiguous, 16-byte-aligned tile"):
                    cute.compile(launch_invalid, dst, dst_other, mode)
        for mode in ("pred", "unroll", "kwargs"):
            with self.subTest(mode=mode):
                with self.assertRaisesRegex(ValueError, "one unpredicated tensor tile per call"):
                    cute.compile(launch_invalid, dst, dst_other, mode)


if __name__ == "__main__":
    unittest.main()
