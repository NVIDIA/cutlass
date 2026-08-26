# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
Planar complex GEMM kernel for Blackwell (SM100) GPUs.

Planar complex matrix multiplication stores real and imaginary parts in separate buffers:

    D_real = A_real @ B_real - A_imag @ B_imag
    D_imag = A_real @ B_imag + A_imag @ B_real

This uses 4 MMA operations per k-tile iteration with NEGATE_A for the subtraction.
"""

import argparse
import os
import sys
from typing import Tuple, Type

import torch

import cutlass
from cutlass import cute
from cutlass import testing
from cutlass import torch as cutlass_torch
from cutlass.cute import experimental as cute_ext
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.base_dsl.typing import Numeric

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../"))

from helpers import cli_helper as cli


class PlanarComplexGemmKernel:
    TMA_STORE_STAGE = 4

    def __init__(
        self,
        mn_tiler: tuple[int, int],
        mma_dtype: tuple[Type[Numeric], Type[Numeric]],
    ):
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype = mma_dtype

    @cute.experimental.jit
    def __call__(
        self,
        mA_real: cute.Tensor,
        mA_imag: cute.Tensor,
        mB_real: cute.Tensor,
        mB_imag: cute.Tensor,
        mD_real: cute.Tensor,
        mD_imag: cute.Tensor,
    ):
        tile_mn = cute.core._pack_shape((*self.mn_tiler, 1))
        div = cute.tiled_divide(mD_real, tile_mn)
        grid = (div.shape[1], div.shape[2], div.shape[3])
        self.kernel(mA_real, mA_imag, mB_real, mB_imag, mD_real, mD_imag).launch(
            grid=grid,
            block=(192, 1, 1),
            cluster=(1, 1, 1),
            smem=cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_100")),
        )

    @cute.experimental.kernel
    def kernel(
        self,
        mA_real: cute.Tensor,
        mA_imag: cute.Tensor,
        mB_real: cute.Tensor,
        mB_imag: cute.Tensor,
        mD_real: cute.Tensor,
        mD_imag: cute.Tensor,
    ):
        use_2cta_instrs = False

        c_dtype = mD_real.element_type
        c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(mD_real)

        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.ab_dtype,
            cutlass.tensor_utils.LayoutEnum.from_tensor(mA_real).mma_major_mode(),
            cutlass.tensor_utils.LayoutEnum.from_tensor(mB_real).mma_major_mode(),
            self.acc_dtype,
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

        gA_real_mkl = cute.local_tile(
            mA_real, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gA_imag_mkl = cute.local_tile(
            mA_imag, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gB_real_nkl = cute.local_tile(
            mB_real, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        gB_imag_nkl = cute.local_tile(
            mB_imag, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        gD_real = cute.zipped_divide(mD_real, tiler_mn)
        gD_imag = cute.zipped_divide(mD_imag, tiler_mn)

        mainloop_stage = 2
        acc_stage = 1

        cta_m, cta_n, cta_l = cute.arch.block_idx()
        tid_x, _, _ = cute.arch.thread_idx()

        gD_real_tile = gD_real[((None, None), (cta_m, cta_n, cta_l))]
        gD_imag_tile = gD_imag[((None, None), (cta_m, cta_n, cta_l))]

        thr_mma = tiled_mma.get_slice(0)
        tCgA_real = thr_mma.partition_A(gA_real_mkl)
        tCgA_imag = thr_mma.partition_A(gA_imag_mkl)
        tCgB_real = thr_mma.partition_B(gB_real_nkl)
        tCgB_imag = thr_mma.partition_B(gB_imag_nkl)

        # Compute A/B/C shared memory layouts
        a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mnk_tiler,
            self.ab_dtype,
            mainloop_stage,
        )
        b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma,
            mnk_tiler,
            self.ab_dtype,
            mainloop_stage,
        )
        cta_tile_shape_mnk = cute.shape_div(mnk_tiler, (tiled_mma.thr_id.shape, 1, 1))
        epi_tile = (128, 32)
        sc_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            c_dtype,
            c_layout,
            epi_tile,
            self.TMA_STORE_STAGE,
        )

        # TMEM layout (one stage each for real and imag accumulators)
        tmem_layout = cute_ext.make_tmem_layout_acc(tiled_mma, mnk_tiler, acc_stage)

        # Allocate SMEM buffers for A and B (real + imag)
        bufferA_real = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )
        bufferA_imag = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )
        bufferB_real = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )
        bufferB_imag = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )

        # Allocate TMEM accumulators (separate for real and imag)
        bufferAcc_real = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.tmem,
            tmem_layout,
            alignment=16,
        )
        bufferAcc_imag = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.tmem,
            tmem_layout,
            alignment=16,
        )

        # Allocate SMEM buffers for epilogue store (real + imag)
        bufferC_real = cute_ext.allocate(
            c_dtype,
            cutlass.AddressSpace.smem,
            sc_smem_layout_staged,
            alignment=1024,
        )
        bufferC_imag = cute_ext.allocate(
            c_dtype,
            cutlass.AddressSpace.smem,
            sc_smem_layout_staged,
            alignment=1024,
        )

        # Create TMEM load atom for epilogue
        copy_atom_t2r = sm100_utils.get_tmem_load_op(
            cta_tile_shape_mnk,
            c_layout,
            c_dtype,
            self.acc_dtype,
            epi_tile,
            use_2cta_instrs,
        )

        # Take one stage of the TMEM buffer for epilogue tiling
        accumulators0 = cute.zipped_divide(bufferAcc_real, ((epi_tile), 1))
        acc_epi_div0_one_stage = accumulators0[((None, None), 0), 0]

        tiled_copy_t2r = cute.nvgpu.tcgen05.make_tmem_copy(
            copy_atom_t2r, acc_epi_div0_one_stage
        )

        # Calculate per-thread RMEM layout for epilogue
        thr_copy_t2r = tiled_copy_t2r.get_slice(tid_x)
        gC_mnl_epi_real = cute.flat_divide(gD_real_tile, epi_tile)
        gC_mnl_epi_imag = cute.flat_divide(gD_imag_tile, epi_tile)
        tTR_gC_real = thr_copy_t2r.partition_D(gC_mnl_epi_real)
        tTR_gC_imag = thr_copy_t2r.partition_D(gC_mnl_epi_imag)
        acc_d_rmem_layout_real = tTR_gC_real[(None, None, None, 0, 0)].layout
        acc_d_rmem_layout_imag = tTR_gC_imag[(None, None, None, 0, 0)].layout

        # Allocate RMEM buffers
        bufferRAcc_real = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.rmem,
            acc_d_rmem_layout_real,
            alignment=32,
        )
        bufferRAcc_imag = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.rmem,
            acc_d_rmem_layout_imag,
            alignment=32,
        )
        bufferRD_real = cute_ext.allocate(
            c_dtype,
            cutlass.AddressSpace.rmem,
            acc_d_rmem_layout_real,
            alignment=32,
        )
        bufferRD_imag = cute_ext.allocate(
            c_dtype,
            cutlass.AddressSpace.rmem,
            acc_d_rmem_layout_imag,
            alignment=32,
        )

        # Create Pipelines
        # TMA -> UMMA
        mainloop_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=mainloop_stage,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
        )

        # UMMA -> tcgen05.ld
        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=acc_stage,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=128,
        )

        tma_store_warp_id = 0

        # st.shared -> TMA store
        tma_store_pipe = cute_ext.TMAStorePipeline(
            stages=self.TMA_STORE_STAGE,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=tma_store_warp_id,
        )

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        is_tma_warp = warp_idx == 5
        is_mma_warp = warp_idx == 4
        is_epi_warp = warp_idx < 4
        k_tile_size = cute.size(gA_real_mkl, mode=[3])

        # ---- TMA Load Producer ----
        if is_tma_warp:
            for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                gA_real_k = tCgA_real[(None, None, None, cta_m, k, cta_l)]
                gA_imag_k = tCgA_imag[(None, None, None, cta_m, k, cta_l)]
                gB_real_k = tCgB_real[(None, None, None, cta_n, k, cta_l)]
                gB_imag_k = tCgB_imag[(None, None, None, cta_n, k, cta_l)]
                producer_stage_token, idx = (
                    mainloop_pipe.producer_acquire_and_get_stage()
                )
                mbar = cute_ext.get_mbarrier(producer_stage_token)
                bufferA_real_sliced = bufferA_real[None, None, None, idx]
                bufferA_imag_sliced = bufferA_imag[None, None, None, idx]
                bufferB_real_sliced = bufferB_real[None, None, None, idx]
                bufferB_imag_sliced = bufferB_imag[None, None, None, idx]
                cute_ext.tma_load(
                    gA_real_k,
                    bufferA_real_sliced,
                    mbar,
                )
                cute_ext.tma_load(
                    gA_imag_k,
                    bufferA_imag_sliced,
                    mbar,
                )
                cute_ext.tma_load(
                    gB_real_k,
                    bufferB_real_sliced,
                    mbar,
                )
                cute_ext.tma_load(
                    gB_imag_k,
                    bufferB_imag_sliced,
                    mbar,
                )
                mainloop_pipe.producer_commit_and_advance()

        # ---- MMA Compute (Complex Arithmetic) ----
        # realAcc =  realA * realB - imagA * imagB
        # imagAcc =  realA * imagB + imagA * realB
        if is_mma_warp:
            producer_stage_token, idx = acc_pipe.producer_acquire_and_get_stage()
            accumulators_real = bufferAcc_real[None, None, None, idx]
            accumulators_imag = bufferAcc_imag[None, None, None, idx]
            mma_atom_real = cute.make_mma_atom(tiled_mma.op)
            mma_atom_real.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)
            mma_atom_imag = cute.make_mma_atom(tiled_mma.op)
            mma_atom_imag.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)
            for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                _, mainloop_idx = mainloop_pipe.consumer_wait_and_get_stage()
                for k_tile in cutlass.range(mma_inst_tile_k, unroll_full=True):
                    bufferA_real_sliced = bufferA_real[None, None, k_tile, mainloop_idx]
                    bufferA_imag_sliced = bufferA_imag[None, None, k_tile, mainloop_idx]
                    bufferB_real_sliced = bufferB_real[None, None, k_tile, mainloop_idx]
                    bufferB_imag_sliced = bufferB_imag[None, None, k_tile, mainloop_idx]

                    # realAcc += realA * realB
                    cute_ext.dot(
                        mma_atom_real,
                        bufferA_real_sliced,
                        bufferB_real_sliced,
                        accumulators_real,
                    )
                    mma_atom_real.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)
                    # realAcc -= imagA * imagB  (via NEGATE_A)
                    mma_atom_real.set(cute.nvgpu.tcgen05.Field.NEGATE_A, True)
                    cute_ext.dot(
                        mma_atom_real,
                        bufferA_imag_sliced,
                        bufferB_imag_sliced,
                        accumulators_real,
                    )
                    mma_atom_real.set(cute.nvgpu.tcgen05.Field.NEGATE_A, False)
                    # imagAcc += realA * imagB
                    cute_ext.dot(
                        mma_atom_imag,
                        bufferA_real_sliced,
                        bufferB_imag_sliced,
                        accumulators_imag,
                    )
                    mma_atom_imag.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)
                    # imagAcc += imagA * realB
                    cute_ext.dot(
                        mma_atom_imag,
                        bufferA_imag_sliced,
                        bufferB_real_sliced,
                        accumulators_imag,
                    )

                mainloop_pipe.consumer_release_and_advance()
            acc_pipe.producer_commit_and_advance()

        # ---- Epilogue (TMEM -> RMEM -> SMEM -> GMEM for real + imag) ----
        if is_epi_warp:
            _, idx = acc_pipe.consumer_wait_and_get_stage()
            accumulators_real = bufferAcc_real[(None, None), 0, 0, idx]
            accumulators_imag = bufferAcc_imag[(None, None), 0, 0, idx]
            acc_epi_div_real = cute.flat_divide(accumulators_real, epi_tile)
            acc_epi_div_imag = cute.flat_divide(accumulators_imag, epi_tile)
            subtile_cnt = cute.size(acc_epi_div_real.shape, mode=[3])

            for mn in range(subtile_cnt):
                # TMEM -> RMEM
                cute_ext.partition_and_copy(
                    tiled_copy_t2r.get_slice(tid_x),
                    acc_epi_div_real[None, None, 0, mn],
                    bufferRAcc_real,
                )
                cute_ext.partition_and_copy(
                    tiled_copy_t2r.get_slice(tid_x),
                    acc_epi_div_imag[None, None, 0, mn],
                    bufferRAcc_imag,
                )
                racc_real0 = bufferRAcc_real.load().to(c_dtype)
                racc_imag0 = bufferRAcc_imag.load().to(c_dtype)
                bufferRD_real.store(racc_real0)
                bufferRD_imag.store(racc_imag0)

                tma_store_pipe.acquire_sync()
                store_idx = tma_store_pipe.get_index()

                # RMEM -> SMEM
                tiled_copy_r2s = cute.make_tiled_copy_D(
                    cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), c_dtype),
                    tiled_copy_t2r,
                )

                cute_ext.partition_and_copy(
                    tiled_copy_r2s.get_slice(tid_x),
                    bufferRD_real,
                    bufferC_real[None, None, store_idx],
                )
                cute_ext.partition_and_copy(
                    tiled_copy_r2s.get_slice(tid_x),
                    bufferRD_imag,
                    bufferC_imag[None, None, store_idx],
                )

                tma_store_pipe.commit_sync()

                # SMEM -> GMEM
                if warp_idx == tma_store_warp_id:
                    cute_ext.tma_store(
                        bufferC_real[None, None, store_idx],
                        gC_mnl_epi_real[None, None, 0, mn],
                    )
                    cute_ext.tma_store(
                        bufferC_imag[None, None, store_idx],
                        gC_mnl_epi_imag[None, None, 0, mn],
                    )

                tma_store_pipe.release_advance()

            tma_store_pipe.tail()
            acc_pipe.consumer_release_and_advance()


def run(
    mnkl: Tuple[int, int, int, int],
    mma_tiler_mn: Tuple[int, int],
    ab_dtype: Type[Numeric],
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
    """Run and benchmark the planar complex GEMM on Blackwell.

    Computes D_real = A_real @ B_real - A_imag @ B_imag and
    D_imag = A_real @ B_imag + A_imag @ B_real, i.e. 4 real GEMMs.

    Planar layout: the real and imaginary planes are separate tensors, each a
    plain real-valued (M, K, L) / (N, K, L) / (M, N, L) matrix with the
    a_major/b_major/c_major layout. The kernel takes six tensors (A_real,
    A_imag, B_real, B_imag, D_real, D_imag); nothing is interleaved.

    Args:
        mnkl: Problem size (M, N, K, L) of each real-valued GEMM.
        mma_tiler_mn: MMA tile (M, N).
        ab_dtype/c_dtype/acc_dtype: Operand, output and accumulator types.
        a_major/b_major/c_major: Operand layouts, applied to both planes.
        warmup_iterations/iterations: Benchmark loop counts.
        use_cold_l2: Cycle fresh workspaces so every iteration misses L2.
        tolerance/skip_ref_check: Reference-check controls.
        kwargs: Absorbs the extra BenchmarkConfig fields that perf_benchmark
            passes to every run(); they are not forwarded any further.

    Returns:
        Execution time in microseconds per iteration.

    Raises:
        AssertionError: If reference checking is enabled and either output
            plane does not match the Torch reference within tolerance.
        Exception: Compilation failures from cute_ext.compile propagate
            unchanged, e.g. when mma_tiler_mn is not supported for the
            requested dtypes.
    """
    cli.print_problem_config(
        "Blackwell Planar Complex GEMM",
        mnkl,
        dtypes={"AB": ab_dtype, "C": c_dtype, "Acc": acc_dtype},
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

    torch.manual_seed(111)
    a_real_cpu = cutlass_torch.matrix(l, m, k, a_major == "m", ab_dtype)
    a_imag_cpu = cutlass_torch.matrix(l, m, k, a_major == "m", ab_dtype)
    b_real_cpu = cutlass_torch.matrix(l, n, k, b_major == "n", ab_dtype)
    b_imag_cpu = cutlass_torch.matrix(l, n, k, b_major == "n", ab_dtype)
    d_real_cpu = cutlass_torch.matrix(l, m, n, c_major == "m", c_dtype)
    d_imag_cpu = cutlass_torch.matrix(l, m, n, c_major == "m", c_dtype)

    def to_cute(torch_cpu, dtype):
        return cutlass_torch.cute_tensor_like(
            torch_cpu, dtype, is_dynamic_layout=True, assumed_align=16
        )

    a_real_tensor, _ = to_cute(a_real_cpu, ab_dtype)
    a_imag_tensor, _ = to_cute(a_imag_cpu, ab_dtype)
    b_real_tensor, _ = to_cute(b_real_cpu, ab_dtype)
    b_imag_tensor, _ = to_cute(b_imag_cpu, ab_dtype)
    d_real_tensor, d_real_gpu = to_cute(d_real_cpu, c_dtype)
    d_imag_tensor, d_imag_gpu = to_cute(d_imag_cpu, c_dtype)

    planar_gemm = PlanarComplexGemmKernel(
        mn_tiler=mma_tiler_mn,
        mma_dtype=(ab_dtype, acc_dtype),
    )

    compiled_planar_gemm = cute_ext.compile(
        planar_gemm,
        a_real_tensor,
        a_imag_tensor,
        b_real_tensor,
        b_imag_tensor,
        d_real_tensor,
        d_imag_tensor,
    )
    compiled_planar_gemm.engine.initialize()
    compiled_planar_gemm(
        a_real_tensor,
        a_imag_tensor,
        b_real_tensor,
        b_imag_tensor,
        d_real_tensor,
        d_imag_tensor,
    )

    if not skip_ref_check:
        ref_real = torch.einsum("mkl,nkl->mnl", a_real_cpu, b_real_cpu) - torch.einsum(
            "mkl,nkl->mnl", a_imag_cpu, b_imag_cpu
        )
        ref_imag = torch.einsum("mkl,nkl->mnl", a_real_cpu, b_imag_cpu) + torch.einsum(
            "mkl,nkl->mnl", a_imag_cpu, b_real_cpu
        )
        torch.testing.assert_close(
            d_real_gpu.cpu().to(torch.float32),
            ref_real.to(torch.float32),
            atol=tolerance,
            rtol=1e-05,
        )
        torch.testing.assert_close(
            d_imag_gpu.cpu().to(torch.float32),
            ref_imag.to(torch.float32),
            atol=tolerance,
            rtol=1e-05,
        )
        print("check reference: PASS")

    def generate_tensors():
        return testing.JitArguments(
            to_cute(a_real_cpu, ab_dtype)[0],
            to_cute(a_imag_cpu, ab_dtype)[0],
            to_cute(b_real_cpu, ab_dtype)[0],
            to_cute(b_imag_cpu, ab_dtype)[0],
            to_cute(d_real_cpu, c_dtype)[0],
            to_cute(d_imag_cpu, c_dtype)[0],
        )

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = sum(
            t.numel() * t.element_size()
            for t in (
                a_real_cpu,
                a_imag_cpu,
                b_real_cpu,
                b_imag_cpu,
                d_real_cpu,
                d_imag_cpu,
            )
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_planar_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Example of Planar Complex GEMM on Blackwell."
    )

    cli.add_mnkl_arg(parser, default=(4096, 4096, 4096, 1), strict_length=True)
    cli.add_mma_tiler_arg(parser, strict_length=True)
    cli.add_dtype_args(parser, ab=cutlass.Float16, c=cutlass.Float16)
    cli.add_major_args(parser)
    cli.add_benchmark_args(parser)

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
        args.warmup_iterations,
        args.iterations,
        args.use_cold_l2,
        args.tolerance,
        args.skip_ref_check,
    )
    print("PASS")
