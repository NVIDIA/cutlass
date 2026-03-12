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
import math
from typing import Tuple, Type

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
import cutlass.utils as utils
from cutlass.cute.runtime import from_dlpack

"""
An INT8 dense GEMM (C = A * B) example for the NVIDIA Ampere architecture using CUTE DSL.
- Matrix A is MxKxL (INT8/UINT8), L is batch dimension, A can be row-major("K") or column-major("M")
- Matrix B is NxKxL (INT8/UINT8), L is batch dimension, B can be row-major("K") or column-major("N")
- Matrix C is MxNxL (INT32), L is batch dimension, C can be row-major("N") or column-major("M")

This GEMM kernel supports the following features:
    - Utilizes Ampere's INT8 tensor cores (mma.sync m16n8k16 or m16n8k32)
    - Supports signedness: S8xS8 (S8xU8 supported by hardware but blocked by
      DSL compiler bug, U8xS8 not supported by hardware)
    - Multi-stage pipeline (3 stages) to overlap computation and memory access
    - cp.async for global-to-shared memory transfers
    - Swizzled shared memory layout for bank-conflict-free access
    - Supports arbitrary M, N, K dimensions (padded to tile boundaries)

To run this example:

.. code-block:: bash

    python examples/python/CuTeDSL/ampere/tensorop_gemm_i8.py                   \\
      --mnkl 512,512,512,1 --atom_layout_mnk 2,2,1                              \\
      --a_dtype Int8 --b_dtype Int8 --c_dtype Int32 --acc_dtype Int32             \\
      --a_major k --b_major k --c_major n

Constraints:
* Supported input types: Int8, Uint8
* Supported accumulator/output type: Int32
* Default tile shape: 128x128x64 (BM auto-selected based on M)
* A and B must be K-major (row-major): ldmatrix requires 128-bit aligned smem
  addresses, but column-major INT8 only provides 64-bit alignment
* Output C can be N-major (row-major) or M-major (column-major)
* The contiguous dimension must be at least 16 bytes aligned
"""


