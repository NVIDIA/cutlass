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
SM100 Input Transform GEMM kernels with 4-pipeline architecture.

Two kernel classes for SS and TS operand sources:
- InputTransformSSGemmKernel: A compute buffer in SMEM
- InputTransformTSGemmKernel: A compute buffer in TMEM

Both compute D = epilogue_op(input_transform(A, B)[0] @ B)
with A going through a transform stage and B bypassing directly to MMA.

12 warps (384 threads):
  Warps 0-3: Epilogue + TMA store (warp 0)
  Warp 4: MMA
  Warp 5: TMA load A
  Warp 6: TMA load B
  Warps 8-11: Transform (128 threads)
"""

import argparse
import os
import sys
from typing import Tuple, Type

import torch

import cutlass
from cutlass import cute
from cutlass import testing
from cutlass.base_dsl.typing import Numeric
from cutlass.cute import experimental as cute_ext
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.torch as cutlass_torch

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../"))

from helpers import cli_helper as cli

ACCUM2STORE_STAGE = 3


class InputTransformSSAOnlyGemmKernel:
    """Input Transform GEMM with SS operand source, A-only transform (4-pipeline)."""

    def __init__(
        self,
        mn_tiler,
        mma_dtype,
        input_transform=lambda a, b: (a, b),
        epilogue_op=lambda x: x,
    ):
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.input_transform = input_transform
        self.epilogue_op = epilogue_op

    @cute.experimental.jit
    def __call__(self, mA: cute.Tensor, mB: cute.Tensor, mD: cute.Tensor):
        tile_mn = cute.core._pack_shape((*self.mn_tiler, 1))
        div = cute.tiled_divide(mD, tile_mn)
        grid = (div.shape[1], div.shape[2], div.shape[3])
        self.kernel(mA, mB, mD).launch(
            grid=grid,
            block=(384, 1, 1),
            cluster=(1, 1, 1),
            smem=cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_100")),
        )

    @cute.experimental.kernel
    def kernel(self, mA: cute.Tensor, mB: cute.Tensor, mD: cute.Tensor):
        ab_dtype, acc_dtype = self.ab_dtype, self.acc_dtype
        c_dtype = mD.element_type
        c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(mD)

        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            ab_dtype,
            ab_dtype,
            cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            cutlass.tensor_utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
            acc_dtype,
            cute.nvgpu.tcgen05.CtaGroup.ONE,
            self.mn_tiler,
        )

        mma_inst_tile_k = 4
        mma_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mnk_tiler = (self.mn_tiler[0], self.mn_tiler[1], mma_k * mma_inst_tile_k)
        tiler_mk, tiler_nk, tiler_mn = (
            (mnk_tiler[0], mnk_tiler[2]),
            (mnk_tiler[1], mnk_tiler[2]),
            (mnk_tiler[0], mnk_tiler[1]),
        )

        gA = cute.zipped_divide(mA, tiler_mk)
        gA_mkl = cute.local_tile(
            mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gB_nkl = cute.local_tile(
            mB, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        gD = cute.zipped_divide(mD, tiler_mn)

        cta_m, cta_n, cta_l = cute.arch.block_idx()
        tid_x, _, _ = cute.arch.thread_idx()
        gA_tile = gA[(None, None), (cta_m, None, cta_l)]
        gD_tile = gD[(None, None), (cta_m, cta_n, cta_l)]

        thr_mma = tiled_mma.get_slice(0)
        tCgA = thr_mma.partition_A(gA_mkl)
        tCgB = thr_mma.partition_B(gB_nkl)

        cta_tile = cute.shape_div(mnk_tiler, (cute.size(tiled_mma.thr_id.shape), 1, 1))
        epi_tile = sm100_utils.compute_epilogue_tile_shape(
            cta_tile, False, c_layout, c_dtype
        )

        # SMEM
        sA = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_a(tiled_mma, mnk_tiler, ab_dtype, 2),
            alignment=1024,
        )
        sB = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_b(tiled_mma, mnk_tiler, ab_dtype, 1),
            alignment=1024,
        )
        sAC = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_a(tiled_mma, mnk_tiler, ab_dtype, 1),
            alignment=1024,
        )
        sC = cute_ext.allocate(
            c_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_epi(
                c_dtype, c_layout, epi_tile, ACCUM2STORE_STAGE
            ),
            alignment=1024,
        )

        # TMEM
        tAcc = cute_ext.allocate(
            acc_dtype,
            cutlass.AddressSpace.tmem,
            cute_ext.make_tmem_layout_acc(tiled_mma, mnk_tiler, 2),
            alignment=16,
        )

        # Epilogue copy
        t2r_atom = sm100_utils.get_tmem_load_op(
            cta_tile, c_layout, c_dtype, acc_dtype, epi_tile, False
        )
        tiled_t2r = cute.nvgpu.tcgen05.make_tmem_copy(
            t2r_atom, cute.zipped_divide(tAcc, ((epi_tile), 1))[((None, None), 0), 0]
        )
        gC_epi = cute.flat_divide(gD_tile, epi_tile)
        rmem_epi_layout = cute_ext.make_t2r_rmem_layout(tiled_t2r, gC_epi, tid_x)

        # Transform copy (SS: cotiled S→R→S)
        tx = tid_x - 32 * 8
        copy_a = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), ab_dtype, num_bits_per_copy=128
        )
        tc_a = cute.make_cotiled_copy(
            copy_a,
            cute.make_layout((128, 8), stride=(8, 1)),
            sAC[(None, None, None, 0)].layout,
        )
        rA_layout = tc_a.get_slice(tx).partition_S(sAC[(None, None, None, 0)]).layout

        # RMEM
        rA = cute_ext.allocate(
            ab_dtype, cutlass.AddressSpace.rmem, rA_layout, alignment=32
        )
        rAcc = cute_ext.allocate(
            acc_dtype, cutlass.AddressSpace.rmem, rmem_epi_layout, alignment=32
        )
        rD = cute_ext.allocate(
            c_dtype, cutlass.AddressSpace.rmem, rmem_epi_layout, alignment=32
        )

        # Pipelines
        mma_op = cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS
        pA = cute_ext.TMAToAsyncPipeline.create(
            num_stages=2,
            consumer=cute_ext.OperationTypeEnum.LD_SHARED,
            consumer_arv_count=128,
        )
        pB = cute_ext.TMAToUMMAPipeline.create(num_stages=1, mma_operation_type=mma_op)
        pT = cute_ext.AsyncToUMMAPipeline.create(
            num_stages=1,
            producer=cute_ext.OperationTypeEnum.ST_SHARED,
            producer_arv_count=128,
            mma_operation_type=mma_op,
        )
        pM = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=2,
            mma_operation_type=mma_op,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=128,
        )
        pS = cute_ext.TMAStorePipeline(
            stages=ACCUM2STORE_STAGE, arv_count=128, barrier_id=1, tma_warp_id=0
        )

        warp = cute.arch.warp_idx()
        warp = cute.arch.make_warp_uniform(warp)
        K = cute.size(gA, mode=[1, 1])

        if warp == 5:
            for k in cutlass.range(0, K, 1, unroll=1):
                tok, i = pA.producer_acquire_and_get_stage()
                cute_ext.tma_load(
                    tCgA[(None, None, None, cta_m, k, cta_l)],
                    sA[None, None, None, i],
                    cute_ext.get_mbarrier(tok),
                )
                pA.producer_commit_and_advance()

        if warp == 6:
            for k in cutlass.range(0, K, 1, unroll=1):
                tok, i = pB.producer_acquire_and_get_stage()
                cute_ext.tma_load(
                    tCgB[(None, None, None, cta_n, k, cta_l)],
                    sB[None, None, None, i],
                    cute_ext.get_mbarrier(tok),
                )
                pB.producer_commit_and_advance()

        if (warp >= 8) & (warp < 12):
            for k in cutlass.range(0, K, 1, unroll=1):
                _, ai = pA.consumer_wait_and_get_stage()
                _, ci = pT.producer_acquire_and_get_stage()
                cute_ext.partition_and_copy(
                    tc_a.get_slice(tx), sA[None, None, None, ai], rA
                )
                a_t, _ = self.input_transform(rA.load(), rA.load())
                rA.store(a_t)
                cute_ext.partition_and_copy(
                    tc_a.get_slice(tx), rA, sAC[None, None, None, ci]
                )
                pT.producer_commit_and_advance()
                pA.consumer_release_and_advance()

        if warp == 4:
            _, mi = pM.producer_acquire_and_get_stage()
            acc = tAcc[None, None, None, mi]
            atom = cute.make_mma_atom(tiled_mma.op)
            atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)
            for k in cutlass.range(0, K, 1, unroll=1):
                _, ti = pT.consumer_wait_and_get_stage()
                _, bi = pB.consumer_wait_and_get_stage()
                As = sAC[None, None, None, ti]
                Bs = sB[None, None, None, bi]
                for kt in cutlass.range(mma_inst_tile_k, unroll_full=True):
                    cute_ext.dot(
                        atom,
                        cute.append_ones(As[None, None, kt], up_to_rank=3),
                        cute.append_ones(Bs[None, None, kt], up_to_rank=3),
                        acc,
                    )
                    atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)
                pB.consumer_release_and_advance()
                pT.consumer_release_and_advance()
            pM.producer_commit_and_advance()

        if warp < 4:
            _, ei = pM.consumer_wait_and_get_stage()
            ad = cute.flat_divide(tAcc[(None, None), 0, 0, ei], epi_tile)
            sc = cute.size(ad.shape, mode=[3])
            for mn in range(sc):
                cute_ext.partition_and_copy(
                    tiled_t2r.get_slice(tid_x), ad[None, None, 0, mn], rAcc
                )
                rD.store(self.epilogue_op(rAcc.load().to(c_dtype)))
                pS.acquire_sync()
                si = pS.get_index()
                r2s = cute.make_tiled_copy_D(
                    cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), c_dtype),
                    tiled_t2r,
                )
                cute_ext.partition_and_copy(
                    r2s.get_slice(tid_x), rD, sC[None, None, si]
                )
                pS.commit_sync()
                if warp == 0:
                    cute_ext.tma_store(
                        sC[None, None, si],
                        gC_epi[None, None, 0, mn],
                    )
                pS.release_advance()
            pS.tail()
            pM.consumer_release_and_advance()


class InputTransformTSAOnlyGemmKernel:
    """Input Transform GEMM with TS operand source, A-only transform (4-pipeline)."""

    def __init__(
        self,
        mn_tiler,
        mma_dtype,
        input_transform=lambda a, b: (a, b),
        epilogue_op=lambda x: x,
    ):
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.input_transform = input_transform
        self.epilogue_op = epilogue_op

    @cute.experimental.jit
    def __call__(self, mA: cute.Tensor, mB: cute.Tensor, mD: cute.Tensor):
        tile_mn = cute.core._pack_shape((*self.mn_tiler, 1))
        div = cute.tiled_divide(mD, tile_mn)
        grid = (div.shape[1], div.shape[2], div.shape[3])
        self.kernel(mA, mB, mD).launch(
            grid=grid,
            block=(384, 1, 1),
            cluster=(1, 1, 1),
            smem=cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_100")),
        )

    @cute.experimental.kernel
    def kernel(self, mA: cute.Tensor, mB: cute.Tensor, mD: cute.Tensor):
        ab_dtype, acc_dtype = self.ab_dtype, self.acc_dtype
        c_dtype = mD.element_type
        c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(mD)

        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            ab_dtype,
            ab_dtype,
            cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            cutlass.tensor_utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
            acc_dtype,
            cute.nvgpu.tcgen05.CtaGroup.ONE,
            self.mn_tiler,
            cute.nvgpu.tcgen05.OperandSource.TMEM,
        )

        mma_inst_tile_k = 4
        mma_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mnk_tiler = (self.mn_tiler[0], self.mn_tiler[1], mma_k * mma_inst_tile_k)
        tiler_mk, tiler_nk, tiler_mn = (
            (mnk_tiler[0], mnk_tiler[2]),
            (mnk_tiler[1], mnk_tiler[2]),
            (mnk_tiler[0], mnk_tiler[1]),
        )

        gA = cute.zipped_divide(mA, tiler_mk)
        gA_mkl = cute.local_tile(
            mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gB_nkl = cute.local_tile(
            mB, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        gD = cute.zipped_divide(mD, tiler_mn)

        cta_m, cta_n, cta_l = cute.arch.block_idx()
        tid_x, _, _ = cute.arch.thread_idx()
        gA_tile = gA[(None, None), (cta_m, None, cta_l)]
        gD_tile = gD[(None, None), (cta_m, cta_n, cta_l)]

        thr_mma = tiled_mma.get_slice(0)
        tCgA = thr_mma.partition_A(gA_mkl)
        tCgB = thr_mma.partition_B(gB_nkl)

        cta_tile = cute.shape_div(mnk_tiler, (cute.size(tiled_mma.thr_id.shape), 1, 1))
        epi_tile = sm100_utils.compute_epilogue_tile_shape(
            cta_tile, False, c_layout, c_dtype
        )

        # SMEM
        sA = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_a(tiled_mma, mnk_tiler, ab_dtype, 1),
            alignment=1024,
        )
        sB = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_b(tiled_mma, mnk_tiler, ab_dtype, 1),
            alignment=1024,
        )
        sC = cute_ext.allocate(
            c_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_epi(
                c_dtype, c_layout, epi_tile, ACCUM2STORE_STAGE
            ),
            alignment=1024,
        )

        # TMEM
        tAcc = cute_ext.allocate(
            acc_dtype,
            cutlass.AddressSpace.tmem,
            cute_ext.make_tmem_layout_acc(tiled_mma, mnk_tiler, 3),
            alignment=16,
        )
        a_shape = tiled_mma.partition_shape_A(tiler_mk)
        tAC = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.tmem,
            tiled_mma.make_fragment_A(cute.append(a_shape, 2)).layout,
            alignment=16,
        )

        # Epilogue copy
        t2r_atom = sm100_utils.get_tmem_load_op(
            cta_tile, c_layout, c_dtype, acc_dtype, epi_tile, False
        )
        tiled_t2r = cute.nvgpu.tcgen05.make_tmem_copy(
            t2r_atom, cute.zipped_divide(tAcc, ((epi_tile), 1))[((None, None), 0), 0]
        )
        gC_epi = cute.flat_divide(gD_tile, epi_tile)
        rmem_epi_layout = cute_ext.make_t2r_rmem_layout(tiled_t2r, gC_epi, tid_x)

        # Transform copy (TS: S→R via R→T partition, then R→T)
        tx = tid_x - 32 * 8
        r2t_atom = cute.make_copy_atom(
            cute.nvgpu.tcgen05.St32x32bOp(
                cute.nvgpu.tcgen05.Repetition.x32, cute.nvgpu.tcgen05.Unpack.NONE
            ),
            ab_dtype,
        )
        tc_a = cute.nvgpu.tcgen05.make_tmem_copy(r2t_atom, tAC[None, None, None, 0])
        rA_layout = tc_a.get_slice(tx).partition_S(sA[None, None, None, 0]).layout

        # RMEM
        rA = cute_ext.allocate(
            ab_dtype, cutlass.AddressSpace.rmem, rA_layout, alignment=32
        )
        rAcc = cute_ext.allocate(
            acc_dtype, cutlass.AddressSpace.rmem, rmem_epi_layout, alignment=32
        )
        rD = cute_ext.allocate(
            c_dtype, cutlass.AddressSpace.rmem, rmem_epi_layout, alignment=32
        )

        # Pipelines
        mma_op = cute_ext.OperationTypeEnum.SM100_MMA_1SM_TS
        pA = cute_ext.TMAToAsyncPipeline.create(
            num_stages=1,
            consumer=cute_ext.OperationTypeEnum.LD_SHARED,
            consumer_arv_count=128,
        )
        pB = cute_ext.TMAToUMMAPipeline.create(num_stages=1, mma_operation_type=mma_op)
        pT = cute_ext.AsyncToUMMAPipeline.create(
            num_stages=2,
            producer=cute_ext.OperationTypeEnum.SM100_COPY_R2T,
            producer_arv_count=128,
            mma_operation_type=mma_op,
        )
        pM = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=3,
            mma_operation_type=mma_op,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=128,
        )
        pS = cute_ext.TMAStorePipeline(
            stages=ACCUM2STORE_STAGE, arv_count=128, barrier_id=1, tma_warp_id=0
        )

        warp = cute.arch.warp_idx()
        warp = cute.arch.make_warp_uniform(warp)
        K = cute.size(gA, mode=[1, 1])

        if warp == 5:
            for k in cutlass.range(0, K, 1, unroll=1):
                tok, i = pA.producer_acquire_and_get_stage()
                cute_ext.tma_load(
                    tCgA[(None, None, None, cta_m, k, cta_l)],
                    sA[None, None, None, i],
                    cute_ext.get_mbarrier(tok),
                )
                pA.producer_commit_and_advance()

        if warp == 6:
            for k in cutlass.range(0, K, 1, unroll=1):
                tok, i = pB.producer_acquire_and_get_stage()
                cute_ext.tma_load(
                    tCgB[(None, None, None, cta_n, k, cta_l)],
                    sB[None, None, None, i],
                    cute_ext.get_mbarrier(tok),
                )
                pB.producer_commit_and_advance()

        if (warp >= 8) & (warp < 12):
            for k in cutlass.range(0, K, 1, unroll=1):
                _, ai = pA.consumer_wait_and_get_stage()
                _, ci = pT.producer_acquire_and_get_stage()
                cute_ext.partition_and_copy(
                    tc_a.get_slice(tx), sA[None, None, None, ai], rA
                )
                a_t, _ = self.input_transform(rA.load(), rA.load())
                rA.store(a_t)
                cute_ext.partition_and_copy(
                    tc_a.get_slice(tx), rA, tAC[None, None, None, ci]
                )
                pT.producer_commit_and_advance()
                pA.consumer_release_and_advance()

        if warp == 4:
            _, mi = pM.producer_acquire_and_get_stage()
            acc = tAcc[None, None, None, mi]
            atom = cute.make_mma_atom(tiled_mma.op)
            atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)
            for k in cutlass.range(0, K, 1, unroll=1):
                _, ti = pT.consumer_wait_and_get_stage()
                _, bi = pB.consumer_wait_and_get_stage()
                As = tAC[None, None, None, ti]
                Bs = sB[None, None, None, bi]
                for kt in cutlass.range(mma_inst_tile_k, unroll_full=True):
                    cute_ext.dot(
                        atom,
                        cute.append_ones(As[None, None, kt], up_to_rank=3),
                        cute.append_ones(Bs[None, None, kt], up_to_rank=3),
                        acc,
                    )
                    atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)
                pB.consumer_release_and_advance()
                pT.consumer_release_and_advance()
            pM.producer_commit_and_advance()

        if warp < 4:
            _, ei = pM.consumer_wait_and_get_stage()
            ad = cute.flat_divide(tAcc[(None, None), 0, 0, ei], epi_tile)
            sc = cute.size(ad.shape, mode=[3])
            for mn in range(sc):
                cute_ext.partition_and_copy(
                    tiled_t2r.get_slice(tid_x), ad[None, None, 0, mn], rAcc
                )
                rD.store(self.epilogue_op(rAcc.load().to(c_dtype)))
                pS.acquire_sync()
                si = pS.get_index()
                r2s = cute.make_tiled_copy_D(
                    cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), c_dtype),
                    tiled_t2r,
                )
                cute_ext.partition_and_copy(
                    r2s.get_slice(tid_x), rD, sC[None, None, si]
                )
                pS.commit_sync()
                if warp == 0:
                    cute_ext.tma_store(
                        sC[None, None, si],
                        gC_epi[None, None, 0, mn],
                    )
                pS.release_advance()
            pS.tail()
            pM.consumer_release_and_advance()


class InputTransformSSGemmKernel:
    """Input Transform GEMM with SS operand source, transforms both A and B (3-pipeline)."""

    def __init__(
        self,
        mn_tiler,
        mma_dtype,
        input_transform=lambda a, b: (a, b),
        epilogue_op=lambda x: x,
    ):
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.input_transform = input_transform
        self.epilogue_op = epilogue_op

    @cute.experimental.jit
    def __call__(self, mA: cute.Tensor, mB: cute.Tensor, mD: cute.Tensor):
        tile_mn = cute.core._pack_shape((*self.mn_tiler, 1))
        div = cute.tiled_divide(mD, tile_mn)
        grid = (div.shape[1], div.shape[2], div.shape[3])
        self.kernel(mA, mB, mD).launch(
            grid=grid,
            block=(384, 1, 1),
            cluster=(1, 1, 1),
            smem=cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_100")),
        )

    @cute.experimental.kernel
    def kernel(self, mA: cute.Tensor, mB: cute.Tensor, mD: cute.Tensor):
        ab_dtype, acc_dtype = self.ab_dtype, self.acc_dtype
        c_dtype = mD.element_type
        c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(mD)

        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            ab_dtype,
            ab_dtype,
            cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            cutlass.tensor_utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
            acc_dtype,
            cute.nvgpu.tcgen05.CtaGroup.ONE,
            self.mn_tiler,
        )

        mma_inst_tile_k = 4
        mma_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mnk_tiler = (self.mn_tiler[0], self.mn_tiler[1], mma_k * mma_inst_tile_k)
        tiler_mk = (mnk_tiler[0], mnk_tiler[2])
        tiler_nk = (mnk_tiler[1], mnk_tiler[2])
        tiler_mn = (mnk_tiler[0], mnk_tiler[1])

        gA = cute.zipped_divide(mA, tiler_mk)
        gB = cute.zipped_divide(mB, tiler_nk)
        gA_mkl = cute.local_tile(
            mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gB_nkl = cute.local_tile(
            mB, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        gD = cute.zipped_divide(mD, tiler_mn)

        load2transform_stage = 2
        transform2mma_stage = 1
        mma2accum_stage = 2

        cta_m, cta_n, cta_l = cute.arch.block_idx()
        tid_x, _, _ = cute.arch.thread_idx()
        gA_tile = gA[(None, None), (cta_m, None, cta_l)]
        gB_tile = gB[(None, None), (cta_n, None, cta_l)]
        gD_tile = gD[(None, None), (cta_m, cta_n, cta_l)]
        thr_mma = tiled_mma.get_slice(0)
        tCgA = thr_mma.partition_A(gA_mkl)
        tCgB = thr_mma.partition_B(gB_nkl)

        cta_tile = cute.shape_div(mnk_tiler, (cute.size(tiled_mma.thr_id.shape), 1, 1))
        epi_tile = sm100_utils.compute_epilogue_tile_shape(
            cta_tile, False, c_layout, c_dtype
        )

        # SMEM: load buffers (A+B staged together), compute buffers, epilogue
        sA = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_a(
                tiled_mma, mnk_tiler, ab_dtype, load2transform_stage
            ),
            alignment=1024,
        )
        sB = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_b(
                tiled_mma, mnk_tiler, ab_dtype, load2transform_stage
            ),
            alignment=1024,
        )
        sAC = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_a(
                tiled_mma, mnk_tiler, ab_dtype, transform2mma_stage
            ),
            alignment=1024,
        )
        sBC = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_b(
                tiled_mma, mnk_tiler, ab_dtype, transform2mma_stage
            ),
            alignment=1024,
        )
        sC = cute_ext.allocate(
            c_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_epi(
                c_dtype, c_layout, epi_tile, ACCUM2STORE_STAGE
            ),
            alignment=1024,
        )

        # TMEM accumulator
        tAcc = cute_ext.allocate(
            acc_dtype,
            cutlass.AddressSpace.tmem,
            cute_ext.make_tmem_layout_acc(tiled_mma, mnk_tiler, mma2accum_stage),
            alignment=16,
        )

        # Epilogue copy
        t2r_atom = sm100_utils.get_tmem_load_op(
            cta_tile, c_layout, c_dtype, acc_dtype, epi_tile, False
        )
        tiled_t2r = cute.nvgpu.tcgen05.make_tmem_copy(
            t2r_atom, cute.zipped_divide(tAcc, ((epi_tile), 1))[((None, None), 0), 0]
        )
        gC_epi = cute.flat_divide(gD_tile, epi_tile)
        rmem_epi_layout = cute_ext.make_t2r_rmem_layout(tiled_t2r, gC_epi, tid_x)

        # Transform copies (cotiled for both A and B)
        tx = tid_x - 32 * 8
        copy_atom_a = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), ab_dtype, num_bits_per_copy=128
        )
        tc_a = cute.make_cotiled_copy(
            copy_atom_a,
            cute.make_layout((128, 8), stride=(8, 1)),
            sAC[(None, None, None, 0)].layout,
        )
        rA_layout = tc_a.get_slice(tx).partition_S(sAC[(None, None, None, 0)]).layout

        copy_atom_b = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), ab_dtype, num_bits_per_copy=128
        )
        tc_b = cute.make_cotiled_copy(
            copy_atom_b,
            cute.make_layout((128, 8), stride=(8, 1)),
            sBC[(None, None, None, 0)].layout,
        )
        rB_layout = tc_b.get_slice(tx).partition_S(sBC[(None, None, None, 0)]).layout

        # RMEM
        rA = cute_ext.allocate(
            ab_dtype, cutlass.AddressSpace.rmem, rA_layout, alignment=32
        )
        rB = cute_ext.allocate(
            ab_dtype, cutlass.AddressSpace.rmem, rB_layout, alignment=32
        )
        rAcc = cute_ext.allocate(
            acc_dtype, cutlass.AddressSpace.rmem, rmem_epi_layout, alignment=32
        )
        rD = cute_ext.allocate(
            c_dtype, cutlass.AddressSpace.rmem, rmem_epi_layout, alignment=32
        )

        # 3 Pipelines: load→transform, transform→MMA, MMA→accum
        mma_op = cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS
        pL = cute_ext.TMAToAsyncPipeline.create(
            num_stages=load2transform_stage,
            consumer=cute_ext.OperationTypeEnum.LD_SHARED,
            consumer_arv_count=128,
        )
        pT = cute_ext.AsyncToUMMAPipeline.create(
            num_stages=transform2mma_stage,
            producer=cute_ext.OperationTypeEnum.ST_SHARED,
            producer_arv_count=128,
            mma_operation_type=mma_op,
        )
        pM = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=mma2accum_stage,
            mma_operation_type=mma_op,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=128,
        )
        pS = cute_ext.TMAStorePipeline(
            stages=ACCUM2STORE_STAGE, arv_count=128, barrier_id=1, tma_warp_id=0
        )

        warp = cute.arch.warp_idx()
        warp = cute.arch.make_warp_uniform(warp)
        K = cute.size(gA, mode=[1, 1])

        # Load warp: loads BOTH A and B into same pipeline stage
        if warp == 5:
            for k in cutlass.range(0, K, 1, unroll=1):
                tok, i = pL.producer_acquire_and_get_stage()
                mbar = cute_ext.get_mbarrier(tok)
                cute_ext.tma_load(
                    tCgA[(None, None, None, cta_m, k, cta_l)],
                    sA[None, None, None, i],
                    mbar,
                )
                cute_ext.tma_load(
                    tCgB[(None, None, None, cta_n, k, cta_l)],
                    sB[None, None, None, i],
                    mbar,
                )
                pL.producer_commit_and_advance()

        # Transform warps: transform both A and B
        if (warp >= 8) & (warp < 12):
            for k in cutlass.range(0, K, 1, unroll=1):
                _, li = pL.consumer_wait_and_get_stage()
                _, ci = pT.producer_acquire_and_get_stage()

                # A: S→R
                cute_ext.partition_and_copy(
                    tc_a.get_slice(tx), sA[None, None, None, li], rA
                )
                # B: S→R
                cute_ext.partition_and_copy(
                    tc_b.get_slice(tx), sB[None, None, None, li], rB
                )

                # Transform both
                a_t, b_t = self.input_transform(rA.load(), rB.load())
                rA.store(a_t)
                rB.store(b_t)

                # A: R→S
                cute_ext.partition_and_copy(
                    tc_a.get_slice(tx), rA, sAC[None, None, None, ci]
                )
                # B: R→S
                cute_ext.partition_and_copy(
                    tc_b.get_slice(tx), rB, sBC[None, None, None, ci]
                )

                pT.producer_commit_and_advance()
                pL.consumer_release_and_advance()

        # MMA: reads both A and B from compute buffers
        if warp == 4:
            _, mi = pM.producer_acquire_and_get_stage()
            acc = tAcc[None, None, None, mi]
            atom = cute.make_mma_atom(tiled_mma.op)
            atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)
            for k in cutlass.range(0, K, 1, unroll=1):
                _, ti = pT.consumer_wait_and_get_stage()
                As = sAC[None, None, None, ti]
                Bs = sBC[None, None, None, ti]
                for kt in cutlass.range(mma_inst_tile_k, unroll_full=True):
                    cute_ext.dot(
                        atom,
                        cute.append_ones(As[None, None, kt], up_to_rank=3),
                        cute.append_ones(Bs[None, None, kt], up_to_rank=3),
                        acc,
                    )
                    atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)
                pT.consumer_release_and_advance()
            pM.producer_commit_and_advance()

        # Epilogue
        if warp < 4:
            _, ei = pM.consumer_wait_and_get_stage()
            ad = cute.flat_divide(tAcc[(None, None), 0, 0, ei], epi_tile)
            sc = cute.size(ad.shape, mode=[3])
            for mn in range(sc):
                cute_ext.partition_and_copy(
                    tiled_t2r.get_slice(tid_x), ad[None, None, 0, mn], rAcc
                )
                rD.store(self.epilogue_op(rAcc.load().to(c_dtype)))
                pS.acquire_sync()
                si = pS.get_index()
                r2s = cute.make_tiled_copy_D(
                    cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), c_dtype),
                    tiled_t2r,
                )
                cute_ext.partition_and_copy(
                    r2s.get_slice(tid_x), rD, sC[None, None, si]
                )
                pS.commit_sync()
                if warp == 0:
                    cute_ext.tma_store(
                        sC[None, None, si],
                        gC_epi[None, None, 0, mn],
                    )
                pS.release_advance()
            pS.tail()
            pM.consumer_release_and_advance()


class InputTransformTSGemmKernel:
    """Input Transform GEMM with TS operand source, transforms both A and B (3-pipeline)."""

    def __init__(
        self,
        mn_tiler,
        mma_dtype,
        input_transform=lambda a, b: (a, b),
        epilogue_op=lambda x: x,
    ):
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.input_transform = input_transform
        self.epilogue_op = epilogue_op

    @cute.experimental.jit
    def __call__(self, mA: cute.Tensor, mB: cute.Tensor, mD: cute.Tensor):
        tile_mn = cute.core._pack_shape((*self.mn_tiler, 1))
        div = cute.tiled_divide(mD, tile_mn)
        grid = (div.shape[1], div.shape[2], div.shape[3])
        self.kernel(mA, mB, mD).launch(
            grid=grid,
            block=(384, 1, 1),
            cluster=(1, 1, 1),
            smem=cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_100")),
        )

    @cute.experimental.kernel
    def kernel(self, mA: cute.Tensor, mB: cute.Tensor, mD: cute.Tensor):
        ab_dtype, acc_dtype = self.ab_dtype, self.acc_dtype
        c_dtype = mD.element_type
        c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(mD)

        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            ab_dtype,
            ab_dtype,
            cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            cutlass.tensor_utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
            acc_dtype,
            cute.nvgpu.tcgen05.CtaGroup.ONE,
            self.mn_tiler,
            cute.nvgpu.tcgen05.OperandSource.TMEM,
        )

        mma_inst_tile_k = 4
        mma_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mnk_tiler = (self.mn_tiler[0], self.mn_tiler[1], mma_k * mma_inst_tile_k)
        tiler_mk = (mnk_tiler[0], mnk_tiler[2])
        tiler_nk = (mnk_tiler[1], mnk_tiler[2])
        tiler_mn = (mnk_tiler[0], mnk_tiler[1])

        gA = cute.zipped_divide(mA, tiler_mk)
        gB = cute.zipped_divide(mB, tiler_nk)
        gA_mkl = cute.local_tile(
            mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gB_nkl = cute.local_tile(
            mB, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        gD = cute.zipped_divide(mD, tiler_mn)

        load2transform_stage = 1
        transform2mma_stage = 2
        mma2accum_stage = 3

        cta_m, cta_n, cta_l = cute.arch.block_idx()
        tid_x, _, _ = cute.arch.thread_idx()
        gA_tile = gA[(None, None), (cta_m, None, cta_l)]
        gB_tile = gB[(None, None), (cta_n, None, cta_l)]
        gD_tile = gD[(None, None), (cta_m, cta_n, cta_l)]
        thr_mma = tiled_mma.get_slice(0)
        tCgA = thr_mma.partition_A(gA_mkl)
        tCgB = thr_mma.partition_B(gB_nkl)

        cta_tile = cute.shape_div(mnk_tiler, (cute.size(tiled_mma.thr_id.shape), 1, 1))
        epi_tile = sm100_utils.compute_epilogue_tile_shape(
            cta_tile, False, c_layout, c_dtype
        )

        # SMEM: load buffers (A+B), B compute buffer, epilogue
        sA = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_a(
                tiled_mma, mnk_tiler, ab_dtype, load2transform_stage
            ),
            alignment=1024,
        )
        sB = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_b(
                tiled_mma, mnk_tiler, ab_dtype, load2transform_stage
            ),
            alignment=1024,
        )
        sBC = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_b(
                tiled_mma, mnk_tiler, ab_dtype, transform2mma_stage
            ),
            alignment=1024,
        )
        sC = cute_ext.allocate(
            c_dtype,
            cutlass.AddressSpace.smem,
            sm100_utils.make_smem_layout_epi(
                c_dtype, c_layout, epi_tile, ACCUM2STORE_STAGE
            ),
            alignment=1024,
        )

        # TMEM: accumulator + A compute buffer
        tAcc = cute_ext.allocate(
            acc_dtype,
            cutlass.AddressSpace.tmem,
            cute_ext.make_tmem_layout_acc(tiled_mma, mnk_tiler, mma2accum_stage),
            alignment=16,
        )
        a_shape = tiled_mma.partition_shape_A(tiler_mk)
        tAC = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.tmem,
            tiled_mma.make_fragment_A(cute.append(a_shape, transform2mma_stage)).layout,
            alignment=16,
        )

        # Epilogue copy
        t2r_atom = sm100_utils.get_tmem_load_op(
            cta_tile, c_layout, c_dtype, acc_dtype, epi_tile, False
        )
        tiled_t2r = cute.nvgpu.tcgen05.make_tmem_copy(
            t2r_atom, cute.zipped_divide(tAcc, ((epi_tile), 1))[((None, None), 0), 0]
        )
        gC_epi = cute.flat_divide(gD_tile, epi_tile)
        rmem_epi_layout = cute_ext.make_t2r_rmem_layout(tiled_t2r, gC_epi, tid_x)

        # Transform copies: A via R→T, B via cotiled S→R→S
        tx = tid_x - 32 * 8
        r2t_atom = cute.make_copy_atom(
            cute.nvgpu.tcgen05.St32x32bOp(
                cute.nvgpu.tcgen05.Repetition.x32, cute.nvgpu.tcgen05.Unpack.NONE
            ),
            ab_dtype,
        )
        tc_a = cute.nvgpu.tcgen05.make_tmem_copy(r2t_atom, tAC[None, None, None, 0])
        rA_layout = tc_a.get_slice(tx).partition_S(sA[None, None, None, 0]).layout

        copy_atom_b = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), ab_dtype, num_bits_per_copy=128
        )
        tc_b = cute.make_cotiled_copy(
            copy_atom_b,
            cute.make_layout((128, 8), stride=(8, 1)),
            sBC[(None, None, None, 0)].layout,
        )
        rB_layout = tc_b.get_slice(tx).partition_S(sBC[(None, None, None, 0)]).layout

        # RMEM
        rA = cute_ext.allocate(
            ab_dtype, cutlass.AddressSpace.rmem, rA_layout, alignment=32
        )
        rB = cute_ext.allocate(
            ab_dtype, cutlass.AddressSpace.rmem, rB_layout, alignment=32
        )
        rAcc = cute_ext.allocate(
            acc_dtype, cutlass.AddressSpace.rmem, rmem_epi_layout, alignment=32
        )
        rD = cute_ext.allocate(
            c_dtype, cutlass.AddressSpace.rmem, rmem_epi_layout, alignment=32
        )

        # 3 Pipelines
        mma_op = cute_ext.OperationTypeEnum.SM100_MMA_1SM_TS
        pL = cute_ext.TMAToAsyncPipeline.create(
            num_stages=load2transform_stage,
            consumer=cute_ext.OperationTypeEnum.LD_SHARED,
            consumer_arv_count=128,
        )
        # Transform warps stage A into TMEM (via SM100_COPY_R2T into tAC)
        # *and* B into SMEM (into sBC) under a single producer-commit.
        # Both producer kinds must fence at commit time -- tcgen05.wait.store
        # for the TMEM write and fence.proxy.async.shared::cta for the SMEM
        # write -- so pT is a multi-producer pipeline.
        pT = cute_ext.AsyncToUMMAPipeline.create(
            num_stages=transform2mma_stage,
            producer=[
                cute_ext.OperationTypeEnum.ST_SHARED,
                cute_ext.OperationTypeEnum.SM100_COPY_R2T,
            ],
            producer_arv_count=128,
            mma_operation_type=mma_op,
        )
        pM = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=mma2accum_stage,
            mma_operation_type=mma_op,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=128,
        )
        pS = cute_ext.TMAStorePipeline(
            stages=ACCUM2STORE_STAGE, arv_count=128, barrier_id=1, tma_warp_id=0
        )

        warp = cute.arch.warp_idx()
        warp = cute.arch.make_warp_uniform(warp)
        K = cute.size(gA, mode=[1, 1])

        # Load warp: loads both A and B
        if warp == 5:
            for k in cutlass.range(0, K, 1, unroll=1):
                tok, i = pL.producer_acquire_and_get_stage()
                mbar = cute_ext.get_mbarrier(tok)
                cute_ext.tma_load(
                    tCgA[(None, None, None, cta_m, k, cta_l)],
                    sA[None, None, None, i],
                    mbar,
                )
                cute_ext.tma_load(
                    tCgB[(None, None, None, cta_n, k, cta_l)],
                    sB[None, None, None, i],
                    mbar,
                )
                pL.producer_commit_and_advance()

        # Transform warps: transform both A and B
        if (warp >= 8) & (warp < 12):
            for k in cutlass.range(0, K, 1, unroll=1):
                _, li = pL.consumer_wait_and_get_stage()
                _, ci = pT.producer_acquire_and_get_stage()
                cute_ext.partition_and_copy(
                    tc_a.get_slice(tx), sA[None, None, None, li], rA
                )
                cute_ext.partition_and_copy(
                    tc_b.get_slice(tx), sB[None, None, None, li], rB
                )
                a_t, b_t = self.input_transform(rA.load(), rB.load())
                rA.store(a_t)
                rB.store(b_t)
                cute_ext.partition_and_copy(
                    tc_a.get_slice(tx), rA, tAC[None, None, None, ci]
                )
                cute_ext.partition_and_copy(
                    tc_b.get_slice(tx), rB, sBC[None, None, None, ci]
                )
                pT.producer_commit_and_advance()
                pL.consumer_release_and_advance()

        # MMA: reads A from TMEM, B from SMEM compute buffer
        if warp == 4:
            _, mi = pM.producer_acquire_and_get_stage()
            acc = tAcc[None, None, None, mi]
            atom = cute.make_mma_atom(tiled_mma.op)
            atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)
            for k in cutlass.range(0, K, 1, unroll=1):
                _, ti = pT.consumer_wait_and_get_stage()
                As = tAC[None, None, None, ti]
                Bs = sBC[None, None, None, ti]
                for kt in cutlass.range(mma_inst_tile_k, unroll_full=True):
                    cute_ext.dot(
                        atom,
                        cute.append_ones(As[None, None, kt], up_to_rank=3),
                        cute.append_ones(Bs[None, None, kt], up_to_rank=3),
                        acc,
                    )
                    atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)
                pT.consumer_release_and_advance()
            pM.producer_commit_and_advance()

        # Epilogue
        if warp < 4:
            _, ei = pM.consumer_wait_and_get_stage()
            ad = cute.flat_divide(tAcc[(None, None), 0, 0, ei], epi_tile)
            sc = cute.size(ad.shape, mode=[3])
            for mn in range(sc):
                cute_ext.partition_and_copy(
                    tiled_t2r.get_slice(tid_x), ad[None, None, 0, mn], rAcc
                )
                rD.store(self.epilogue_op(rAcc.load().to(c_dtype)))
                pS.acquire_sync()
                si = pS.get_index()
                r2s = cute.make_tiled_copy_D(
                    cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), c_dtype),
                    tiled_t2r,
                )
                cute_ext.partition_and_copy(
                    r2s.get_slice(tid_x), rD, sC[None, None, si]
                )
                pS.commit_sync()
                if warp == 0:
                    cute_ext.tma_store(
                        sC[None, None, si],
                        gC_epi[None, None, 0, mn],
                    )
                pS.release_advance()
            pS.tail()
            pM.consumer_release_and_advance()


def create_tensors(l, m, n, k, ab_dtype, c_dtype):
    torch.manual_seed(1111)
    a_cpu = cutlass_torch.matrix(l, m, k, False, ab_dtype)
    b_cpu = cutlass_torch.matrix(l, n, k, False, ab_dtype)
    c_cpu = cutlass_torch.matrix(l, m, n, False, c_dtype)
    a_t, _ = cutlass_torch.cute_tensor_like(
        a_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    b_t, _ = cutlass_torch.cute_tensor_like(
        b_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    c_t, c_gpu = cutlass_torch.cute_tensor_like(
        c_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
    )
    return a_t, b_t, c_t, a_cpu, b_cpu, c_gpu


def compare(a_cpu, b_cpu, c_gpu, tolerance=1e-01):
    ref = torch.einsum("mkl,nkl->mnl", a_cpu.to(torch.float32), b_cpu.to(torch.float32))
    torch.testing.assert_close(c_gpu.cpu(), ref, atol=tolerance, rtol=1e-05)


# Kernel classes selectable from the perf harness by operand source. Both apply
# the same A/B transform; they differ in where the transformed A operand lands
# before the MMA reads it (SMEM vs TMEM).
INPUT_TRANSFORM_KERNELS = {
    "SS": InputTransformSSGemmKernel,
    "TS": InputTransformTSGemmKernel,
}


def run(
    mnkl: Tuple[int, int, int, int],
    mma_tiler_mn: Tuple[int, int],
    ab_dtype: Type[Numeric],
    c_dtype: Type[Numeric],
    acc_dtype: Type[Numeric],
    a_major: str = "k",
    b_major: str = "k",
    c_major: str = "n",
    operand_source: str = "SS",
    warmup_iterations: int = 0,
    iterations: int = 1,
    use_cold_l2: bool = False,
    tolerance: float = 1e-01,
    skip_ref_check: bool = False,
    **kwargs,
):
    """Run and benchmark the input-transform GEMM D = transform(A, B)[0] @ B.

    The benchmark uses the identity transform so the measured time reflects the
    pipeline structure (extra transform stage) rather than transform arithmetic.

    Args:
        mnkl: Problem size (M, N, K, L).
        mma_tiler_mn: MMA tile (M, N).
        ab_dtype/c_dtype/acc_dtype: Operand, output and accumulator types.
        a_major/b_major/c_major: Operand layouts. create_tensors is K/K/N-major.
        operand_source: "SS" (A staged in SMEM) or "TS" (A staged in TMEM).
        warmup_iterations/iterations: Benchmark loop counts.
        use_cold_l2: Cycle fresh workspaces so every iteration misses L2.
        tolerance/skip_ref_check: Reference-check controls.
        kwargs: Absorbs the extra BenchmarkConfig fields that perf_benchmark
            passes to every run(); they are not forwarded any further.

    Returns:
        Execution time in microseconds per iteration.

    Raises:
        ValueError: If operand_source is not one of INPUT_TRANSFORM_KERNELS,
            or if the majors are not ("k", "k", "n").
        AssertionError: If reference checking is enabled and the output does
            not match the Torch reference within tolerance.
    """
    cli.print_problem_config(
        "Blackwell Input Transform GEMM",
        mnkl,
        dtypes={"AB": ab_dtype, "C": c_dtype, "Acc": acc_dtype},
        majors={"A": a_major, "B": b_major, "C": c_major},
        mma_tiler_mn=mma_tiler_mn,
    )
    print(f"Operand source: {operand_source}")
    cli.print_benchmark_config(
        tolerance=tolerance,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        skip_ref_check=skip_ref_check,
        use_cold_l2=use_cold_l2,
    )

    m, n, k, l = mnkl

    if operand_source not in INPUT_TRANSFORM_KERNELS:
        raise ValueError(
            f"Unknown operand_source {operand_source!r}, "
            f"expected one of {sorted(INPUT_TRANSFORM_KERNELS)}"
        )
    # create_tensors always builds K-major A/B and N-major C.
    if (a_major, b_major, c_major) != ("k", "k", "n"):
        raise ValueError(
            "input_transform_gemm perf harness only supports majors (k, k, n), "
            f"got ({a_major}, {b_major}, {c_major})"
        )

    a_tensor, b_tensor, c_tensor, a_cpu, b_cpu, c_gpu = create_tensors(
        l, m, n, k, ab_dtype, c_dtype
    )

    kernel = INPUT_TRANSFORM_KERNELS[operand_source](
        mn_tiler=mma_tiler_mn,
        mma_dtype=(ab_dtype, acc_dtype),
    )

    compiled_kernel = cute_ext.compile(kernel, a_tensor, b_tensor, c_tensor)
    compiled_kernel.engine.initialize()
    compiled_kernel(a_tensor, b_tensor, c_tensor)

    if not skip_ref_check:
        ref = torch.einsum(
            "mkl,nkl->mnl", a_cpu.to(torch.float32), b_cpu.to(torch.float32)
        )
        torch.testing.assert_close(
            c_gpu.cpu().to(torch.float32), ref, atol=tolerance, rtol=1e-05
        )
        print("check reference: PASS")

    def generate_tensors():
        a_workspace, _ = cutlass_torch.cute_tensor_like(
            a_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        b_workspace, _ = cutlass_torch.cute_tensor_like(
            b_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        c_workspace, _ = cutlass_torch.cute_tensor_like(
            c_gpu.cpu(), c_dtype, is_dynamic_layout=True, assumed_align=16
        )
        return testing.JitArguments(a_workspace, b_workspace, c_workspace)

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_cpu.numel() * a_cpu.element_size()
            + b_cpu.numel() * b_cpu.element_size()
            + c_gpu.numel() * c_gpu.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_kernel,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Example of Input Transform GEMM on Blackwell."
    )

    cli.add_mnkl_arg(parser, default=(1024, 2048, 4096, 1), strict_length=True)
    cli.add_mma_tiler_arg(parser, strict_length=True)
    cli.add_dtype_args(parser, ab=cutlass.Float16, c=cutlass.Float16)
    # This kernel only builds the K/K/N layout combination.
    cli.add_major_args(parser, a=["k"], b=["k"], c=["n"])
    cli.add_benchmark_args(parser)

    parser.add_argument(
        "--operand_source", choices=sorted(INPUT_TRANSFORM_KERNELS), default="SS"
    )

    args = parser.parse_args()

    run(
        args.mnkl,
        args.mma_tiler_mn,
        args.ab_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.operand_source,
        args.warmup_iterations,
        args.iterations,
        args.use_cold_l2,
        args.tolerance,
        args.skip_ref_check,
    )
    print("PASS")
