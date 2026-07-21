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
from functools import lru_cache
from typing import Tuple, Type

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass import testing
import cutlass.utils as utils
from cutlass.utils.tensor_helpers import create_cute_tensor_for_fp8
from cutlass.utils.tensor_helpers import is_fp8_dtype

"""
A dense GEMM (C = A * B) example for the NVIDIA Ampere architecture using CUTE DSL.
- Matrix A is MxKxL, L is batch dimension, A can be row-major("K") or column-major("M")
- Matrix B is NxKxL, L is batch dimension, B can be row-major("N") or column-major("K")
- Matrix C is MxNxL, L is batch dimension, C can be row-major("N") or column-major("M")

This GEMM kernel supports the following features:
    - Utilizes Ampere's tensor cores for matrix multiply-accumulate (MMA) operations
    - Threadblock rasterization to improve data re-use
    - Supports multi-stage pipeline to overlap computation and memory access
    - Implements shared memory buffering for epilogue to increase coalesced global memory access

This GEMM works as follows:
1. Load A and B matrices from global memory (GMEM) to shared memory (SMEM) using asynchronous copies.
2. Perform matrix multiply-accumulate (MMA) operations.
3. Store results from registers (RMEM) to shared memory (SMEM), then to global memory (GMEM).

The Ampere tensor core instruction used operates as follows:
- Read matrix A from SMEM
- Read matrix B from SMEM
- Perform MMA operation and store the result in Accumulator(register)

To run this example:

.. code-block:: bash

    python examples/cute/ampere/kernel/dense_gemm/tensorop_gemm.py                                  \
      --mnkl 8192,8192,8192,1 --atom_layout_mnk 2,2,1                        \
      --ab_dtype Float16                                                     \
      --c_dtype Float16 --acc_dtype Float32                                  \
      --a_major m --b_major n --c_major n

The above example command computes with M=8192, N=8192, K=8192,
batch_count=1. The atom layout's shape is 2x2x1 and the input, mma
accumulator, and output data type are set as fp16, fp32 and fp16,
respectively.

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/cute/ampere/kernel/dense_gemm/tensorop_gemm.py                              \
      --mnkl 8192,8192,8192,1 --atom_layout_mnk 2,2,1                        \
      --ab_dtype Float16                                                     \
      --c_dtype Float16 --acc_dtype Float32                                  \
      --a_major m --b_major n --c_major n                                    \
      --skip_ref_check --iterations 2

Constraints:
* Supported input data types: fp16/bf16/fp8
* Supported output data types: fp16
* Support accumulator data types: f32/f16
* Default tile shape is 128x128x32 for fp16/bf16 and 128x128x64 for fp8
* Atom layout's MNK shape is set so that tile shape can be divided by MMA
  instruction shape
* The contiguous dimension of A/B/C tensors must be at least 16 bytes aligned,
  i.e, number of elements is a multiple of 8
"""


