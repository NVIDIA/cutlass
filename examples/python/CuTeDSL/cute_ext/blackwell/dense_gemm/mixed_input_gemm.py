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
SM100 Mixed-Input GEMM kernel with dequantization transform.

Computes D = epilogue_op((A.to(ab_dtype) - Zeros.to(ab_dtype)) * Scale @ B)

Uses the same 4-pipeline architecture as InputTransformGemmKernel,
with additional Scale/Zeros tensors loaded alongside A.
"""

import argparse
import os
import sys
from typing import Tuple, Type

import torch

import cutlass
from cutlass import cute
from cutlass import testing
from cutlass.cute import experimental as cute_ext
from cutlass.base_dsl.typing import Numeric
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.torch as cutlass_torch

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../"))

from helpers import cli_helper as cli

# Pipeline stage constants
ACCUM2STORE_STAGE = 3


class MixedInputGemmKernel:
    """
    Mixed-input GEMM kernel for SM100.

    A (input_a_dtype, e.g. Int8) is dequantized via: (A - Zeros) * Scale
    B (ab_dtype, e.g. Float16) goes directly to MMA.
    Uses the same 4-pipeline architecture as InputTransformGemmKernel.
    """

    def __init__(
        self,
        mn_tiler: tuple[int, int],
        mma_dtype: tuple[Type[Numeric], Type[Numeric]],
        input_a_dtype: Type[Numeric],
        epilogue_op=lambda x: x,
    ):
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.input_a_dtype = input_a_dtype
        self.epilogue_op = epilogue_op

    @cute.experimental.jit
    def __call__(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mScale: cute.Tensor,
        mZeros: cute.Tensor,
        mD: cute.Tensor,
    ):
        tile_mn = cute.core._pack_shape((*self.mn_tiler, 1))
        div = cute.tiled_divide(mD, tile_mn)
        grid = (div.shape[1], div.shape[2], div.shape[3])
        self.kernel(mA, mB, mScale, mZeros, mD).launch(
            grid=grid,
            block=(384, 1, 1),
            cluster=(1, 1, 1),
            smem=cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_100")),
        )

    @cute.experimental.kernel
    def kernel(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mScale: cute.Tensor,
        mZeros: cute.Tensor,
        mD: cute.Tensor,
    ):
        ab_dtype = self.ab_dtype
        acc_dtype = self.acc_dtype
        input_a_dtype = self.input_a_dtype
        c_dtype = mD.element_type
        c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(mD)
        use_2cta_instrs = False

        # MMA configuration (SS only for mixed input)
        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            ab_dtype,
            ab_dtype,
            cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            cutlass.tensor_utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
            acc_dtype,
            cute.nvgpu.tcgen05.CtaGroup.ONE,
            self.mn_tiler,
        )

        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        mnk_tiler = (
            self.mn_tiler[0],
            self.mn_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )

        tiler_mk = (mnk_tiler[0], mnk_tiler[2])
        tiler_nk = (mnk_tiler[1], mnk_tiler[2])
        tiler_mn = (mnk_tiler[0], mnk_tiler[1])

        gA = cute.zipped_divide(mA, tiler_mk)
        gA_mkl = cute.local_tile(
            mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gB_nkl = cute.local_tile(
            mB, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        gScale = cute.zipped_divide(mScale, tiler_mk)
        gZeros = cute.zipped_divide(mZeros, tiler_mk)
        gScale_mkl = cute.local_tile(
            mScale, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gZeros_mkl = cute.local_tile(
            mZeros, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gD = cute.zipped_divide(mD, tiler_mn)

        # Pipeline stages
        loadA2transform_stage = 2
        loadB2mma_stage = 1
        transformA2mma_stage = 1
        mma2accum_stage = 2

        cta_m, cta_n, cta_l = cute.arch.block_idx()
        tid_x, _, _ = cute.arch.thread_idx()

        gA_tile = gA[(None, None), (cta_m, None, cta_l)]
        gScale_tile = gScale[(None, None), (cta_m, None, cta_l)]
        gZeros_tile = gZeros[(None, None), (cta_m, None, cta_l)]
        gD_tile = gD[(None, None), (cta_m, cta_n, cta_l)]

        thr_mma = tiled_mma.get_slice(0)
        tCgA = thr_mma.partition_A(gA_mkl)
        tCgB = thr_mma.partition_B(gB_nkl)
        tCgScale = thr_mma.partition_A(gScale_mkl)
        tCgZeros = thr_mma.partition_A(gZeros_mkl)

        # SMEM layouts
        a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mnk_tiler,
            input_a_dtype,
            loadA2transform_stage,
        )
        a_scale_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mnk_tiler,
            ab_dtype,
            loadA2transform_stage,
        )
        b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma,
            mnk_tiler,
            ab_dtype,
            loadB2mma_stage,
        )
        a_compute_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mnk_tiler,
            ab_dtype,
            transformA2mma_stage,
        )

        cta_tile_shape_mnk = cute.shape_div(
            mnk_tiler, (cute.size(tiled_mma.thr_id.shape), 1, 1)
        )
        epi_tile = sm100_utils.compute_epilogue_tile_shape(
            cta_tile_shape_mnk,
            use_2cta_instrs,
            c_layout,
            c_dtype,
        )
        sc_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            c_dtype,
            c_layout,
            epi_tile,
            ACCUM2STORE_STAGE,
        )

        # Allocate SMEM buffers
        bufferSA = cute_ext.allocate(
            input_a_dtype,
            cutlass.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )
        bufferSZero = cute_ext.allocate(
            input_a_dtype,
            cutlass.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )
        bufferSScale = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            a_scale_smem_layout_staged,
            alignment=1024,
        )
        bufferSB = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )
        bufferSACompute = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.smem,
            a_compute_smem_layout_staged,
            alignment=1024,
        )
        bufferSC = cute_ext.allocate(
            c_dtype,
            cutlass.AddressSpace.smem,
            sc_smem_layout_staged,
            alignment=1024,
        )

        # TMEM accumulator
        tmem_layout = cute_ext.make_tmem_layout_acc(
            tiled_mma, mnk_tiler, mma2accum_stage
        )
        bufferTAccum = cute_ext.allocate(
            acc_dtype,
            cutlass.AddressSpace.tmem,
            tmem_layout,
            alignment=16,
        )

        # Epilogue copy setup
        copy_atom_t2r = sm100_utils.get_tmem_load_op(
            cta_tile_shape_mnk,
            c_layout,
            c_dtype,
            acc_dtype,
            epi_tile,
            use_2cta_instrs,
        )
        accumulators = cute.zipped_divide(bufferTAccum, ((epi_tile), 1))
        acc_epi_div = accumulators[((None, None), 0), 0]
        tiled_copy_t2r = cute.nvgpu.tcgen05.make_tmem_copy(copy_atom_t2r, acc_epi_div)
        gC_mnl_epi = cute.flat_divide(gD_tile, epi_tile)
        acc_d_rmem_layout = cute_ext.make_t2r_rmem_layout(
            tiled_copy_t2r, gC_mnl_epi, tid_x
        )

        # Transform copy atoms
        transform_local_tidx = tid_x - 32 * 8
        copy_atom_ab_compute = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), ab_dtype, num_bits_per_copy=128
        )
        tiled_copy_sa_compute = cute.make_cotiled_copy(
            copy_atom_ab_compute,
            cute.make_layout((128, 8), stride=(8, 1)),
            bufferSACompute[(None, None, None, 0)].layout,
        )
        thr_copy_sa = tiled_copy_sa_compute.get_slice(transform_local_tidx)
        a_compute_r_layout = thr_copy_sa.partition_S(
            bufferSACompute[(None, None, None, 0)]
        ).layout

        # Allocate RMEM buffers
        bufferRACompute_lower = cute_ext.allocate(
            input_a_dtype,
            cutlass.AddressSpace.rmem,
            a_compute_r_layout,
            alignment=32,
        )
        bufferRZero = cute_ext.allocate(
            input_a_dtype,
            cutlass.AddressSpace.rmem,
            a_compute_r_layout,
            alignment=32,
        )
        bufferRScale = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.rmem,
            a_compute_r_layout,
            alignment=32,
        )
        bufferRACompute = cute_ext.allocate(
            ab_dtype,
            cutlass.AddressSpace.rmem,
            a_compute_r_layout,
            alignment=32,
        )
        bufferRAcc = cute_ext.allocate(
            acc_dtype,
            cutlass.AddressSpace.rmem,
            acc_d_rmem_layout,
            alignment=32,
        )
        bufferRD = cute_ext.allocate(
            c_dtype,
            cutlass.AddressSpace.rmem,
            acc_d_rmem_layout,
            alignment=32,
        )

        # Pipelines
        mma_op = cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS

        loadA2transform_pipe = cute_ext.TMAToAsyncPipeline.create(
            num_stages=loadA2transform_stage,
            consumer=cute_ext.OperationTypeEnum.LD_SHARED,
            consumer_arv_count=128,
        )
        loadB2mma_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=loadB2mma_stage,
            mma_operation_type=mma_op,
        )
        transformA2mma_pipe = cute_ext.AsyncToUMMAPipeline.create(
            num_stages=transformA2mma_stage,
            producer=cute_ext.OperationTypeEnum.ST_SHARED,
            producer_arv_count=128,
            mma_operation_type=mma_op,
        )
        mma2accum_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=mma2accum_stage,
            mma_operation_type=mma_op,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=128,
        )

        tma_store_warp_id = 0
        accum2store_pipe = cute_ext.TMAStorePipeline(
            stages=ACCUM2STORE_STAGE,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=tma_store_warp_id,
        )

        # Warp assignment
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        is_loadA_warp = warp_idx == 5
        is_loadB_warp = warp_idx == 6
        is_transform_warp = (warp_idx >= 8) & (warp_idx < 12)
        is_mma_warp = warp_idx == 4
        is_epi_warp = warp_idx < 4

        k_tile_size = cute.size(gA, mode=[1, 1])

        # === TMA Load A + Scale + Zeros warp ===
        if is_loadA_warp:
            for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                gA_k = tCgA[(None, None, None, cta_m, k, cta_l)]
                gScale_k = tCgScale[(None, None, None, cta_m, k, cta_l)]
                gZeros_k = tCgZeros[(None, None, None, cta_m, k, cta_l)]
                producer_stage_token, idx = (
                    loadA2transform_pipe.producer_acquire_and_get_stage()
                )
                mbar = cute_ext.get_mbarrier(producer_stage_token)
                cute_ext.tma_load(
                    gA_k,
                    bufferSA[None, None, None, idx],
                    mbar,
                )
                cute_ext.tma_load(
                    gScale_k,
                    bufferSScale[None, None, None, idx],
                    mbar,
                )
                cute_ext.tma_load(
                    gZeros_k,
                    bufferSZero[None, None, None, idx],
                    mbar,
                )
                loadA2transform_pipe.producer_commit_and_advance()

        # === TMA Load B warp ===
        if is_loadB_warp:
            for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                gB_k = tCgB[(None, None, None, cta_n, k, cta_l)]
                producer_stage_token, idx = (
                    loadB2mma_pipe.producer_acquire_and_get_stage()
                )
                mbar = cute_ext.get_mbarrier(producer_stage_token)
                cute_ext.tma_load(
                    gB_k,
                    bufferSB[None, None, None, idx],
                    mbar,
                )
                loadB2mma_pipe.producer_commit_and_advance()

        # === Transform warps: dequantize A ===
        if is_transform_warp:
            for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                _, idx = loadA2transform_pipe.consumer_wait_and_get_stage()
                _, compute_idx = transformA2mma_pipe.producer_acquire_and_get_stage()

                # Copy A, Zeros, Scale from SMEM to RMEM
                cute_ext.partition_and_copy(
                    tiled_copy_sa_compute.get_slice(transform_local_tidx),
                    bufferSA[None, None, None, idx],
                    bufferRACompute_lower,
                )
                cute_ext.partition_and_copy(
                    tiled_copy_sa_compute.get_slice(transform_local_tidx),
                    bufferSZero[None, None, None, idx],
                    bufferRZero,
                )
                cute_ext.partition_and_copy(
                    tiled_copy_sa_compute.get_slice(transform_local_tidx),
                    bufferSScale[None, None, None, idx],
                    bufferRScale,
                )

                # Dequantize: (A - Zeros) * Scale
                rA_lower = bufferRACompute_lower.load().to(ab_dtype)
                rz = bufferRZero.load().to(ab_dtype)
                rs = bufferRScale.load()
                rA = (rA_lower - rz) * rs
                bufferRACompute.store(rA)

                # Copy transformed A to compute buffer
                cute_ext.partition_and_copy(
                    tiled_copy_sa_compute.get_slice(transform_local_tidx),
                    bufferRACompute,
                    bufferSACompute[None, None, None, compute_idx],
                )

                transformA2mma_pipe.producer_commit_and_advance()
                loadA2transform_pipe.consumer_release_and_advance()

        # === MMA warp ===
        if is_mma_warp:
            _, idx = mma2accum_pipe.producer_acquire_and_get_stage()
            accumulators_sliced = bufferTAccum[None, None, None, idx]
            mma_atom = cute.make_mma_atom(tiled_mma.op)
            mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)

            for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                _, transform_idx = transformA2mma_pipe.consumer_wait_and_get_stage()
                _, b_idx = loadB2mma_pipe.consumer_wait_and_get_stage()

                bufferA_stage = bufferSACompute[None, None, None, transform_idx]
                bufferB_stage = bufferSB[None, None, None, b_idx]

                for k_tile in cutlass.range(mma_inst_tile_k, unroll_full=True):
                    bufferA_sliced = bufferA_stage[None, None, k_tile]
                    bufferB_sliced = bufferB_stage[None, None, k_tile]
                    cute_ext.dot(
                        mma_atom,
                        cute.append_ones(bufferA_sliced, up_to_rank=3),
                        cute.append_ones(bufferB_sliced, up_to_rank=3),
                        accumulators_sliced,
                    )
                    mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)

                loadB2mma_pipe.consumer_release_and_advance()
                transformA2mma_pipe.consumer_release_and_advance()

            mma2accum_pipe.producer_commit_and_advance()

        # === Epilogue warps ===
        if is_epi_warp:
            _, idx = mma2accum_pipe.consumer_wait_and_get_stage()
            accumulators_sliced = bufferTAccum[(None, None), 0, 0, idx]
            acc_epi_div_tiled = cute.flat_divide(accumulators_sliced, epi_tile)
            subtile_cnt = cute.size(acc_epi_div_tiled.shape, mode=[3])

            for mn in range(subtile_cnt):
                cute_ext.partition_and_copy(
                    tiled_copy_t2r.get_slice(tid_x),
                    acc_epi_div_tiled[None, None, 0, mn],
                    bufferRAcc,
                )
                bufferRD.store(self.epilogue_op(bufferRAcc.load().to(c_dtype)))

                accum2store_pipe.acquire_sync()
                store_idx = accum2store_pipe.get_index()

                tiled_copy_r2s = cute.make_tiled_copy_D(
                    cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), c_dtype),
                    tiled_copy_t2r,
                )
                cute_ext.partition_and_copy(
                    tiled_copy_r2s.get_slice(tid_x),
                    bufferRD,
                    bufferSC[None, None, store_idx],
                )

                accum2store_pipe.commit_sync()

                if warp_idx == tma_store_warp_id:
                    cute_ext.tma_store(
                        bufferSC[None, None, store_idx],
                        gC_mnl_epi[None, None, 0, mn],
                    )

                accum2store_pipe.release_advance()

            accum2store_pipe.tail()
            mma2accum_pipe.consumer_release_and_advance()


class MixedInputGemmTestbed:
    """Test harness for mixed-input GEMM."""

    def __init__(self, m, n, k, l=1):
        torch.manual_seed(1111)
        self.m, self.n, self.k, self.l = m, n, k, l

        self.A = (
            torch.empty(l, m, k).random_(-4, 4).permute(1, 2, 0).to(torch.int8).cuda()
        )
        self.Scale = (
            torch.empty(l, m, k)
            .random_(-4, 4)
            .permute(1, 2, 0)
            .to(torch.float16)
            .cuda()
        )
        self.Zeros = (
            torch.empty(l, m, k).random_(-4, 4).permute(1, 2, 0).to(torch.int8).cuda()
        )
        self.B = (
            torch.empty(l, n, k)
            .random_(-4, 4)
            .permute(1, 2, 0)
            .to(torch.float16)
            .cuda()
        )
        self.D = (
            torch.empty(l, m, n)
            .random_(-4, 4)
            .permute(1, 2, 0)
            .to(torch.float16)
            .cuda()
        )

        # Compute scale/zeros from A's range
        self.Scale[:, :, :] = (self.A.max() - self.A.min()) / torch.iinfo(
            torch.int8
        ).max
        self.Zeros[:, :, :] = -self.A.min() / self.Scale

        # Host copies of the generated data. Cold-L2 timing rebuilds a fresh
        # device workspace per iteration, so cache these once instead of paying
        # a device-to-host copy of every operand per workspace.
        self.A_host = self.A.cpu()
        self.B_host = self.B.cpu()
        self.Scale_host = self.Scale.cpu()
        self.Zeros_host = self.Zeros.cpu()
        self.D_host = self.D.cpu()

        # Create CuTe tensors
        self.a_tensor, _ = cutlass_torch.cute_tensor_like(
            self.A_host, cutlass.Int8, is_dynamic_layout=True, assumed_align=16
        )
        self.b_tensor, _ = cutlass_torch.cute_tensor_like(
            self.B_host, cutlass.Float16, is_dynamic_layout=True, assumed_align=16
        )
        self.scale_tensor, _ = cutlass_torch.cute_tensor_like(
            self.Scale_host, cutlass.Float16, is_dynamic_layout=True, assumed_align=16
        )
        self.zeros_tensor, _ = cutlass_torch.cute_tensor_like(
            self.Zeros_host, cutlass.Int8, is_dynamic_layout=True, assumed_align=16
        )
        self.d_tensor, self.d_gpu = cutlass_torch.cute_tensor_like(
            self.D_host, cutlass.Float16, is_dynamic_layout=True, assumed_align=16
        )

    def make_cute_tensors(self):
        """Build a fresh set of device tensors from the cached host data.

        Used by the benchmark loop to cycle workspaces for cold-L2 timing.
        """
        a_tensor, _ = cutlass_torch.cute_tensor_like(
            self.A_host, cutlass.Int8, is_dynamic_layout=True, assumed_align=16
        )
        b_tensor, _ = cutlass_torch.cute_tensor_like(
            self.B_host, cutlass.Float16, is_dynamic_layout=True, assumed_align=16
        )
        scale_tensor, _ = cutlass_torch.cute_tensor_like(
            self.Scale_host, cutlass.Float16, is_dynamic_layout=True, assumed_align=16
        )
        zeros_tensor, _ = cutlass_torch.cute_tensor_like(
            self.Zeros_host, cutlass.Int8, is_dynamic_layout=True, assumed_align=16
        )
        d_tensor, _ = cutlass_torch.cute_tensor_like(
            self.D_host, cutlass.Float16, is_dynamic_layout=True, assumed_align=16
        )
        return a_tensor, b_tensor, scale_tensor, zeros_tensor, d_tensor

    def workspace_bytes(self):
        """Bytes of GMEM one workspace touches: A, B, Scale, Zeros and D.

        Raw tensor payload only (numel * element_size); CuTe wrapper and
        descriptor overhead is excluded. testing.get_workspace_count() uses
        this to size the workspace ring for cold-L2 timing, so undercounting
        here would leave part of the ring resident in L2.
        """
        return sum(
            t.numel() * t.element_size()
            for t in (self.A, self.B, self.Scale, self.Zeros, self.D)
        )

    def reference_check(self, epilogue_fn=torch.nn.Identity(), tolerance=1e-01):
        ref = epilogue_fn(
            torch.einsum(
                "mkl,nkl->mnl",
                (self.A_host.to(torch.float16) - self.Zeros_host.to(torch.float16))
                * self.Scale_host.to(torch.float16),
                self.B_host,
            )
        )
        torch.testing.assert_close(self.d_gpu.cpu(), ref, atol=tolerance, rtol=1e-05)


def run(
    mnkl: Tuple[int, int, int, int],
    mma_tiler_mn: Tuple[int, int],
    a_dtype: Type[Numeric],
    b_dtype: Type[Numeric],
    c_dtype: Type[Numeric],
    acc_dtype: Type[Numeric],
    a_major: str = "k",
    b_major: str = "k",
    c_major: str = "n",
    warmup_iterations: int = 0,
    iterations: int = 1,
    use_cold_l2: bool = False,
    tolerance: float = 1e-01,
    skip_ref_check: bool = False,
    **kwargs,
):
    """Run and benchmark the mixed-input GEMM D = ((A - Zeros) * Scale) @ B.

    Args:
        mnkl: Problem size (M, N, K, L).
        mma_tiler_mn: MMA tile (M, N).
        a_dtype: Quantized A operand type (the testbed generates Int8 data).
        b_dtype: B operand type, which is also the MMA type after dequantization.
        c_dtype/acc_dtype: Output and accumulator types.
        a_major/b_major/c_major: Operand layouts. The testbed only builds
            K-major A/B and N-major C, so ("k", "k", "n") is the only accepted
            combination.
        warmup_iterations/iterations: Benchmark loop counts.
        use_cold_l2: Cycle fresh workspaces so every iteration misses L2.
        tolerance/skip_ref_check: Reference-check controls.
        kwargs: Absorbs the extra BenchmarkConfig fields that perf_benchmark
            passes to every run(); they are not forwarded any further.

    Returns:
        Execution time in microseconds per iteration.

    Raises:
        ValueError: If the dtypes or the majors are not the ones the testbed
            generates.
        AssertionError: If reference checking is enabled and the output does
            not match the Torch reference within tolerance.
    """
    cli.print_problem_config(
        "Blackwell Mixed-Input GEMM",
        mnkl,
        dtypes={"A": a_dtype, "B": b_dtype},
        lines=[f"C dtype: {c_dtype}, Acc dtype: {acc_dtype}"],
        majors={"A": a_major, "B": b_major, "C": c_major},
        mma_tiler_mn=mma_tiler_mn,
    )
    cli.print_benchmark_config(
        tolerance=tolerance,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        skip_ref_check=skip_ref_check,
        use_cold_l2=use_cold_l2,
    )

    m, n, k, l = mnkl

    # MixedInputGemmTestbed generates Int8 A / Float16 B, Scale, D. Fail loudly
    # rather than silently benchmarking a different configuration than requested.
    expected = {
        "a_dtype": (a_dtype, cutlass.Int8),
        "b_dtype": (b_dtype, cutlass.Float16),
        "c_dtype": (c_dtype, cutlass.Float16),
    }
    for arg_name, (given, supported) in expected.items():
        if given is not supported:
            raise ValueError(
                f"mixed_input_gemm perf harness supports {arg_name}={supported}, "
                f"got {given}"
            )

    expected_majors = {
        "a_major": (a_major, "k"),
        "b_major": (b_major, "k"),
        "c_major": (c_major, "n"),
    }
    for arg_name, (given, supported) in expected_majors.items():
        if given != supported:
            raise ValueError(
                f"mixed_input_gemm perf harness supports {arg_name}={supported!r}, "
                f"got {given!r}"
            )

    testbed = MixedInputGemmTestbed(m=m, n=n, k=k, l=l)

    mixed_input_gemm = MixedInputGemmKernel(
        mn_tiler=mma_tiler_mn,
        mma_dtype=(b_dtype, acc_dtype),
        input_a_dtype=a_dtype,
    )

    compiled_mixed_input_gemm = cute_ext.compile(
        mixed_input_gemm,
        testbed.a_tensor,
        testbed.b_tensor,
        testbed.scale_tensor,
        testbed.zeros_tensor,
        testbed.d_tensor,
    )
    compiled_mixed_input_gemm.engine.initialize()
    compiled_mixed_input_gemm(
        testbed.a_tensor,
        testbed.b_tensor,
        testbed.scale_tensor,
        testbed.zeros_tensor,
        testbed.d_tensor,
    )

    if not skip_ref_check:
        testbed.reference_check(tolerance=tolerance)
        print("check reference: PASS")

    def generate_tensors():
        return testing.JitArguments(*testbed.make_cute_tensors())

    workspace_count = 1
    if use_cold_l2:
        workspace_count = testing.get_workspace_count(
            testbed.workspace_bytes(), warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_mixed_input_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Example of Mixed-Input GEMM on Blackwell."
    )

    cli.add_mnkl_arg(parser, default=(1024, 2048, 4096, 1), strict_length=True)
    cli.add_mma_tiler_arg(parser, strict_length=True)
    # A and B carry different dtypes here, so declare them instead of --ab_dtype.
    parser.add_argument("--a_dtype", type=cutlass.dtype, default=cutlass.Int8)
    parser.add_argument("--b_dtype", type=cutlass.dtype, default=cutlass.Float16)
    cli.add_dtype_args(parser, c=cutlass.Float16)
    # This kernel only builds the K/K/N layout combination.
    cli.add_major_args(parser, a=["k"], b=["k"], c=["n"])
    cli.add_benchmark_args(parser)

    args = parser.parse_args()

    run(
        args.mnkl,
        args.mma_tiler_mn,
        args.a_dtype,
        args.b_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.warmup_iterations,
        args.iterations,
        args.use_cold_l2,
        args.tolerance,
        args.skip_ref_check,
    )
    print("PASS")
