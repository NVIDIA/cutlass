#################################################################################################
#
# Copyright (c) 2023 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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
#
#################################################################################################

"""
Unit tests for the cute.union decorator.
"""

import logging
import unittest

import cutlass
import cutlass.cute as cute
import torch
from cutlass.cute.runtime import from_dlpack

_LOGGER = logging.getLogger(__name__)


class TestUnion(unittest.TestCase):
    def test_basic_union(self):
        """Test basic union with scalar types."""
        @cute.union
        class BasicUnion:
            as_int: cutlass.Int32
            as_float: cutlass.Float32

        size = BasicUnion.__sizeof__()
        align = BasicUnion.__alignof__()

        self.assertEqual(size, 4)
        self.assertEqual(align, 4)

    def test_different_sizes(self):
        """Test union with different sized members."""
        @cute.union
        class SizedUnion:
            small: cutlass.Int16
            medium: cutlass.Int32
            large: cutlass.Int64

        size = SizedUnion.__sizeof__()
        align = SizedUnion.__alignof__()

        # Size should be max(2, 4, 8) = 8, aligned to 8
        self.assertEqual(size, 8)
        # Alignment should be max(2, 4, 8) = 8
        self.assertEqual(align, 8)

    def test_aligned_members(self):
        """Test union with explicit alignment."""
        @cute.union
        class AlignedUnion:
            a: cute.struct.Align[cutlass.Float32, 16]
            b: cute.struct.Align[cutlass.Int32, 8]

        size = AlignedUnion.__sizeof__()
        align = AlignedUnion.__alignof__()

        # Max alignment is max(16, 8) = 16
        # Max size is 4 bytes (Float32/Int32)
        # Final size = align_up(4, 16) = 16
        self.assertEqual(size, 16)
        self.assertEqual(align, 16)

    def test_with_arrays(self):
        """Test union with MemRange arrays."""
        @cute.union
        class ArrayUnion:
            small_array: cute.struct.MemRange[cutlass.Float32, 4]
            large_array: cute.struct.MemRange[cutlass.Int64, 8]

        size = ArrayUnion.__sizeof__()
        align = ArrayUnion.__alignof__()

        # Max size is max(16, 64) = 64
        # Max alignment is max(4, 8) = 8
        # Final size = align_up(64, 8) = 64
        self.assertEqual(size, 64)
        self.assertEqual(align, 8)

    def test_comparison_with_struct(self):
        """Compare union and struct behavior."""
        @cute.struct
        class MyStruct:
            a: cutlass.Int32
            b: cutlass.Float32
            c: cutlass.Int64

        @cute.union
        class MyUnion:
            a: cutlass.Int32
            b: cutlass.Float32
            c: cutlass.Int64

        struct_size = MyStruct.__sizeof__()
        union_size = MyUnion.__sizeof__()
        struct_align = MyStruct.__alignof__()
        union_align = MyUnion.__alignof__()

        # Struct lays out sequentially: 4 + 4 + 8 = 16 bytes (already 8-aligned)
        # Union uses max size: max(4, 4, 8) = 8 bytes
        # Both have same alignment: max(4, 4, 8) = 8
        self.assertEqual(struct_size, 16)
        self.assertEqual(union_size, 8)
        self.assertEqual(struct_align, 8)
        self.assertEqual(union_align, 8)
        self.assertGreater(struct_size, union_size)

    def test_nested_union(self):
        """Test nested struct in union."""
        @cute.struct
        class InnerStruct:
            x: cutlass.Float32
            y: cutlass.Float32

        @cute.union
        class OuterUnion:
            as_struct: InnerStruct
            as_int64: cutlass.Int64

        size = OuterUnion.__sizeof__()
        align = OuterUnion.__alignof__()

        # InnerStruct is 8 bytes (2 * 4), align 4
        # Int64 is 8 bytes, align 8
        # Max size = 8, max align = max(4, 8) = 8
        self.assertEqual(size, 8)
        self.assertEqual(align, 8)

    def test_kernel_usage(self):
        """Test cute_union in an actual kernel."""
        @cute.union
        class ValueUnion:
            as_int: cutlass.Int32
            as_float: cutlass.Float32

        torch.cuda.synchronize()

        @cute.kernel
        def union_kernel():
            allocator = cutlass.utils.SmemAllocator()

            # Allocate union in shared memory
            value = allocator.allocate(ValueUnion)
            layout = cute.make_layout((1,), stride=(0,))
            tensor_int = cute.make_tensor(value.as_int, layout)
            tensor_float = cute.make_tensor(value.as_float, layout)
            tensor_float.fill(1.0)
            cute.arch.sync_threads()
            cute.printf("{}", tensor_int[0])

        @cute.jit
        def run():
            union_kernel().launch(grid=(1, 1, 1), block=(32, 1, 1))

        run()
        torch.cuda.synchronize()


if __name__ == "__main__":
    unittest.main()
