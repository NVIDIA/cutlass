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
Unit tests for using @cute.struct instances across DSL control flow.

A struct instance is implicitly captured into the value set of an
`scf.if` whenever its fields are accessed inside the branch (the natural
warp-specialization pattern). For this to work, the struct must
implement the DynamicExpression protocol so the DSL can flatten/unflatten
it across the branch boundary.
"""

import unittest

import cutlass
import cutlass.cute as cute
import cutlass.utils as utils
from cutlass import Float32, Int32
from cutlass.cute.runtime import make_fake_tensor


@cute.struct
class _OneTile:
    sA: cute.struct.MemRange[Float32, 128]


@cute.struct
class _Inner:
    sX: cute.struct.MemRange[Float32, 64]


@cute.struct
class _Outer:
    inner: _Inner
    sY: cute.struct.MemRange[Float32, 64]


class TestStructInIf(unittest.TestCase):
    def test_get_tensor_inside_dynamic_if(self):
        """The original failing case: storage.<field>.get_tensor() inside
        a dynamic if. Used to raise DSLRuntimeError because the struct
        instance was not flattenable across the scf.if boundary."""

        @cute.kernel
        def k(gA: cute.Tensor):
            tidx, _, _ = cute.arch.thread_idx()
            smem_alloc = utils.SmemAllocator()
            storage = smem_alloc.allocate(_OneTile)
            sA_layout = cute.make_layout((128,), stride=(1,))
            if tidx == Int32(0):
                sA = storage.sA.get_tensor(sA_layout)
                sA[0] = gA[0]

        @cute.jit
        def entry(gA: cute.Tensor):
            k(gA).launch(grid=(1, 1, 1), block=(32, 1, 1), smem=512)

        gA = make_fake_tensor(Float32, (128,), stride=(1,), assumed_align=4)
        cute.compile(entry, gA)

    def test_struct_use_outside_if_still_works(self):
        """Regression: plain struct usage (no dynamic if) must keep
        working — i.e. the DynamicExpression-protocol injection must not
        break the existing non-branched path."""

        @cute.kernel
        def k(gA: cute.Tensor):
            tidx, _, _ = cute.arch.thread_idx()
            smem_alloc = utils.SmemAllocator()
            storage = smem_alloc.allocate(_OneTile)
            sA_layout = cute.make_layout((128,), stride=(1,))
            sA = storage.sA.get_tensor(sA_layout)
            sA[tidx] = gA[tidx]

        @cute.jit
        def entry(gA: cute.Tensor):
            k(gA).launch(grid=(1, 1, 1), block=(32, 1, 1), smem=512)

        gA = make_fake_tensor(Float32, (128,), stride=(1,), assumed_align=4)
        cute.compile(entry, gA)

    def test_nested_struct_inside_dynamic_if(self):
        """Nested struct (struct-of-struct) is also captured into the
        branch — verify the flatten round-trip still rebuilds the inner
        field correctly."""

        @cute.kernel
        def k(gA: cute.Tensor):
            tidx, _, _ = cute.arch.thread_idx()
            smem_alloc = utils.SmemAllocator()
            storage = smem_alloc.allocate(_Outer)
            inner_layout = cute.make_layout((64,), stride=(1,))
            if tidx == Int32(0):
                sX = storage.inner.sX.get_tensor(inner_layout)
                sX[0] = gA[0]

        @cute.jit
        def entry(gA: cute.Tensor):
            k(gA).launch(grid=(1, 1, 1), block=(32, 1, 1), smem=1024)

        gA = make_fake_tensor(Float32, (128,), stride=(1,), assumed_align=4)
        cute.compile(entry, gA)

    def test_if_else_branches(self):
        """Both branches of an if/else access struct fields. Covers the
        case where the struct is live on both edges of the scf.if."""

        @cute.kernel
        def k(gA: cute.Tensor):
            tidx, _, _ = cute.arch.thread_idx()
            smem_alloc = utils.SmemAllocator()
            storage = smem_alloc.allocate(_OneTile)
            sA_layout = cute.make_layout((128,), stride=(1,))
            if tidx == Int32(0):
                sA = storage.sA.get_tensor(sA_layout)
                sA[0] = gA[0]
            else:
                sA = storage.sA.get_tensor(sA_layout)
                sA[1] = gA[1]

        @cute.jit
        def entry(gA: cute.Tensor):
            k(gA).launch(grid=(1, 1, 1), block=(32, 1, 1), smem=512)

        gA = make_fake_tensor(Float32, (128,), stride=(1,), assumed_align=4)
        cute.compile(entry, gA)

    def test_if_elif_else_warp_spec_pattern(self):
        """The actual warp-specialization shape: an if/elif/elif chain
        where each role accesses a different field of the storage."""

        @cute.kernel
        def k(gA: cute.Tensor):
            tidx, _, _ = cute.arch.thread_idx()
            warp = tidx // Int32(32)
            smem_alloc = utils.SmemAllocator()
            storage = smem_alloc.allocate(_Outer)
            inner_layout = cute.make_layout((64,), stride=(1,))
            outer_layout = cute.make_layout((64,), stride=(1,))
            if warp == Int32(0):
                sX = storage.inner.sX.get_tensor(inner_layout)
                sX[0] = gA[0]
            elif warp == Int32(1):
                sY = storage.sY.get_tensor(outer_layout)
                sY[0] = gA[1]
            else:
                sY = storage.sY.get_tensor(outer_layout)
                sY[1] = gA[2]

        @cute.jit
        def entry(gA: cute.Tensor):
            k(gA).launch(grid=(1, 1, 1), block=(128, 1, 1), smem=1024)

        gA = make_fake_tensor(Float32, (128,), stride=(1,), assumed_align=4)
        cute.compile(entry, gA)

    def test_struct_captured_in_while_body(self):
        """scf.while uses the same unpack_to_irvalue machinery as scf.if
        for carrying captured Python objects through the loop. Cover
        struct access inside a dynamic while body."""

        @cute.kernel
        def k(gA: cute.Tensor):
            tidx, _, _ = cute.arch.thread_idx()
            smem_alloc = utils.SmemAllocator()
            storage = smem_alloc.allocate(_OneTile)
            sA_layout = cute.make_layout((128,), stride=(1,))
            i = Int32(0)
            while i < Int32(4):
                sA = storage.sA.get_tensor(sA_layout)
                sA[i] = gA[i]
                i = i + Int32(1)

        @cute.jit
        def entry(gA: cute.Tensor):
            k(gA).launch(grid=(1, 1, 1), block=(1, 1, 1), smem=512)

        gA = make_fake_tensor(Float32, (128,), stride=(1,), assumed_align=4)
        cute.compile(entry, gA)


if __name__ == "__main__":
    unittest.main()
