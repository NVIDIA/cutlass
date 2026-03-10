# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

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

import argparse
import torch
import pytest

from cutlass import cute
from cutlass.cute import experimental as cute_ext
from cutlass.cute.runtime import from_dlpack
import cutlass.utils as utils


@cute.experimental.kernel
def memcpy_simt_universal_copy_kernel(
    mA: cute.Tensor, mD: cute.Tensor, addend: cute.Float16
):
    tile_mn = cute.core._pack_shape((128, 64))
    gA = cute.zipped_divide(mA, tile_mn)
    gD = cute.zipped_divide(mD, tile_mn)

    cta_m, cta_n, cta_l = cute.arch.block_idx()
    tid_x, _, _ = cute.arch.thread_idx()

    gA_tile = gA[(None, None), (cta_m, cta_n, cta_l)]
    gD_tile = gD[(None, None), (cta_m, cta_n, cta_l)]

    buffer = cute_ext.allocate(
        cute.Float16,
        cute.AddressSpace.rmem,
        cute.make_layout(((8, 1), (1, 8)), stride=((1, 8), (1, 8))),
        alignment=16,
    )

    tCgA = cute_ext.partition(
        gA_tile,
        tid_x,
        layout_tv=cute.make_layout(((16, 8), (8, 1)), stride=((8, 128), (1, 1024))),
        tiler=cute.core._pack_tile((128, 8)),
    )

    tCgD = cute_ext.partition(
        gD_tile,
        tid_x,
        layout_tv=cute.make_layout(((16, 8), (8, 1)), stride=((8, 128), (1, 1024))),
        tiler=cute.core._pack_tile((128, 8)),
    )

    # cute_ext.copy() automatically computes predicates based on the shape of
    # the tensor passed to the @cute.experimental.kernel argument
    cute_ext.copy(
        tCgA,
        buffer,
        copy_atom=cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            tCgD.element_type,
            num_bits_per_copy=128,
        ),
    )

    # Update the RMEM tensor in place using elementwise addition.
    buffer.store(buffer.load() + addend)

    # cute_ext.copy() automatically computes predicates based on the shape of
    # the tensor passed to the @cute.experimental.kernel argument
    cute_ext.copy(
        buffer,
        tCgD,
        copy_atom=cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            tCgD.element_type,
            num_bits_per_copy=128,
        ),
    )


@cute.experimental.jit
def memcpy_simt_universal_copy(
    src: cute.Tensor, dst: cute.Tensor, addend: cute.Float16
):
    tile_mn = cute.core._pack_shape((128, 64))
    div = cute.tiled_divide(src, tile_mn)
    grid = (div.shape[1], div.shape[2], div.shape[3])
    memcpy_simt_universal_copy_kernel(src, dst, addend).launch(
        grid=grid,
        block=(128, 1, 1),
        smem=cute.Int64(utils.get_smem_capacity_in_bytes("sm_80")),
    )


def run_simt_universal_memcpy(M, N, L):
    src = torch.randn(L, N, M).permute(2, 1, 0).to(torch.float16).cuda()
    dst = torch.randn(L, N, M).permute(2, 1, 0).to(torch.float16).cuda()

    mA = (
        from_dlpack(src, assumed_align=16)
        .mark_layout_dynamic(leading_dim=0)
        .mark_compact_shape_dynamic(
            mode=0, stride_order=src.dim_order(), divisibility=8
        )
    )
    mD = (
        from_dlpack(dst, assumed_align=16)
        .mark_layout_dynamic(leading_dim=0)
        .mark_compact_shape_dynamic(
            mode=0, stride_order=dst.dim_order(), divisibility=8
        )
    )
    addend = 5.0

    memcpy_simt_universal_copy(
        mA,
        mD,
        cute.Float16(addend),
        no_cache=True,
    )

    torch.testing.assert_close(src.cpu() + addend, dst.cpu())


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Example memory copy example using CuTe auto predication features."
    )
    parser.add_argument("--mnl", default=[136, 7, 9], nargs="+", type=int)
    args = parser.parse_args()

    M, N, L = tuple(args.mnl)
    run_simt_universal_memcpy(M, N, L)
    print("PASS")
