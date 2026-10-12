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

"""
SM80 (Ampere) SIMT GEMM using tensor core MMA.

This kernel uses a single warp (32 threads) with a 16x8x8 MMA atom.
"""

import torch

import cutlass
from cutlass import cute
from cutlass.cute import experimental as cute_ext
import cutlass.torch as cutlass_torch


@cute.experimental.kernel
def sgemm_kernel(mA: cute.Tensor, mB: cute.Tensor, mD: cute.Tensor):
    """Compute D = A @ B with a single-warp SM80 tensor-core pipeline."""
    tiler_mk = (16, 8)
    tiler_nk = (8, 8)
    tiler_mn = (16, 8)

    gA = cute.zipped_divide(mA, tiler_mk)
    gB = cute.zipped_divide(mB, tiler_nk)
    gD = cute.zipped_divide(mD, tiler_mn)

    k_tile_size = cute.size(gA, mode=[1, 1])

    cta_m, cta_n, cta_l = cute.arch.block_idx()
    tid_x, _, _ = cute.arch.thread_idx()

    gA_tile = gA[(None, None), (cta_m, None, cta_l)]
    gB_tile = gB[(None, None), (cta_n, None, cta_l)]
    gD_tile = gD[(None, None), (cta_m, cta_n, cta_l)]

    # Allocate SMEM buffers for A and B
    bufferSA = cute_ext.allocate(
        cute.Float16,
        cutlass.AddressSpace.smem,
        cute.make_layout((16, 8), stride=(8, 1)),
        alignment=16,
    )

    bufferSB = cute_ext.allocate(
        cute.Float16,
        cutlass.AddressSpace.smem,
        cute.make_layout((8, 8), stride=(8, 1)),
        alignment=16,
    )

    # GMEM -> SMEM: build tiled copies for partitioning, use cute_ext.copy for transfer
    g2s_copy_atom = cute.make_copy_atom(
        cute.nvgpu.cpasync.CopyG2SOp(), cute.Float16, num_bits_per_copy=32
    )

    tiled_copy_g2s_A = cute.make_tiled_copy_tv(
        g2s_copy_atom,
        cute.make_layout((16, 2), stride=(2, 1)),
        cute.make_layout((1, 4)),
    )

    tiled_copy_g2s_B = cute.make_tiled_copy_tv(
        g2s_copy_atom,
        cute.make_layout((8, 4), stride=(4, 1)),
        cute.make_layout((1, 2)),
    )

    # Partition SMEM buffers (static, done once outside loop)
    tAsA = cute_ext.partition(
        bufferSA,
        tid_x,
        layout_tv=tiled_copy_g2s_A.layout_dst_tv_tiled,
        tiler=cute.core._pack_tile(tiled_copy_g2s_A.tiler_mn),
    )
    tBsB = cute_ext.partition(
        bufferSB,
        tid_x,
        layout_tv=tiled_copy_g2s_B.layout_dst_tv_tiled,
        tiler=cute.core._pack_tile(tiled_copy_g2s_B.tiler_mn),
    )

    # MMA configuration: 16x8x8 tensor core MMA
    tiled_mma = cute.make_tiled_mma(
        cute.make_mma_atom(
            cute.nvgpu.warp.MmaF16BF16Op(
                ab_dtype=cute.Float16,
                acc_dtype=cute.Float32,
                shape_mnk=(16, 8, 8),
            )
        ),
        atom_layout_mnk=cute.make_layout((1, 1, 1)),
    )

    # Allocate RMEM buffers for A, B, C fragments
    shape_A = tiled_mma.partition_shape_A(tiler_mk)
    bufferRA = cute_ext.allocate(
        cute.Float16,
        cutlass.AddressSpace.rmem,
        tiled_mma.make_fragment_A(shape_A).layout,
        alignment=16,
    )

    shape_B = tiled_mma.partition_shape_B(tiler_nk)
    bufferRB = cute_ext.allocate(
        cute.Float16,
        cutlass.AddressSpace.rmem,
        tiled_mma.make_fragment_B(shape_B).layout,
        alignment=16,
    )

    shape_C = tiled_mma.partition_shape_C(tiler_mn)
    bufferRC = cute_ext.allocate(
        cute.Float32,
        cutlass.AddressSpace.rmem,
        tiled_mma.make_fragment_C(shape_C).layout,
        alignment=16,
    )

    bufferRC.fill(0.0)

    # SMEM -> RMEM tiled copies (LDSM) — partition_and_copy handles LdMatrix correctly
    copy_s2r_a = cute.make_tiled_copy_A(
        cute.make_copy_atom(
            cute.nvgpu.warp.LdMatrix8x8x16bOp(transpose=False, num_matrices=1),
            cute.Float16,
        ),
        tiled_mma,
    )

    copy_s2r_b = cute.make_tiled_copy_B(
        cute.make_copy_atom(
            cute.nvgpu.warp.LdMatrix8x8x16bOp(transpose=False, num_matrices=1),
            cute.Float16,
        ),
        tiled_mma,
    )

    # Mainloop: iterate over K tiles
    for k_tile in range(k_tile_size):
        gA_k = gA_tile[None, None, k_tile]
        gB_k = gB_tile[None, None, k_tile]

        # Partition GMEM per K-tile slice (2D, matches tiler)
        tAgA_k = cute_ext.partition(
            gA_k,
            tid_x,
            layout_tv=tiled_copy_g2s_A.layout_src_tv_tiled,
            tiler=cute.core._pack_tile(tiled_copy_g2s_A.tiler_mn),
        )
        # Preserve 32-bit cpasync alignment after dynamic tid_x partitioning.
        # The aligned make_view is also the explicit predication bounds root.
        tAgA_k = cute_ext.predicated_tensor_origin(
            cute.make_tensor(tAgA_k.iterator.align(4), tAgA_k.layout)
        )
        tBgB_k = cute_ext.partition(
            gB_k,
            tid_x,
            layout_tv=tiled_copy_g2s_B.layout_src_tv_tiled,
            tiler=cute.core._pack_tile(tiled_copy_g2s_B.tiler_mn),
        )
        tBgB_k = cute_ext.predicated_tensor_origin(
            cute.make_tensor(tBgB_k.iterator.align(4), tBgB_k.layout)
        )

        # GMEM -> SMEM (cpasync)
        cute_ext.copy(tAgA_k, tAsA, copy_atom=g2s_copy_atom)
        cute_ext.copy(tBgB_k, tBsB, copy_atom=g2s_copy_atom)

        cute.arch.cp_async_commit_group()
        cute.arch.cp_async_wait_group(0)
        cute.arch.barrier()

        # SMEM -> RMEM (LDSM)
        cute_ext.partition_and_copy(copy_s2r_a.get_slice(tid_x), bufferSA, bufferRA)
        cute_ext.partition_and_copy(copy_s2r_b.get_slice(tid_x), bufferSB, bufferRB)

        # MMA
        cute_ext.dot(tiled_mma, bufferRA, bufferRB, bufferRC)

        cute.arch.barrier()

    # Epilogue: RMEM -> GMEM
    copy_r2g_c = cute.make_tiled_copy_C(
        cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), mD.element_type, num_bits_per_copy=16
        ),
        tiled_mma,
    )
    cute_ext.partition_and_copy(copy_r2g_c.get_slice(tid_x), bufferRC, gD_tile)


