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

import unittest

import torch

import cutlass
import cutlass.cute as cute
import cutlass.memory
from cutlass.cute.nvgpu.warp import StMatrix16x8x8bOp
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def store_matrix(src: cute.Tensor, dst: cute.Tensor, matrices: cutlass.Constexpr,
                 warps: cutlass.Constexpr):
    lane, _, _ = cute.arch.thread_idx()
    tile, _, _ = cute.arch.block_idx()
    shared = cutlass.memory.SmemAllocator().allocate_tensor(
        cutlass.Uint8, cute.make_layout((16, 8 * matrices * warps), stride=(1, 16)), 16
    )
    atom = cute.make_copy_atom(
        StMatrix16x8x8bOp(transpose=True, num_matrices=matrices), cutlass.Uint8
    )
    atom_tv = atom.layout_src_tv
    layout_tv = cute.make_layout(
        ((atom_tv.shape[0], warps), atom_tv.shape[1]),
        stride=((atom_tv.stride[0], 128 * matrices), atom_tv.stride[1]),
    )
    tiled = cute.make_tiled_copy(atom, layout_tv, (16, 8 * matrices * warps))
    thread = tiled.get_slice(lane)
    source = thread.partition_S(src[tile, None, None])
    # The source partition layout is not the packed register layout for x2/x4.
    registers = cute.make_rmem_tensor(source.shape, source.element_type)
    cute.autovec_copy(source, registers)
    cute.copy(tiled, registers, thread.partition_D(shared))
    cute.arch.sync_threads()
    for k in cutlass.range_constexpr(4 * matrices):
        index = lane + 32 * warps * k
        row, col = index // (8 * matrices * warps), index % (8 * matrices * warps)
        dst[tile, row, col] = shared[row, col]


@cute.jit
def launch(src: cute.Tensor, dst: cute.Tensor, matrices: cutlass.Constexpr,
           warps: cutlass.Constexpr = 1):
    store_matrix(src, dst, matrices, warps).launch(
        grid=(src.shape[0], 1, 1), block=(32 * warps, 1, 1)
    )


@unittest.skipUnless(torch.cuda.is_available(), "requires CUDA")
class TestStMatrixThreadGroups(unittest.TestCase):
    def test_complete_warp_round_trip(self):
        if torch.cuda.get_device_capability() < (10, 0):
            self.skipTest("b8 stmatrix requires SM100 or later")
        generator = torch.Generator(device="cuda").manual_seed(3234)
        for matrices in (1, 2, 4):
            for warps in (1, 2, 4):
                for tiles in (1, 3):
                    with self.subTest(matrices=matrices, warps=warps, tiles=tiles):
                        src = torch.randint(0, 256, (tiles, 16, 8 * matrices * warps),
                                            dtype=torch.uint8, device="cuda", generator=generator)
                        dst = torch.empty_like(src)
                        a, b = from_dlpack(src, assumed_align=16), from_dlpack(dst, assumed_align=16)
                        compiled = cute.compile(launch, a, b, matrices, warps)
                        compiled(a, b)
                        self.assertTrue(torch.equal(dst, src))


if __name__ == "__main__":
    unittest.main()