class TensorOpGemm:
    _FP16_BF16_DTYPES = (cutlass.Float16, cutlass.BFloat16)
    _FP8_DTYPES = (cutlass.Float8E4M3FN, cutlass.Float8E5M2)
    _MMA_SHAPE_FP16_BF16 = (16, 8, 16)
    _MMA_SHAPE_FP8 = (16, 8, 32)
    _CTA_TILER_FP16_BF16 = (128, 128, 32)
    _CTA_TILER_FP8 = (128, 128, 64)

    def __init__(
        self,
        ab_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        atom_layout_mnk: Tuple[int, int, int],
        is_m_major_c: bool = False,
    ):
        self.ab_dtype = ab_dtype
        self.c_dtype = c_dtype
        self.acc_dtype = acc_dtype
        self.is_fp8 = self.ab_dtype in self._FP8_DTYPES
        assert self.ab_dtype in self._FP16_BF16_DTYPES + self._FP8_DTYPES, (
            "ab_dtype must be one of Float16, BFloat16, Float8E4M3FN, Float8E5M2"
        )
        self.cta_tiler = (
            self._CTA_TILER_FP8 if self.is_fp8 else self._CTA_TILER_FP16_BF16
        )
        self.num_stages = 4
        self.atom_layout_mnk = atom_layout_mnk
        atom_lay_M, atom_lay_N, atom_lay_K = self.atom_layout_mnk
        self.num_threads = atom_lay_M * atom_lay_N * atom_lay_K * 32

        self.bM, self.bN, self.bK = self.cta_tiler
        self.mma_inst_shape = (
            self._MMA_SHAPE_FP8 if self.is_fp8 else self._MMA_SHAPE_FP16_BF16
        )
        mmaM, mmaN, mmaK = self.mma_inst_shape

        # M-major C uses C^T = B^T * A^T, swapping atom layout M/N roles.
        if is_m_major_c:
            assert self.bM % (atom_lay_N * mmaM) == 0, (
                "bM must be divisible by MMA instruction"
            )
            assert self.bN % (atom_lay_M * mmaN) == 0, (
                "bN must be divisible by MMA instruction"
            )
        else:
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
        stream: cuda.CUstream,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        # The grid divides the problems's M, N, and L dimensions by the
        # respective modes of the tile shape (bM, bN, 1). The K dimension is
        # handled within a block via a multistage process.

        # The Ampere MMA atom's accumulator layout writes M along the row
        # dimension. When C is column-major (M-major), the accumulator does
        # not naturally align with the contiguous dimension of C, so storing
        # the result requires non-coalesced register/SMEM traffic. To avoid
        # this we can compute C^T = B^T * A^T instead of C = A * B:
        if cutlass.const_expr(
            utils.LayoutEnum.from_tensor(mC) == utils.LayoutEnum.COL_MAJOR
        ):
            mA, mB = mB, mA
            mC = cute.make_tensor(mC.iterator, cute.select(mC.layout, mode=[1, 0, 2]))
            atom_layout_mnk = (
                self.atom_layout_mnk[1],
                self.atom_layout_mnk[0],
                self.atom_layout_mnk[2],
            )
        else:
            atom_layout_mnk = self.atom_layout_mnk

        self.a_major_mode = utils.LayoutEnum.from_tensor(mA)
        self.b_major_mode = utils.LayoutEnum.from_tensor(mB)
        self.c_major_mode = utils.LayoutEnum.from_tensor(mC)

        # ///////////////////////////////////////////////////////////////////////////////
        # Shared memory layout:
        # ///////////////////////////////////////////////////////////////////////////////

        # Creates a layout with the size required for the provided tile
        # size and num stages (stages are used for K dimension) that is also
        # sectioned into 64x8 or 8x32 layout atoms. The swizzle is set so that
        # the atom for the shared memory -> register copy does not encounter
        # bank conflicts

        # assume the input is 16B align
        ab_copy_bits = 128
        sA_layout, sA_swizzle = self._make_smem_layout_AB(
            mA.element_type,
            self.a_major_mode,
            ab_copy_bits,
            (self.cta_tiler[0], self.cta_tiler[2], self.num_stages),
        )
        sB_layout, sB_swizzle = self._make_smem_layout_AB(
            mB.element_type,
            self.b_major_mode,
            ab_copy_bits,
            (self.cta_tiler[1], self.cta_tiler[2], self.num_stages),
        )

        # Creates a similar layout but without num_stages or layout atoms
        sC_layout = self._make_smem_layout_C(
            mC.element_type,
            self.c_major_mode,
            ab_copy_bits,
            (self.cta_tiler[0], self.cta_tiler[1]),
        )

        # ///////////////////////////////////////////////////////////////////////////////
        # Tiled copy:
        # The majorness of tA/tB/tC follows the majorness of gA/gB/gC,
        # enabling merged accesses to global memory for faster data
        # transfer between global and shared memory.
        # ///////////////////////////////////////////////////////////////////////////////

        # Create a copy atom for a global to shared memory asynchronous copy
        atom_async_copy = cute.make_copy_atom(
            cute.nvgpu.cpasync.CopyG2SOp(cache_mode=cute.nvgpu.LoadCacheMode.GLOBAL),
            mA.element_type,
            num_bits_per_copy=ab_copy_bits,
        )

        # Create thread layouts for tiled copy from the copy atom where the
        # thread layout simply follows the leading dimension of the tensor
        tiled_copy_A = self._make_gmem_tiled_copy_AB(
            atom_async_copy, mA.element_type, self.a_major_mode, ab_copy_bits
        )
        tiled_copy_B = self._make_gmem_tiled_copy_AB(
            atom_async_copy, mB.element_type, self.b_major_mode, ab_copy_bits
        )

        # Creates a synchronous copy atom and thread layouts for the epilogue
        c_copy_bits = 128
        atom_sync_copy = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            mC.element_type,
            num_bits_per_copy=c_copy_bits,
        )
        tiled_copy_C = self._make_gmem_tiled_copy_C(
            atom_sync_copy, mC.element_type, self.c_major_mode, c_copy_bits
        )

        # ///////////////////////////////////////////////////////////////////////////////
        # Tiled MMA
        # ///////////////////////////////////////////////////////////////////////////////

        if cutlass.const_expr(self.is_fp8):
            op = cute.nvgpu.warp.MmaFP8Op(
                self.ab_dtype, self.acc_dtype, self.mma_inst_shape
            )
        else:
            op = cute.nvgpu.warp.MmaF16BF16Op(
                self.ab_dtype, self.acc_dtype, self.mma_inst_shape
            )

        permutation_mnk = (
            atom_layout_mnk[0] * self.mma_inst_shape[0],
            # if atom layout's N-mode is 1, to leverage the largest coalesced
            # shared memory -> register copy, set the tiled mma's N mode to 16
            atom_layout_mnk[1] * self.mma_inst_shape[1] * 2,
            atom_layout_mnk[2] * self.mma_inst_shape[2],
        )

        # Created a tiled mma that tiles the atom according to specified layout.
        # For a 2x2x1 atom layout, the mma atom is duplicated 4 times, twice
        # across M and twice across N
        tC = cute.make_layout(atom_layout_mnk)
        tiled_mma = cute.make_tiled_mma(
            op,
            tC,
            permutation_mnk=permutation_mnk,
        )

        # grid_dim: ((m + BLK_M - 1) // BLK_M, (n + BLK_N - 1) // BLK_N, l)
        grid_dim = cute.ceil_div(mC.shape, (self.bM, self.bN, 1))

        # Add threadblock rasterization to improve re-use of data
        raster_factor = 1
        grid_dim_n = cute.size(grid_dim[1])
        # Thresholds picked so that it doesn't cause too many no-op CTAs
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
            sA_swizzle,
            sB_layout,
            sB_swizzle,
            sC_layout,
            tiled_copy_A,
            tiled_copy_B,
            tiled_copy_C,
            tiled_mma,
            raster_factor,
            epilogue_op,
        ).launch(
            grid=rasterization_remap_grid_dim,
            block=[self.num_threads, 1, 1],
            stream=stream,
        )

    @cute.kernel
    def kernel(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mC: cute.Tensor,
        sA_layout: cute.Layout,
        sA_swizzle: cute.Swizzle,
        sB_layout: cute.Layout,
        sB_swizzle: cute.Swizzle,
        sC_layout: cute.ComposedLayout,
        tiled_copy_A: cute.TiledCopy,
        tiled_copy_B: cute.TiledCopy,
        tiled_copy_C: cute.TiledCopy,
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
            # gA: (BLK_M, BLK_N, k), gB: (BLK_N, BLK_K, k), gC: (BLK_M, BLK_N)
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

            # By default, if the tensor k mode does not divide into the tile k
            # size, then last tiles in the k dimension are irregular.
            # Instead, make the first tiles irregular when k is irregular.
            # This allows us to handle the irregular tile first to avoid
            # checking for this condition within the mainloop.

            # residual_k is a negative number indicating the amount needed to
            # shift the pointer by in dimension k
            residual_k = cute.size(mA, mode=[1]) - cutlass.Int32(self.bK) * cute.size(
                gA, mode=[2]
            )

            # move the pointer of gA/gB in the `-k` direction
            gA = cute.domain_offset((0, residual_k, 0), gA)
            gB = cute.domain_offset((0, residual_k, 0), gB)
            # input is 16B aligned
            gA = cute.make_tensor(gA.iterator.align(16), gA.layout)
            gB = cute.make_tensor(gB.iterator.align(16), gB.layout)

            # Construct identity layout for sA and sB (mirrors global tensors,
            # used for predication only)
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
            # Create shared memory buffers and get the appropriate fragments for this thread.
            # sA:   (BLK_M, BLK_K, PIPE)       , sB:   (BLK_N, BLK_K, PIPE)
            # tAgA: (CPY, CPY_M, CPY_K, k)     , tBgB: (CPY, CPY_N, CPY_K, k)
            # tAsA: (CPY, CPY_M, CPY_K, PIPE)  , tBsB: (CPY, CPY_N, CPY_K, PIPE)
            # ///////////////////////////////////////////////////////////////////////////////
            @cute.struct
            class SharedStorageAB:
                a: cute.struct.Align[
                    cute.struct.MemRange[mA.element_type, cute.cosize(sA_layout)],
                    16,
                ]
                b: cute.struct.Align[
                    cute.struct.MemRange[mB.element_type, cute.cosize(sB_layout)],
                    16,
                ]

            @cute.struct
            class SharedStorageC:
                c: cute.struct.Align[
                    cute.struct.MemRange[mC.element_type, cute.cosize(sC_layout)],
                    16,
                ]

            # Shared memory buffer
            smem = cutlass.utils.SmemAllocator()
            # Shared memory allocated for operations with A, B will be
            # overwritten for operations on C. This is to improve performance
            # by reducing the size of shared memory requested by each block
            storage = smem.allocate(
                max(SharedStorageAB.size_in_bytes(), SharedStorageC.size_in_bytes()),
                byte_alignment=16,
            )
            sA = SharedStorageAB(storage).a.get_tensor(sA_layout, swizzle=sA_swizzle)
            sB = SharedStorageAB(storage).b.get_tensor(sB_layout, swizzle=sB_swizzle)
            sC = SharedStorageC(storage).c.get_tensor(sC_layout)

            thr_copy_A = tiled_copy_A.get_slice(tidx)
            thr_copy_B = tiled_copy_B.get_slice(tidx)
            thr_copy_C = tiled_copy_C.get_slice(tidx)
            tAgA = thr_copy_A.partition_S(gA)
            tAsA = thr_copy_A.partition_D(sA)
            tBgB = thr_copy_B.partition_S(gB)
            tBsB = thr_copy_B.partition_D(sB)
            tCsC_epilogue = thr_copy_C.partition_S(sC)
            tCgC_epilogue = thr_copy_C.partition_D(gC)

            # Repeat the partitioning with identity layouts
            tAcA = thr_copy_A.partition_S(cA)
            tBcB = thr_copy_B.partition_S(cB)

            # ///////////////////////////////////////////////////////////////////////////////
            # Predicate: Mark indices that need to copy when problem_shape isn't a multiple
            # of tile_shape
            # ///////////////////////////////////////////////////////////////////////////////

            # For predication over the tensors A (M/K), B (N/K), and (in the
            # epilogue) C (M/N), we will compute it in a fashion similar to an
            # outer product. The predication along one of the dimensions is
            # evaluated and stored in a predication tensor. Then, the
            # predication for the remaining dimension is handled later via an
            # if/else branch at the copy.
            # For A and B, predication booleans along M/N are stored in a
            # predication tensor and along K is handled via a if/else branch.

            # Allocate predicate tensors for M and N. Predication is checked
            # at the granularity of a copy atom, so the predicate tensor does not
            # need separate booleans for individual elements within a copy
            # atom (for example, the elements of tAgA.shape[0][0].)
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
            # Set predicates for M/N bounds
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
            # Prefetch Prologue
            # ///////////////////////////////////////////////////////////////////////////////
            # Clear the smem tiles to account for predicated off loads
            tAsA.fill(0)
            tBsB.fill(0)
            cute.arch.sync_threads()
            # Start async loads for the first k-tile. Here we take care of the k residue
            # via if/else check along the k dimension. Because we shifted the identity tensor
            # by the residue_k and because the identity tensor is a coord tensor, the
            # values of any identity tensor element that is poison is less than -1
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

            # Start async loads for rest of the k-tiles
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
            tCsC = thr_mma.partition_C(sC)
            tCgC = thr_mma.partition_C(gC)
            tCrA = tiled_mma.make_fragment_A(tCsA[None, None, None, 0])
            tCrB = tiled_mma.make_fragment_B(tCsB[None, None, None, 0])
            tCrC = tiled_mma.make_fragment_C(tCgC)
            # Clear the accumulator
            tCrC.fill(0.0)

            # ///////////////////////////////////////////////////////////////////////////////
            # Copy Atom A/B retiling
            # ///////////////////////////////////////////////////////////////////////////////

            # Create the copy atoms for the copy from shared memory to register
            if cutlass.const_expr(self.is_fp8):
                if cutlass.const_expr(self.a_major_mode == utils.LayoutEnum.ROW_MAJOR):
                    atom_copy_s2r_A = cute.make_copy_atom(
                        cute.nvgpu.warp.LdMatrix8x16x8bOp(False, 4),
                        mA.element_type,
                    )
                else:
                    atom_copy_s2r_A = cute.make_copy_atom(
                        cute.nvgpu.CopyUniversalOp(),
                        mA.element_type,
                        num_bits_per_copy=8,
                    )
                if cutlass.const_expr(self.b_major_mode == utils.LayoutEnum.ROW_MAJOR):
                    atom_copy_s2r_B = cute.make_copy_atom(
                        cute.nvgpu.warp.LdMatrix8x16x8bOp(False, 4),
                        mB.element_type,
                    )
                else:
                    atom_copy_s2r_B = cute.make_copy_atom(
                        cute.nvgpu.CopyUniversalOp(),
                        mB.element_type,
                        num_bits_per_copy=8,
                    )
            else:
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

            # Creates the tiled copy so that it matches the thread-value layout
            # expected by the tiled mma
            tiled_copy_s2r_A = cute.make_tiled_copy_A(atom_copy_s2r_A, tiled_mma)
            tiled_copy_s2r_B = cute.make_tiled_copy_B(atom_copy_s2r_B, tiled_mma)

            thr_copy_ldmatrix_A = tiled_copy_s2r_A.get_slice(tidx)
            thr_copy_ldmatrix_B = tiled_copy_s2r_B.get_slice(tidx)
            tCsA_copy_view = thr_copy_ldmatrix_A.partition_S(sA)
            tCrA_copy_view = thr_copy_ldmatrix_A.retile(tCrA)
            tCsB_copy_view = thr_copy_ldmatrix_B.partition_S(sB)
            tCrB_copy_view = thr_copy_ldmatrix_B.retile(tCrB)

            # Current pipe index in smem to read from / write to
            smem_pipe_read = 0
            smem_pipe_write = num_smem_stages - 1

            tCsA_p = tCsA_copy_view[None, None, None, smem_pipe_read]
            tCsB_p = tCsB_copy_view[None, None, None, smem_pipe_read]

            # ///////////////////////////////////////////////////////////////////////////////
            # PREFETCH register pipeline
            # ///////////////////////////////////////////////////////////////////////////////
            num_k_block = cute.size(tCrA, mode=[2])
            if num_k_block > 1:
                # Wait until our first prefetched tile is loaded in
                cute.arch.cp_async_wait_group(num_smem_stages - 2)
                cute.arch.sync_threads()
                # Prefetch the first k-block rmem from the first k-tile
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
            # Mainloop
            # 1. Shared memory pipeline (gmem -> smem):
            #    The default smem pipeline depth is 3, meaning that for shared
            # memory buffers, we allocate three times the size described by the
            # CTA tiler. We prefetch 2 of these buffers before entering the main
            # loop. Considering only the transfer from global memory to shared
            # memory, the general structure of the mainloop is:
            #   (1) copy k-tile from gmem to smem;
            #   (2) perform gemm computation on k-tile;
            #   (3) wait for the next copy to finish.
            #    The `cute.arch.cp_async_wait_group(num_smem_stages - 2)` command
            # waits for the number of unfinished 'copy' to be <= 1. The advantage
            # of this approach is that it allows for simultaneous production
            # (i.e., step (1)) and consumption (i.e., step (2)) of smem.
            #    A common misconception is to prefetch N buffers and rewrite
            # the pipeline logic to wait on N-1 pending copies. The disadvantage
            # of this approach is that it requires fully consuming a buffer in
            # order to open an empty buffer for the next copy.
            # 2. Register pipeline (smem -> register):
            #    Similarly, the register pipeline produces i+1, consumes i, and
            # produces i+2... Notably, i and i+1 do not use the same register,
            # eliminating dependencies on the same register for better parallelism.
            # 3. Combining the smem and register pipelines results in the mainloop.
            # ///////////////////////////////////////////////////////////////////////////////
            for k_tile in range(k_tile_count):
                for k_block in cutlass.range(num_k_block, unroll_full=True):
                    if k_block == num_k_block - 1:
                        tCsA_p = tCsA_copy_view[None, None, None, smem_pipe_read]
                        tCsB_p = tCsB_copy_view[None, None, None, smem_pipe_read]
                        cute.arch.cp_async_wait_group(num_smem_stages - 2)
                        cute.arch.sync_threads()

                    # Load A, B from shared memory to registers for k_block + 1
                    k_block_next = (k_block + 1) % num_k_block  # static
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

                    # Fetch next A and B and update smem pipeline read/write
                    if k_block == 0:
                        if k_tile + num_smem_stages - 1 < k_tile_count:
                            cute.copy(
                                tiled_copy_A,
                                tAgA[None, None, None, k_tile_index],
                                tAsA[None, None, None, smem_pipe_write],
                                pred=tApA,
                            )
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

                    # Thread-level register gemm for k_block
                    cute.gemm(
                        tiled_mma,
                        tCrC,
                        tCrA[None, None, k_block],
                        tCrB[None, None, k_block],
                        tCrC,
                    )

            # Sync before epilogue
            cute.arch.cp_async_wait_group(0)
            cute.arch.sync_threads()

            # ///////////////////////////////////////////////////////////////////////////////
            # Epilogue with fusion
            # ///////////////////////////////////////////////////////////////////////////////
            tCrD = cute.make_fragment_like(tCrC, self.c_dtype)
            tCrD[None] = epilogue_op(tCrC.load()).to(self.c_dtype)

            # Copy results of D back to shared memory
            cute.autovec_copy(tCrD, tCsC)

            # Create coord tensor for C
            ceilM, ceilN, _ = cute.ceil_div(mC.shape, (self.bM, self.bN, 1))
            mcC = cute.make_identity_tensor(
                (
                    cute.size(ceilM) * self.cta_tiler[0],
                    cute.size(ceilN) * self.cta_tiler[1],
                    1,
                )
            )
            cC = cute.local_tile(
                mcC[None, None, bidz],
                tiler=self.cta_tiler,
                coord=tiler_coord,
                proj=(1, 1, None),
            )
            tCcC = thr_copy_C.partition_S(cC)

            tCrC_epilogue = cute.make_fragment_like(tCsC_epilogue)
            # Wait for all writes to shared memory to finish before starting copies
            # using the new layouts
            cute.arch.sync_threads()
            cute.autovec_copy(tCsC_epilogue, tCrC_epilogue)

            # Create predication tensor for m
            tCpC = cute.make_rmem_tensor(
                cute.make_layout(
                    (
                        tCgC_epilogue.shape[0][1],
                        cute.size(tCgC_epilogue, mode=[1]),
                        cute.size(tCgC_epilogue, mode=[2]),
                    ),
                    stride=(cute.size(tCgC_epilogue, mode=[1]), 1, 0),
                ),
                cutlass.Boolean,
            )
            for rest_v in range(tCpC.shape[0]):
                for m in range(tCpC.shape[1]):
                    tCpC[rest_v, m, 0] = cute.elem_less(
                        tCcC[(0, rest_v), m, 0][0], mC.shape[0]
                    )

            # Copy to global memory using better vectorization
            for rest_v in range(tCpC.shape[0]):
                for n in range(tCpC.shape[2]):
                    if cute.elem_less(tCcC[(0, rest_v), 0, n][1], mC.shape[1]):
                        cute.copy(
                            tiled_copy_C,
                            tCrC_epilogue[None, None, n],
                            tCgC_epilogue[None, None, n],
                            pred=tCpC[None, None, n],
                        )
        return

    def _make_smem_layout_AB(self, dtype, major_mode, copy_bits, smem_tiler):
        major_mode_size = (
            smem_tiler[1] if major_mode == utils.LayoutEnum.ROW_MAJOR else smem_tiler[0]
        )
        # Cap at 128 bytes (fp16: 64 elems, fp8: 128 elems)
        max_elems = 128 * 8 // dtype.width
        major_mode_size = min(major_mode_size, max_elems)

        swizzle_bits = int(math.log2(major_mode_size * dtype.width // copy_bits))
        swizzle_bits = min(swizzle_bits, 3)
        # PDSL: base_bits is in bytes (copy_bits / 8), not in elements
        base_bits = int(math.log2(copy_bits // 8))

        shift_bits = int(math.log2(copy_bits // dtype.width))
        swizzle = cute.make_swizzle(swizzle_bits, base_bits, shift_bits)

        layout_atom_outer = (
            cute.make_layout((8, major_mode_size), stride=(major_mode_size, 1))
            if major_mode == utils.LayoutEnum.ROW_MAJOR
            else cute.make_layout((major_mode_size, 8), stride=(1, major_mode_size))
        )
        layout = cute.tile_to_shape(layout_atom_outer, smem_tiler, (0, 1, 2))
        return layout, swizzle

    def _make_smem_layout_C(self, dtype, major_mode, copy_bits, smem_tiler):
        major_mode_size = (
            smem_tiler[1] if major_mode == utils.LayoutEnum.ROW_MAJOR else smem_tiler[0]
        )

        swizzle_bits = int(math.log2(major_mode_size * dtype.width // copy_bits))
        swizzle_bits = min(swizzle_bits, 3)

        layout_atom_outer = (
            cute.make_layout((8, major_mode_size), stride=(major_mode_size, 1))
            if major_mode == utils.LayoutEnum.ROW_MAJOR
            else cute.make_layout((major_mode_size, 8), stride=(1, major_mode_size))
        )
        layout_atom = cute.make_composed_layout(
            cute.make_swizzle(swizzle_bits, 3, 4),
            0,
            layout_atom_outer,
        )

        # Due to the thread layout of the mma, remove swizzle in C to
        # prevent shared memory fragments owned by an single thread from
        # holding swizzles
        if major_mode == utils.LayoutEnum.COL_MAJOR:
            layout_atom = cute.make_composed_layout(
                cute.make_swizzle(0, 3, 4), 0, layout_atom_outer
            )
        layout = cute.tile_to_shape(
            layout_atom,
            smem_tiler,
            (0, 1),
        )
        return layout

    def _make_gmem_tiled_copy_AB(self, atom_copy, dtype, major_mode, copy_bits):
        copy_elems = copy_bits // dtype.width
        shape_dim_1 = cute.size(self.bK) // copy_elems
        # thread layout for copy
        thread_layout = cute.make_layout(
            (self.num_threads // shape_dim_1, shape_dim_1), stride=(shape_dim_1, 1)
        )
        if major_mode != utils.LayoutEnum.ROW_MAJOR:
            shape_dim_0 = cute.size(self.bM) // copy_elems
            thread_layout = cute.make_layout(
                (shape_dim_0, self.num_threads // shape_dim_0), stride=(1, shape_dim_0)
            )
        # Value layout for copy
        value_layout = (
            cute.make_layout((1, copy_elems))
            if major_mode == utils.LayoutEnum.ROW_MAJOR
            else cute.make_layout((copy_elems, 1))
        )
        return cute.make_tiled_copy_tv(atom_copy, thread_layout, value_layout)

    def _make_gmem_tiled_copy_C(self, atom_copy, dtype, major_mode, copy_bits):
        copy_elems = copy_bits // dtype.width
        shape_dim_1 = cute.size(self.bN) // copy_elems
        # thread layout for copy
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


@cute.jit
def bmm(
    gemm_op: cutlass.Constexpr,
    a: cute.Tensor,  # (l, m, k)
    b: cute.Tensor,  # (l, k, n)
    c: cute.Tensor,  # (l, m, n)
    stream: cuda.CUstream,
    epilogue_op: cutlass.Constexpr = lambda x: x,
):
    """
    Wrapper API for GEMM kernel to follow the convention of PyTorch's batch matrix-multiply (bmm).

    Internally, the tensors are permuted to match CuTe's convention:
      - a: (m, k, l)
      - b: (n, k, l)
      - c: (m, n, l)

    :param gemm_op: Kernel operation, expects (a, b, c, stream, epilogue_op)
    :type gemm_op: cutlass.Constexpr
    :param a: Input tensor of shape (l, m, k)
    :type a: cute.Tensor
    :param b: Input tensor of shape (l, k, n)
    :type b: cute.Tensor
    :param c: Output tensor of shape (l, m, n)
    :type c: cute.Tensor
    :param stream: CUDA stream for asynchronous execution
    :type stream: cuda.CUstream
    :param epilogue_op: Optional elementwise lambda function to apply per output element, defaults to identity
    :type epilogue_op: cutlass.Constexpr, optional
    """
    # (l,m,k) -> (m,k,l)
    a = cute.make_tensor(a.iterator, cute.select(a.layout, mode=[1, 2, 0]))
    # (l,k,n) -> (n,k,l)
    b = cute.make_tensor(b.iterator, cute.select(b.layout, mode=[2, 1, 0]))
    # (l,m,n) -> (m,n,l)
    c = cute.make_tensor(c.iterator, cute.select(c.layout, mode=[1, 2, 0]))

    gemm_op(a, b, c, stream, epilogue_op)


@lru_cache(maxsize=1)
def prepare_tensors(
    mnkl: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    init_random: bool = True,
):
    """
    Prepare input and output tensors for the GEMM operation.

    :param mnkl: Problem size as a tuple (M, N, K, L).
    :type mnkl: Tuple[int, int, int, int]
    :param ab_dtype: Data type for input tensors A and B.
    :type ab_dtype: Type[cutlass.Numeric]
    :param c_dtype: Data type for output tensor C.
    :type c_dtype: Type[cutlass.Numeric]
    :param a_major: Major dimension of the A tensor layout ("m" or "k").
    :type a_major: str
    :param b_major: Major dimension of the B tensor layout ("n" or "k").
    :type b_major: str
    :param c_major: Major dimension of the C tensor layout ("m" or "n").
    :type c_major: str
    :param init_random: Whether to initialize tensors with random values, defaults to True.
    :type init_random: bool, optional

    :return: Tuple of (a, b, c) torch tensors.
    :rtype: Tuple[torch.Tensor, torch.Tensor, torch.Tensor]
    """
    import torch
    from cutlass.torch import dtype as torch_dtype

    m, n, k, l = mnkl

    if a_major == "k":
        a = torch.empty((l, m, k), dtype=torch.float32, device="cuda")
    elif a_major == "m":
        a = torch.empty((l, k, m), dtype=torch.float32, device="cuda").permute(0, 2, 1)

    if b_major == "n":
        b = torch.empty((l, k, n), dtype=torch.float32, device="cuda")
    elif b_major == "k":
        b = torch.empty((l, n, k), dtype=torch.float32, device="cuda").permute(0, 2, 1)

    if c_major == "n":
        c = torch.empty((l, m, n), dtype=torch.float32, device="cuda")
    elif c_major == "m":
        c = torch.empty((l, n, m), dtype=torch.float32, device="cuda").permute(0, 2, 1)

    if init_random:
        a.random_(-2, 3)
        b.random_(-2, 3)
        c.random_(-2, 3)

    # For fp8 types, use uint8 as storage to avoid dlpack limitation
    a_storage_dtype = torch.uint8 if is_fp8_dtype(ab_dtype) else torch_dtype(ab_dtype)
    b_storage_dtype = torch.uint8 if is_fp8_dtype(ab_dtype) else torch_dtype(ab_dtype)
    c_storage_dtype = torch.uint8 if is_fp8_dtype(c_dtype) else torch_dtype(c_dtype)

    return (
        a.to(dtype=a_storage_dtype),
        b.to(dtype=b_storage_dtype),
        c.to(dtype=c_storage_dtype),
        a.clone(),  # fp32 source for fp8 conversion
        b.clone(),  # fp32 source for fp8 conversion
        c.clone(),  # fp32 source for fp8 conversion
    )


def mark_dynamic_layout(
    a,
    b,
    c,
    leading_dim_a: int,
    leading_dim_b: int,
    leading_dim_c: int,
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    a_f32=None,
    b_f32=None,
    c_f32=None,
):
    a_ = create_cute_tensor_for_fp8(a, ab_dtype, leading_dim_a, source_f32_tensor=a_f32)
    b_ = create_cute_tensor_for_fp8(b, ab_dtype, leading_dim_b, source_f32_tensor=b_f32)
    c_ = create_cute_tensor_for_fp8(c, c_dtype, leading_dim_c, source_f32_tensor=c_f32)

    a_.mark_compact_shape_dynamic(
        mode=leading_dim_a,
        stride_order=(0, 1, 2) if leading_dim_a == 2 else (0, 2, 1),
        divisibility=128 // ab_dtype.width,
    )
    b_.mark_compact_shape_dynamic(
        mode=leading_dim_b,
        stride_order=(0, 1, 2) if leading_dim_b == 2 else (0, 2, 1),
        divisibility=128 // ab_dtype.width,
    )
    c_.mark_compact_shape_dynamic(
        mode=leading_dim_c,
        stride_order=(0, 1, 2) if leading_dim_c == 2 else (0, 2, 1),
        divisibility=128 // c_dtype.width,
    )
    return a_, b_, c_


@lru_cache(maxsize=1)
def compile_bmm(
    mnkl: Tuple[int, int, int, int],
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    atom_layout_mnk: Tuple[int, int, int],
    epilogue_op: cutlass.Constexpr = lambda x: x,
):
    """
    Compile the BMM kernel with caching.

    :param mnkl: Problem size as a tuple (M, N, K, L).
    :type mnkl: Tuple[int, int, int, int]
    :param a: Input tensor A.
    :type a: cute.Tensor
    :param b: Input tensor B.
    :type b: cute.Tensor
    :param c: Output tensor C.
    :type c: cute.Tensor
    :param ab_dtype: Data type for input tensors A and B.
    :type ab_dtype: Type[cutlass.Numeric]
    :param c_dtype: Data type for output tensor C.
    :type c_dtype: Type[cutlass.Numeric]
    :param acc_dtype: Accumulator data type.
    :type acc_dtype: Type[cutlass.Numeric]
    :param atom_layout_mnk: Atom layout shape (M, N, K).
    :type atom_layout_mnk: Tuple[int, int, int]
    :param epilogue_op: Optional elementwise lambda function to apply to the output tensor.
    :type epilogue_op: cutlass.Constexpr, optional

    :return: Compiled kernel function.
    """
    from cutlass.cute.runtime import make_fake_stream

    stream = make_fake_stream()

    is_m_major_c = c.leading_dim == 0
    gemm = TensorOpGemm(ab_dtype, c_dtype, acc_dtype, atom_layout_mnk, is_m_major_c)
    return cute.compile(bmm, gemm, a, b, c, stream, epilogue_op)


def run(
    mnkl: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    atom_layout_mnk: Tuple[int, int, int],
    tolerance: float = 1e-03,
    warmup_iterations: int = 2,
    iterations: int = 100,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    benchmark: bool = False,
    **kwargs,
):
    """
    Execute an Ampere tensor core GEMM operation with performance benchmarking.

    Prepares input tensors, configures and launches the GEMM kernel,
    optionally performs reference validation, and benchmarks execution.

    :param mnkl: Problem size as a tuple (M, N, K, L).
    :type mnkl: Tuple[int, int, int, int]
    :param ab_dtype: Data type for input tensors A and B.
    :type ab_dtype: Type[cutlass.Numeric]
    :param c_dtype: Data type for output tensor C.
    :type c_dtype: Type[cutlass.Numeric]
    :param acc_dtype: Accumulator data type for the matrix multiplication.
    :type acc_dtype: Type[cutlass.Numeric]
    :param a_major: Major dimension of the A tensor layout ("m" or "k").
    :type a_major: str
    :param b_major: Major dimension of the B tensor layout ("n" or "k").
    :type b_major: str
    :param c_major: Major dimension of the C tensor layout ("m" or "n").
    :type c_major: str
    :param atom_layout_mnk: Atom layout shape (M, N, K).
    :type atom_layout_mnk: Tuple[int, int, int]
    :param tolerance: Tolerance for reference validation, defaults to 1e-03.
    :type tolerance: float, optional
    :param warmup_iterations: Number of warmup iterations before benchmarking, defaults to 2.
    :type warmup_iterations: int, optional
    :param iterations: Number of benchmark iterations to run, defaults to 100.
    :type iterations: int, optional
    :param skip_ref_check: Whether to skip reference result validation, defaults to False.
    :type skip_ref_check: bool, optional
    :param use_cold_l2: Whether to use circular buffer strategy to ensure cold L2 cache, defaults to False.
    :type use_cold_l2: bool, optional
    :param benchmark: Whether to only benchmark the kernel, defaults to False.
    :type benchmark: bool, optional
    :raises RuntimeError: If CUDA GPU is not available.
    :return: Execution time of the GEMM kernel.
    :rtype: float
    """
    import torch
    from cutlass.torch import dtype as torch_dtype

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    # Run and verify BMM with torch
    a, b, c, a_f32, b_f32, c_f32 = prepare_tensors(
        mnkl, ab_dtype, c_dtype, a_major, b_major, c_major
    )

    leading_dim_a = 2 if a_major == "k" else 1
    leading_dim_b = 1 if b_major == "k" else 2
    leading_dim_c = 2 if c_major == "n" else 1

    a_, b_, c_ = mark_dynamic_layout(
        a,
        b,
        c,
        leading_dim_a,
        leading_dim_b,
        leading_dim_c,
        ab_dtype,
        c_dtype,
        a_f32,
        b_f32,
        c_f32,
    )

    compiled_fn = compile_bmm(
        mnkl,
        a_,
        b_,
        c_,
        ab_dtype,
        c_dtype,
        acc_dtype,
        atom_layout_mnk,
        epilogue_op=lambda x: x,
    )

    print("Running Ampere tensor core GEMM test with:")
    print(f"mnkl: {mnkl}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")

    if not skip_ref_check:
        # Use small random number for deterministic result for reference check
        compiled_fn(a_, b_, c_, current_stream)

        # Manually quantize to be comparable
        # For fp8 types, use f32 source tensors for reference computation
        # since a/b/c may be stored as uint8
        a_ref = a_f32 if is_fp8_dtype(ab_dtype) else a
        b_ref = b_f32 if is_fp8_dtype(ab_dtype) else b
        ref = (
            torch.bmm(a_ref.to(dtype=torch.float32), b_ref.to(dtype=torch.float32))
            .to(dtype=torch_dtype(c_dtype))
            .to(dtype=torch.float32)
        )
        torch.testing.assert_close(
            c.to(dtype=torch.float32), ref, atol=tolerance, rtol=1e-05
        )

    if not benchmark:
        return 0

    def generate_tensors():
        a, b, c, a_f32, b_f32, c_f32 = prepare_tensors(
            mnkl,
            ab_dtype,
            c_dtype,
            a_major,
            b_major,
            c_major,
            init_random=True,
        )
        a_, b_, c_ = mark_dynamic_layout(
            a,
            b,
            c,
            leading_dim_a,
            leading_dim_b,
            leading_dim_c,
            ab_dtype,
            c_dtype,
            a_f32,
            b_f32,
            c_f32,
        )
        return testing.JitArguments(a_, b_, c_, current_stream)

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a.numel() * a.element_size()
            + b.numel() * b.element_size()
            + c.numel() * c.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    # Return execution time in microseconds
    exec_time = testing.benchmark(
        compiled_fn,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )
    print(f"[DSL INFO] Execution time: {exec_time} microseconds per iteration")
    return exec_time


def _parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
    try:
        return tuple(int(x.strip()) for x in s.split(","))
    except ValueError:
        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers."
        )


def prepare_parser():
    parser = argparse.ArgumentParser(description="Example of Dense GEMM on Ampere.")

    parser.add_argument(
        "--mnkl",
        type=_parse_comma_separated_ints,
        default=(256, 256, 512, 1),
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument(
        "--atom_layout_mnk",
        type=_parse_comma_separated_ints,
        default=(2, 2, 1),
        help="Atom layout (comma-separated)",
    )
    parser.add_argument("--ab_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="m")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="n")
    parser.add_argument("--c_major", choices=["n", "m"], type=str, default="n")
    parser.add_argument(
        "--tolerance", type=float, default=1e-03, help="Tolerance for validation"
    )
    parser.add_argument(
        "--benchmark",
        type=str,
        default="default",
        choices=["default", "none"],
        help="Benchmark the kernel with default (cutlass.testing.benchmark) or none",
    )
    parser.add_argument(
        "--warmup_iterations", type=int, default=2, help="Warmup iterations"
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=100,
        help="Number of iterations to run the kernel",
    )
    parser.add_argument(
        "--skip_ref_check", action="store_true", help="Skip reference checking"
    )
    parser.add_argument(
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )

    return parser


if __name__ == "__main__":
    parser = prepare_parser()

    args = parser.parse_args()

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    if len(args.atom_layout_mnk) != 3:
        parser.error("--atom_layout_mnk must contain exactly 3 values")

    print("[DSL INFO] Compiling Ampere Dense GEMM with:")
    print(
        f"[DSL INFO] A dtype: {args.ab_dtype}, B dtype: {args.ab_dtype}, C dtype: {args.c_dtype}, Acc dtype: {args.acc_dtype}"
    )
    print(
        f"[DSL INFO] Matrix majors - A: {args.a_major}, B: {args.b_major}, C: {args.c_major}"
    )
    print(f"[DSL INFO] Atom layout (M, N, K): {args.atom_layout_mnk}")

    run(
        args.mnkl,
        args.ab_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.atom_layout_mnk,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
        args.benchmark == "default",
    )
    print("PASS")