@cute.experimental.jit
def sgemm(a: cute.Tensor, b: cute.Tensor, d: cute.Tensor):
    tile_mn = cute.core._pack_shape((16, 8))
    div = cute.tiled_divide(d, tile_mn)
    grid = (div.shape[1], div.shape[2], div.shape[3])
    sgemm_kernel(a, b, d).launch(
        grid=grid,
        block=(32, 1, 1),
        smem=cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_80")),
    )


def create_tensors(m, n, k, l, ab_dtype, c_dtype):
    """Create input/output tensors for SM80 GEMM."""
    torch.manual_seed(1111)
    a_torch_cpu = cutlass_torch.matrix(l, m, k, False, ab_dtype)
    b_torch_cpu = cutlass_torch.matrix(l, n, k, False, ab_dtype)
    c_torch_cpu = cutlass_torch.matrix(l, m, n, False, c_dtype)

    a_tensor, _ = cutlass_torch.cute_tensor_like(
        a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    b_tensor, _ = cutlass_torch.cute_tensor_like(
        b_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    c_tensor, c_torch_gpu = cutlass_torch.cute_tensor_like(
        c_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
    )

    return a_tensor, b_tensor, c_tensor, a_torch_cpu, b_torch_cpu, c_torch_gpu


def run_sgemm(m, n, k, l=1):
    """Run SM80 GEMM and verify against reference."""
    a_tensor, b_tensor, c_tensor, a_torch_cpu, b_torch_cpu, c_torch_gpu = (
        create_tensors(m, n, k, l, cutlass.Float16, cutlass.Float32)
    )

    compiled = cute_ext.compile(sgemm, a_tensor, b_tensor, c_tensor)
    compiled(a_tensor, b_tensor, c_tensor)

    ref_c = torch.einsum(
        "mkl, nkl->mnl",
        a_torch_cpu.to(torch.float32),
        b_torch_cpu.to(torch.float32),
    )
    torch.testing.assert_close(c_torch_gpu.cpu(), ref_c, atol=1e-03, rtol=1e-05)