class TensorOpGemmI8:
    def __init__(
        self,
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        atom_layout_mnk: Tuple[int, int, int],
        use_k32: bool = False,
        bm: int = 128,
    ):
        self.a_dtype = a_dtype
        self.b_dtype = b_dtype
        self.c_dtype = c_dtype
        self.acc_dtype = acc_dtype
        self.use_k32 = use_k32
        self.cta_tiler = (bm, 128, 64)
        self.num_stages = 3
        self.atom_layout_mnk = atom_layout_mnk
        atom_lay_M, atom_lay_N, atom_lay_K = self.atom_layout_mnk
        self.num_threads = atom_lay_M * atom_lay_N * atom_lay_K * 32

        self.bM, self.bN, self.bK = self.cta_tiler
        self.mma_inst_shape = (16, 8, 32) if use_k32 else (16, 8, 16)
        mmaM, mmaN, mmaK = self.mma_inst_shape

        # PTX mma.sync constraint: if mixed signedness, A must be signed, B unsigned.
        # A=Uint8, B=Int8 is NOT supported by the hardware.
        if not self.a_dtype.signed and self.b_dtype.signed:
            raise ValueError(
                "A=Uint8, B=Int8 is not supported by the MMA instruction. "
                "Use A=Int8, B=Uint8 or same signedness for both."
            )

        assert self.bM % (atom_lay_M * mmaM) == 0, (
            "bM must be divisible by MMA instruction"
        )
        assert self.bN % (atom_lay_N * mmaN) == 0, (
            "bN must be divisible by MMA instruction"
        )
        assert atom_lay_K == 1, "this example does not support atom layout K > 1"
        assert self.bK % mmaK == 0, "bK must be divisible by MMA instruction"
        assert self.num_stages >= 3, "num_stages must be greater than or equal to 3"

    @cute.jit
    def __call__(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mC: cute.Tensor,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        self.a_major_mode = utils.LayoutEnum.from_tensor(mA)
        self.b_major_mode = utils.LayoutEnum.from_tensor(mB)
        self.c_major_mode = utils.LayoutEnum.from_tensor(mC)

        # ///////////////////////////////////////////////////////////////////////////////
        # Shared memory layout
        # ///////////////////////////////////////////////////////////////////////////////
        ab_copy_bits = 128
        sA_layout = self._make_smem_layout_AB(
            mA.element_type,
            self.a_major_mode,
            ab_copy_bits,
            (self.cta_tiler[0], self.cta_tiler[2], self.num_stages),
        )
        sB_layout = self._make_smem_layout_AB(
            mB.element_type,
            self.b_major_mode,
            ab_copy_bits,
            (self.cta_tiler[1], self.cta_tiler[2], self.num_stages),
        )

        smem_size = (
            cute.size_in_bytes(mA.element_type, sA_layout)
            + cute.size_in_bytes(mB.element_type, sB_layout)
        )

        # ///////////////////////////////////////////////////////////////////////////////
        # Tiled copy: global memory -> shared memory (asynchronous cp.async)
        # ///////////////////////////////////////////////////////////////////////////////
        atom_async_copy = cute.make_copy_atom(
            cute.nvgpu.cpasync.CopyG2SOp(
                cache_mode=cute.nvgpu.cpasync.LoadCacheMode.GLOBAL
            ),
            mA.element_type,
            num_bits_per_copy=ab_copy_bits,
        )

        tiled_copy_A = self._make_gmem_tiled_copy_AB(
            atom_async_copy, mA.element_type, self.a_major_mode, ab_copy_bits
        )
        tiled_copy_B = self._make_gmem_tiled_copy_AB(
            atom_async_copy, mB.element_type, self.b_major_mode, ab_copy_bits
        )

        # ///////////////////////////////////////////////////////////////////////////////
        # Tiled MMA
        # ///////////////////////////////////////////////////////////////////////////////
        op = cute.nvgpu.warp.MmaI8Op(
            self.a_dtype, self.b_dtype, self.acc_dtype, self.mma_inst_shape
        )

        permutation_mnk = (
            self.atom_layout_mnk[0] * self.mma_inst_shape[0],
            self.atom_layout_mnk[1] * self.mma_inst_shape[1] * 2,
            self.atom_layout_mnk[2] * self.mma_inst_shape[2],
        )

        tC = cute.make_layout(self.atom_layout_mnk)
        tiled_mma = cute.make_tiled_mma(
            op,
            tC,
            permutation_mnk=permutation_mnk,
        )

        grid_dim = cute.ceil_div(mC.shape, (self.bM, self.bN, 1))

        raster_factor = 1
        grid_dim_n = cute.size(grid_dim[1])
        if grid_dim_n > 5:
            raster_factor = 8
        elif grid_dim_n > 2:
            raster_factor = 4
        elif grid_dim_n > 1:
            raster_factor = 2
        rasterization_remap_grid_dim = (
            cute.size(grid_dim[0]) * raster_factor,
            (cute.size(grid_dim[1]) + raster_factor - 1) // raster_factor,
            cute.size(grid_dim[2]),
        )

        self.kernel(
            mA,
            mB,
            mC,
            sA_layout,
            sB_layout,
            tiled_copy_A,
            tiled_copy_B,
            tiled_mma,
            raster_factor,
            epilogue_op,
        ).launch(
            grid=rasterization_remap_grid_dim,
            block=[self.num_threads, 1, 1],
            smem=smem_size,
        )

    @cute.kernel
    def kernel(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mC: cute.Tensor,
        sA_layout: cute.ComposedLayout,
        sB_layout: cute.ComposedLayout,
        tiled_copy_A: cute.TiledCopy,
        tiled_copy_B: cute.TiledCopy,
        tiled_mma: cute.TiledMma,
        rasterization_factor: cutlass.Int32,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        # Thread index, block index
        tidx, _, _ = cute.arch.thread_idx()
        bidx, bidy, bidz = cute.arch.block_idx()
        grid_dim = cute.ceil_div(mC.shape, (self.bM, self.bN, 1))
        offset_tile_x, offset_tile_y = self.raster_tile(
            bidx, bidy, rasterization_factor
        )
        # Early exit if CTA is out of range
        if grid_dim[0] <= offset_tile_x or grid_dim[1] <= offset_tile_y:
            pass
        else:
            tiler_coord = (offset_tile_x, offset_tile_y, None)

            # ///////////////////////////////////////////////////////////////////////////////
            # Get the appropriate tiles for this thread block.
            # gA: (BLK_M, BLK_K, k), gB: (BLK_N, BLK_K, k), gC: (BLK_M, BLK_N)
            # ///////////////////////////////////////////////////////////////////////////////
            gA = cute.local_tile(
                mA[None, None, bidz],
                tiler=self.cta_tiler,
                coord=tiler_coord,
                proj=(1, None, 1),
            )
            gB = cute.local_tile(
                mB[None, None, bidz],
                tiler=self.cta_tiler,
                coord=tiler_coord,
                proj=(None, 1, 1),
            )
            gC = cute.local_tile(
                mC[None, None, bidz],
                tiler=self.cta_tiler,
                coord=tiler_coord,
                proj=(1, 1, None),
            )

            # Make the first k-tiles irregular instead of last, so we handle
            # the residual tile first and avoid a condition in the mainloop.
            residual_k = cute.size(mA, mode=[1]) - cutlass.Int32(self.bK) * cute.size(
                gA, mode=[2]
            )

            gA = cute.domain_offset((0, residual_k, 0), gA)
            gB = cute.domain_offset((0, residual_k, 0), gB)
            gA = cute.make_tensor(gA.iterator.align(16), gA.layout)
            gB = cute.make_tensor(gB.iterator.align(16), gB.layout)

            # Construct identity layout for predication
            mcA = cute.make_identity_tensor(mA.layout.shape)
            mcB = cute.make_identity_tensor(mB.layout.shape)
            cA = cute.local_tile(
                mcA[None, None, bidz],
                tiler=self.cta_tiler,
                coord=tiler_coord,
                proj=(1, None, 1),
            )
            cB = cute.local_tile(
                mcB[None, None, bidz],
                tiler=self.cta_tiler,
                coord=tiler_coord,
                proj=(None, 1, 1),
            )

            cA = cute.domain_offset((0, residual_k, 0), cA)
            cB = cute.domain_offset((0, residual_k, 0), cB)

            # ///////////////////////////////////////////////////////////////////////////////
            # Create shared memory buffers and thread partitions.
            # sA:   (BLK_M, BLK_K, PIPE)       , sB:   (BLK_N, BLK_K, PIPE)
            # tAgA: (CPY, CPY_M, CPY_K, k)     , tBgB: (CPY, CPY_N, CPY_K, k)
            # tAsA: (CPY, CPY_M, CPY_K, PIPE)  , tBsB: (CPY, CPY_N, CPY_K, PIPE)
            # ///////////////////////////////////////////////////////////////////////////////
            smem = cutlass.utils.SmemAllocator()

            sA = smem.allocate_tensor(mA.element_type, sA_layout, 16)
            sB = smem.allocate_tensor(mB.element_type, sB_layout, 16)

            thr_copy_A = tiled_copy_A.get_slice(tidx)
            thr_copy_B = tiled_copy_B.get_slice(tidx)
            tAgA = thr_copy_A.partition_S(gA)
            tAsA = thr_copy_A.partition_D(sA)
            tBgB = thr_copy_B.partition_S(gB)
            tBsB = thr_copy_B.partition_D(sB)

            tAcA = thr_copy_A.partition_S(cA)
            tBcB = thr_copy_B.partition_S(cB)

            # ///////////////////////////////////////////////////////////////////////////////
            # Predication: mark indices that need copies when M/N/K aren't
            # multiples of tile shape. M/N predicates are stored in tensors;
            # K residual is handled by the domain_offset + if/else branch.
            # ///////////////////////////////////////////////////////////////////////////////
            tApA = cute.make_rmem_tensor(
                cute.make_layout(
                    (
                        tAgA.shape[0][1],
                        cute.size(tAgA, mode=[1]),
                        cute.size(tAgA, mode=[2]),
                    ),
                    stride=(cute.size(tAgA, mode=[1]), 1, 0),
                ),
                cutlass.Boolean,
            )
            tBpB = cute.make_rmem_tensor(
                cute.make_layout(
                    (
                        tBsB.shape[0][1],
                        cute.size(tBsB, mode=[1]),
                        cute.size(tBsB, mode=[2]),
                    ),
                    stride=(cute.size(tBsB, mode=[1]), 1, 0),
                ),
                cutlass.Boolean,
            )
            for rest_v in range(tApA.shape[0]):
                for m in range(tApA.shape[1]):
                    tApA[rest_v, m, 0] = cute.elem_less(
                        tAcA[(0, rest_v), m, 0, 0][0], mA.shape[0]
                    )
            for rest_v in range(tBpB.shape[0]):
                for n in range(tBpB.shape[1]):
                    tBpB[rest_v, n, 0] = cute.elem_less(
                        tBcB[(0, rest_v), n, 0, 0][0], mB.shape[0]
                    )

            # ///////////////////////////////////////////////////////////////////////////////
            # Prefetch prologue
            # ///////////////////////////////////////////////////////////////////////////////
            tAsA.fill(0)
            tBsB.fill(0)
            cute.arch.sync_threads()
            num_smem_stages = cute.size(tAsA, mode=[3])
            k_tile_count = cute.size(tAgA, mode=[3])
            k_tile_index = cutlass.Int32(0)

            for k in range(tApA.shape[2]):
                if cute.elem_less(cutlass.Int32(-1), tAcA[0, 0, k, 0][1]):
                    cute.copy(
                        tiled_copy_A,
                        tAgA[None, None, k, k_tile_index],
                        tAsA[None, None, k, 0],
                        pred=tApA[None, None, k],
                    )
            for k in range(tBpB.shape[2]):
                if cute.elem_less(cutlass.Int32(-1), tBcB[0, 0, k, 0][1]):
                    cute.copy(
                        tiled_copy_B,
                        tBgB[None, None, k, k_tile_index],
                        tBsB[None, None, k, 0],
                        pred=tBpB[None, None, k],
                    )
            k_tile_index = k_tile_index + 1
            cute.arch.cp_async_commit_group()

            for k_tile in range(1, num_smem_stages - 1):
                if k_tile == k_tile_count:
                    tApA.fill(0)
                    tBpB.fill(0)
                cute.copy(
                    tiled_copy_A,
                    tAgA[None, None, None, k_tile_index],
                    tAsA[None, None, None, k_tile],
                    pred=tApA,
                )
                cute.copy(
                    tiled_copy_B,
                    tBgB[None, None, None, k_tile_index],
                    tBsB[None, None, None, k_tile],
                    pred=tBpB,
                )
                k_tile_index = k_tile_index + 1
                cute.arch.cp_async_commit_group()

            # ///////////////////////////////////////////////////////////////////////////////
            # Tile MMA compute thread partitions and allocate accumulators
            # ///////////////////////////////////////////////////////////////////////////////
            thr_mma = tiled_mma.get_slice(tidx)
            tCsA = thr_mma.partition_A(sA)
            tCsB = thr_mma.partition_B(sB)
            tCgC = thr_mma.partition_C(gC)
            tCrA = tiled_mma.make_fragment_A(tCsA[None, None, None, 0])
            tCrB = tiled_mma.make_fragment_B(tCsB[None, None, None, 0])
            tCrC = tiled_mma.make_fragment_C(tCgC)
            tCrC.fill(0)

            # ///////////////////////////////////////////////////////////////////////////////
            # Copy Atom A/B retiling (shared memory -> registers)
            # ///////////////////////////////////////////////////////////////////////////////
            # S2R copy atoms for INT8
            # Use LdMatrix8x8x16bOp: ldmatrix operates in 16-bit register
            # units regardless of element type; each 16b value holds 2 INT8
            # elements. The transpose depends on the majorness of the operand.
            atom_copy_s2r_A = cute.make_copy_atom(
                cute.nvgpu.warp.LdMatrix8x8x16bOp(
                    self.a_major_mode != utils.LayoutEnum.ROW_MAJOR, 4
                ),
                mA.element_type,
            )
            atom_copy_s2r_B = cute.make_copy_atom(
                cute.nvgpu.warp.LdMatrix8x8x16bOp(
                    self.b_major_mode != utils.LayoutEnum.ROW_MAJOR, 4
                ),
                mB.element_type,
            )

            tiled_copy_s2r_A = cute.make_tiled_copy_A(atom_copy_s2r_A, tiled_mma)
            tiled_copy_s2r_B = cute.make_tiled_copy_B(atom_copy_s2r_B, tiled_mma)

            thr_copy_ldmatrix_A = tiled_copy_s2r_A.get_slice(tidx)
            thr_copy_ldmatrix_B = tiled_copy_s2r_B.get_slice(tidx)
            tCsA_copy_view = thr_copy_ldmatrix_A.partition_S(sA)
            tCrA_copy_view = thr_copy_ldmatrix_A.retile(tCrA)
            tCsB_copy_view = thr_copy_ldmatrix_B.partition_S(sB)
            tCrB_copy_view = thr_copy_ldmatrix_B.retile(tCrB)

            smem_pipe_read = 0
            smem_pipe_write = num_smem_stages - 1

            tCsA_p = tCsA_copy_view[None, None, None, smem_pipe_read]
            tCsB_p = tCsB_copy_view[None, None, None, smem_pipe_read]

            # Register pipeline prefetch
            num_k_block = cute.size(tCrA, mode=[2])
            if num_k_block > 1:
                cute.arch.cp_async_wait_group(num_smem_stages - 2)
                cute.arch.sync_threads()
                cute.copy(
                    tiled_copy_s2r_A,
                    tCsA_p[None, None, 0],
                    tCrA_copy_view[None, None, 0],
                )
                cute.copy(
                    tiled_copy_s2r_B,
                    tCsB_p[None, None, 0],
                    tCrB_copy_view[None, None, 0],
                )

            # ///////////////////////////////////////////////////////////////////////////////
            # Mainloop: interleaved smem pipeline (gmem->smem) and register
            # pipeline (smem->rmem) with MMA computation.
            # ///////////////////////////////////////////////////////////////////////////////
            for k_tile in range(k_tile_count):
                for k_block in cutlass.range(num_k_block, unroll_full=True):
                    if k_block == num_k_block - 1:
                        tCsA_p = tCsA_copy_view[None, None, None, smem_pipe_read]
                        tCsB_p = tCsB_copy_view[None, None, None, smem_pipe_read]
                        cute.arch.cp_async_wait_group(num_smem_stages - 2)
                        cute.arch.sync_threads()

                    k_block_next = (k_block + 1) % num_k_block
                    cute.copy(
                        tiled_copy_s2r_A,
                        tCsA_p[None, None, k_block_next],
                        tCrA_copy_view[None, None, k_block_next],
                    )
                    cute.copy(
                        tiled_copy_s2r_B,
                        tCsB_p[None, None, k_block_next],
                        tCrB_copy_view[None, None, k_block_next],
                    )

                    if k_block == 0:
                        if k_tile + num_smem_stages - 1 < k_tile_count:
                            cute.copy(
                                tiled_copy_A,
                                tAgA[None, None, None, k_tile_index],
                                tAsA[None, None, None, smem_pipe_write],
                                pred=tApA,
                            )

                    cute.gemm(
                        tiled_mma,
                        tCrC,
                        tCrA[None, None, k_block],
                        tCrB[None, None, k_block],
                        tCrC,
                    )

                    if k_block == 0:
                        if k_tile + num_smem_stages - 1 < k_tile_count:
                            cute.copy(
                                tiled_copy_B,
                                tBgB[None, None, None, k_tile_index],
                                tBsB[None, None, None, smem_pipe_write],
                                pred=tBpB,
                            )
                        k_tile_index = k_tile_index + 1
                        cute.arch.cp_async_commit_group()
                        smem_pipe_write = smem_pipe_read
                        smem_pipe_read = smem_pipe_read + 1
                        if smem_pipe_read == num_smem_stages:
                            smem_pipe_read = 0

            cute.arch.cp_async_wait_group(0)
            cute.arch.sync_threads()

            # ///////////////////////////////////////////////////////////////////////////////
            # Epilogue: direct register to global memory (no smem buffer).
            # Unlike the FP16 tensorop_gemm which buffers through smem for
            # predicated stores, we skip smem to avoid a 64KB INT32 buffer
            # (128x128x4B) that would limit occupancy to 1 CTA/SM. Instead,
            # the run() function pads output tensors to tile boundaries.
            # ///////////////////////////////////////////////////////////////////////////////
            tCrD = cute.make_fragment_like(tCrC, self.c_dtype)
            tCrD[None] = epilogue_op(tCrC.load()).to(self.c_dtype)
            cute.autovec_copy(tCrD, tCgC)
        return

    def _make_smem_layout_AB(self, dtype, major_mode, copy_bits, smem_tiler):
        major_mode_size = (
            smem_tiler[1] if major_mode == utils.LayoutEnum.ROW_MAJOR else smem_tiler[0]
        )
        major_mode_size = 64 if major_mode_size >= 64 else major_mode_size

        swizzle_bits = int(math.log2(major_mode_size * dtype.width // copy_bits))
        swizzle_bits = min(swizzle_bits, 3)

        # MBase: log2 of elements per 128-bit copy
        # INT8: 128/8 = 16 elems -> MBase=4, F16: 128/16 = 8 elems -> MBase=3
        mbase = int(math.log2(copy_bits // dtype.width))
        # SShift must differ from MBase for actual swizzling (SShift==MBase is no-op)
        # Swizzle<2,4,3> is correct for INT8: 16-byte contiguity, 8-row atom
        sshift = 3

        layout_atom_outer = (
            cute.make_layout((8, major_mode_size), stride=(major_mode_size, 1))
            if major_mode == utils.LayoutEnum.ROW_MAJOR
            else cute.make_layout((major_mode_size, 8), stride=(1, major_mode_size))
        )
        layout_atom = cute.make_composed_layout(
            cute.make_swizzle(swizzle_bits, mbase, sshift),
            0,
            layout_atom_outer,
        )
        layout = cute.tile_to_shape(layout_atom, smem_tiler, (0, 1, 2))
        return layout

    def _make_gmem_tiled_copy_AB(self, atom_copy, dtype, major_mode, copy_bits):
        copy_elems = copy_bits // dtype.width
        shape_dim_1 = cute.size(self.bK) // copy_elems
        thread_layout = cute.make_layout(
            (self.num_threads // shape_dim_1, shape_dim_1), stride=(shape_dim_1, 1)
        )
        if major_mode != utils.LayoutEnum.ROW_MAJOR:
            shape_dim_0 = cute.size(self.bM) // copy_elems
            thread_layout = cute.make_layout(
                (shape_dim_0, self.num_threads // shape_dim_0), stride=(1, shape_dim_0)
            )
        value_layout = (
            cute.make_layout((1, copy_elems))
            if major_mode == utils.LayoutEnum.ROW_MAJOR
            else cute.make_layout((copy_elems, 1))
        )
        return cute.make_tiled_copy_tv(atom_copy, thread_layout, value_layout)

    def raster_tile(self, i, j, f):
        new_i = i // f
        new_j = (i % f) + (j * f)
        return (new_i, new_j)


def run(
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    mnkl: Tuple[int, int, int, int],
    atom_layout_mnk: Tuple[int, int, int] = None,
    use_k32: bool = False,
    a_major: str = "k",
    b_major: str = "k",
    c_major: str = "n",
    warmup_iterations: int = 2,
    iterations: int = 100,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    **kwargs,
):
    import torch
    import cutlass.torch as cutlass_torch

    M, N, K, L = mnkl

    # Auto-select tile size and atom layout based on M
    # (2,4,1)=8 warps best for M>=64 (fewer accum regs)
    # (2,2,1)=4 warps best for large M (2 CTAs/SM, better latency hiding)
    # (2,4,1) requires bm>=64 for correct gmem copy thread layout
    if M <= 16:
        bm, default_atom = 16, (1, 2, 1)
    elif M <= 32:
        bm, default_atom = 32, (2, 2, 1)
    elif M <= 64:
        bm, default_atom = 64, (2, 4, 1)
    elif M <= 256:
        bm, default_atom = 128, (2, 4, 1)
    else:
        bm, default_atom = 128, (2, 2, 1)
    if atom_layout_mnk is None:
        atom_layout_mnk = default_atom

    # INT8 requires K-major (row-major) inputs: ldmatrix needs 128-bit aligned
    # smem addresses, but column-major INT8 only gives 64-bit alignment.
    if a_major != "k":
        raise ValueError(
            f"A must be K-major (row-major) for INT8. Got a_major='{a_major}'. "
            "Column-major INT8 does not meet ldmatrix 128-bit alignment."
        )
    if b_major != "k":
        raise ValueError(
            f"B must be K-major (row-major) for INT8. Got b_major='{b_major}'. "
            "Column-major INT8 does not meet ldmatrix 128-bit alignment."
        )

    # Pad dimensions to tile boundaries for the unpredicated epilogue.
    # Input loads use predicates, but epilogue stores don't check bounds.
    bN = 128
    bK = 64
    M_pad = ((M + bm - 1) // bm) * bm
    N_pad = ((N + bN - 1) // bN) * bN
    K_pad = ((K + bK - 1) // bK) * bK

    print("Running Ampere INT8 tensor core GEMM example:")
    print(f"mnkl: {mnkl}, bm: {bm}, padded: ({M_pad}, {N_pad}, {K_pad})")
    print(
        f"A dtype: {a_dtype}, B dtype: {b_dtype}, C dtype: {c_dtype}, Acc dtype: {acc_dtype}"
    )
    print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
    print(f"Use k32 MMA: {use_k32}")
    print(f"Atoms layout: {atom_layout_mnk}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print(f"Use cold L2: {use_cold_l2}")

    # A(M,K) K-major, B(N,K) K-major, C(M,N) N-major
    def create_and_permute_tensor(l, mode0, mode1, is_mode0_major, dtype):
        shape = (l, mode1, mode0) if is_mode0_major else (l, mode0, mode1)
        permute_order = (2, 1, 0) if is_mode0_major else (1, 2, 0)
        torch_dtype = cutlass_torch.dtype(dtype)
        if dtype.signed:
            torch_tensor = torch.randint(-2, 3, shape, dtype=torch_dtype)
        else:
            torch_tensor = torch.randint(0, 5, shape, dtype=torch_dtype)
        torch_tensor = torch_tensor.permute(permute_order).cuda()
        cute_tensor = (
            from_dlpack(torch_tensor, assumed_align=16)
            .mark_layout_dynamic(leading_dim=(1 if not is_mode0_major else 0))
            .mark_compact_shape_dynamic(
                mode=(1 if not is_mode0_major else 0),
                stride_order=(2, 0, 1) if not is_mode0_major else (2, 1, 0),
                divisibility=(128 // dtype.width),
            )
        )
        return cute_tensor, torch_tensor

    # Create padded tensors; zero padding ensures MMA gets zeros for OOB elements.
    # Tensor shape after permute is always (mode0, mode1, L); majorness only
    # affects strides, so padding indexing is the same for any majorness.
    mA, a_torch = create_and_permute_tensor(L, M_pad, K_pad, a_major == "m", a_dtype)
    mB, b_torch = create_and_permute_tensor(L, N_pad, K_pad, b_major == "n", b_dtype)
    mC, c_torch = create_and_permute_tensor(L, M_pad, N_pad, c_major == "m", c_dtype)
    # Zero the padding regions of input tensors
    if M_pad > M:
        a_torch[M:, :, :] = 0
    if K_pad > K:
        a_torch[:, K:, :] = 0
        b_torch[:, K:, :] = 0
    if N_pad > N:
        b_torch[N:, :, :] = 0

    tensor_op_gemm = TensorOpGemmI8(
        a_dtype,
        b_dtype,
        c_dtype,
        acc_dtype,
        atom_layout_mnk,
        use_k32,
        bm,
    )

    print("Compiling kernel with cute.compile ...")
    compiled_gemm = cute.compile(tensor_op_gemm, mA, mB, mC)

    print("Executing GEMM kernel...")

    if not skip_ref_check:
        # torch.einsum doesn't support int on CUDA, compute on CPU
        # Use only the valid (non-padded) region for reference
        ref = torch.einsum(
            "mkl,nkl->mnl",
            a_torch[:M, :K, :].cpu().to(dtype=torch.int32),
            b_torch[:N, :K, :].cpu().to(dtype=torch.int32),
        ).to(cutlass_torch.dtype(c_dtype))
        compiled_gemm(mA, mB, mC)
        print("Verifying results...")
        torch.testing.assert_close(c_torch[:M, :N, :].cpu(), ref, atol=0, rtol=0)
        print("Results verified successfully!")

    def generate_tensors():
        a_workspace, _ = create_and_permute_tensor(L, M_pad, K_pad, a_major == "m", a_dtype)
        b_workspace, _ = create_and_permute_tensor(L, N_pad, K_pad, b_major == "n", b_dtype)
        c_workspace, _ = create_and_permute_tensor(L, M_pad, N_pad, c_major == "m", c_dtype)
        return testing.JitArguments(a_workspace, b_workspace, c_workspace)

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_torch.numel() * a_torch.element_size()
            + b_torch.numel() * b_torch.element_size()
            + c_torch.numel() * c_torch.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    avg_time_us = testing.benchmark(
        compiled_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        use_cuda_graphs=False,
    )

    return avg_time_us


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser(
        description="INT8 tensor core GEMM with CuTe DSL on Ampere GPU"
    )
    parser.add_argument(
        "--mnkl", type=parse_comma_separated_ints, default=(128, 128, 128, 1)
    )
    parser.add_argument(
        "--atom_layout_mnk", type=parse_comma_separated_ints, default=None
    )
    parser.add_argument(
        "--a_dtype",
        type=cutlass.dtype,
        choices=[cutlass.Int8, cutlass.Uint8],
        default=cutlass.Int8,
    )
    parser.add_argument(
        "--b_dtype",
        type=cutlass.dtype,
        choices=[cutlass.Int8, cutlass.Uint8],
        default=cutlass.Int8,
    )
    parser.add_argument(
        "--acc_dtype",
        type=cutlass.dtype,
        choices=[cutlass.Int32],
        default=cutlass.Int32,
    )
    parser.add_argument(
        "--c_dtype",
        type=cutlass.dtype,
        choices=[cutlass.Int32],
        default=cutlass.Int32,
    )
    parser.add_argument("--use_k32", action="store_true", default=False)
    parser.add_argument("--a_major", choices=["k", "m"], default="k")
    parser.add_argument("--b_major", choices=["k", "n"], default="k")
    parser.add_argument("--c_major", choices=["n", "m"], default="n")
    parser.add_argument("--warmup_iterations", default=2, type=int)
    parser.add_argument("--iterations", default=100, type=int)
    parser.add_argument("--skip_ref_check", action="store_true")
    parser.add_argument(
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )

    args = parser.parse_args()
    run(
        args.a_dtype,
        args.b_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.mnkl,
        args.atom_layout_mnk,
        args.use_k32,
        args.a_major,
        args.b_major,
        args.c_major,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
    )
    print("PASS")
