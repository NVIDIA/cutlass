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


class B2BGemmKernel:
    """
    Back-to-back GEMM kernel: D = epilogue(mma1_transform(A @ B0) @ B1)

    where:
        A: (M, K)
        B0: (128, K)
        B1: (N, 128)
        D: (M, N)

    The N of B0 and K of B1 are 128 because the result is stored in TMEM
    and must be CTA-resident.
    """

    EPI2TMA_STORE_STAGE = 1

    def __init__(
        self,
        mn_tiler: tuple[int, int],
        mma_dtype: tuple[Type[Numeric], Type[Numeric]],
        epilogue_op=lambda x: x,
        mma1_transform=lambda x: x,
    ):
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.epilogue_op = epilogue_op
        self.mma1_transform = mma1_transform

    @cute.experimental.jit
    def __call__(
        self, mA: cute.Tensor, mB0: cute.Tensor, mB1: cute.Tensor, mD: cute.Tensor
    ):
        tile_mn = cute.core._pack_shape((*self.mn_tiler, 1))
        div = cute.tiled_divide(mD, tile_mn)
        grid = (div.shape[1], div.shape[2], div.shape[3])
        self.kernel(mA, mB0, mB1, mD).launch(
            grid=grid,
            block=(384, 1, 1),
            cluster=(1, 1, 1),
            smem=cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_100")),
        )

    @cute.experimental.kernel
    def kernel(
        self, mA: cute.Tensor, mB0: cute.Tensor, mB1: cute.Tensor, mD: cute.Tensor
    ):
        use_2cta_instrs = False

        tiled_mma0 = sm100_utils.make_trivial_tiled_mma(
            self.ab_dtype,
            self.ab_dtype,
            cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            cutlass.tensor_utils.LayoutEnum.from_tensor(mB0).mma_major_mode(),
            self.acc_dtype,
            cute.nvgpu.tcgen05.CtaGroup.ONE,
            self.mn_tiler,
        )
        tiled_mma1 = sm100_utils.make_trivial_tiled_mma(
            self.ab_dtype,
            self.ab_dtype,
            cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            cutlass.tensor_utils.LayoutEnum.from_tensor(mB1).mma_major_mode(),
            self.acc_dtype,
            cute.nvgpu.tcgen05.CtaGroup.ONE,
            self.mn_tiler,
            cute.nvgpu.tcgen05.OperandSource.TMEM,
        )

        mma_inst_shape_k = cute.size(tiled_mma0.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        mnk_tiler = (
            self.mn_tiler[0],
            self.mn_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )

        tiler_mk = (mnk_tiler[0], mnk_tiler[2])
        tiler_nk = (mnk_tiler[1], mnk_tiler[2])

        gA_mkl = cute.local_tile(
            mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gB0_nkl = cute.local_tile(
            mB0, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        gB1_nkl = cute.local_tile(
            mB1, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )

        load2mma0_stage = 1
        load2mma1_stage = 1
        mma02transform_stage = 1
        transform2mma1_stage = 1
        mma12epi_stage = 1

        cta_m, cta_n, cta_l = cute.arch.block_idx()
        tid_x, _, _ = cute.arch.thread_idx()

        thr_mma0 = tiled_mma0.get_slice(0)
        tCgA = thr_mma0.partition_A(gA_mkl)
        tCgB0 = thr_mma0.partition_B(gB0_nkl)
        tCgB1 = tiled_mma1.get_slice(0).partition_B(gB1_nkl)

        # Compute A/B/C shared memory layout
        a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma0,
            mnk_tiler,
            self.ab_dtype,
            load2mma0_stage,
        )
        b0_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma0,
            mnk_tiler,
            self.ab_dtype,
            load2mma0_stage,
        )
        b1_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma1,
            mnk_tiler,
            self.ab_dtype,
            load2mma1_stage,
        )

        cta_tile_shape_mnk = cute.shape_div(
            mnk_tiler, (cute.size(tiled_mma0.thr_id.shape), 1, 1)
        )

        # UMMA0 ACC TMEM Layout
        tmem0_layout = cute_ext.make_tmem_layout_acc(
            tiled_mma0, mnk_tiler, mma02transform_stage
        )

        # UMMA1 ACC TMEM Layout
        tmem1_layout = cute_ext.make_tmem_layout_acc(
            tiled_mma1, mnk_tiler, mma12epi_stage
        )

        # UMMA1 Layout for A input
        mma1_a_tmem_layout = cute_ext.make_tmem_layout_a(
            tiled_mma1, tiler_mk, transform2mma1_stage
        )

        # Allocate UMMA Buffers for SMEM inputs of UMMA0
        bufferA = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )

        bufferB0 = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            b0_smem_layout_staged,
            alignment=1024,
        )

        # Allocate UMMA Buffers for SMEM input of UMMA1
        bufferB1 = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            b1_smem_layout_staged,
            alignment=1024,
        )

        # Allocate TMEM buffers for UMMA0 and UMMA1 results
        bufferAcc0 = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.tmem,
            tmem0_layout,
            alignment=16,
        )
        bufferAcc1 = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.tmem,
            tmem1_layout,
            alignment=16,
        )

        # Allocate TMEM buffer for UMMA1 A input
        bufferA1 = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.tmem,
            mma1_a_tmem_layout,
            alignment=16,
        )

        # Create the TMEM copy atom based on the size of transfer within one iteration for mma02transform
        mma02transform_copy_atom_t2r = cute.make_copy_atom(
            cute.nvgpu.tcgen05.Ld32x32bOp(
                cute.nvgpu.tcgen05.Repetition.x64,
                cute.nvgpu.tcgen05.Pack.NONE,
            ),
            self.acc_dtype,
        )
        mma0acc_sliced = bufferAcc0[(None, None), 0, 0, 0]
        zipped_mma0acc_sliced = cute.flat_divide(mma0acc_sliced, tiler_mk)
        mma02transform_copy_atom_t2r = cute.nvgpu.tcgen05.make_tmem_copy(
            mma02transform_copy_atom_t2r, zipped_mma0acc_sliced[None, None, 0, 0]
        )

        # Calculate the per thread destination size per iteration for output of TMEM and input of SMEM
        thr_copy_t2r_transform = mma02transform_copy_atom_t2r.get_slice(tid_x % 128)
        bufferA1_sliced_one_stage = bufferA1[(None, None), None, None, 0]
        div_bufferA1_sliced = cute.flat_divide(bufferA1_sliced_one_stage, tiler_mk)
        tTR_mma02transform = thr_copy_t2r_transform.partition_D(
            div_bufferA1_sliced[None, None, 0, 0, 0, 0]
        )
        acc_d_rmem_layout_mma02transform = tTR_mma02transform.layout

        # Create the TMEM store atom for UMMA A input
        mma02transform_copy_atom_r2t = cute.make_copy_atom(
            cute.nvgpu.tcgen05.St32x32bOp(
                cute.nvgpu.tcgen05.Repetition.x32,
                cute.nvgpu.tcgen05.Unpack.NONE,
            ),
            self.ab_dtype,
        )
        mma02transform_copy_atom_r2t = cute.nvgpu.tcgen05.make_tmem_copy(
            mma02transform_copy_atom_r2t, bufferA1[None, None, None, 0]
        )

        # Allocate RMEM buffers for mma02transform
        bufferRAcc_mma02transform = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.rmem,
            acc_d_rmem_layout_mma02transform,
            alignment=32,
        )
        bufferRA_mma02transform = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.rmem,
            acc_d_rmem_layout_mma02transform,
            alignment=32,
        )

        # Create Pipeline
        # TMA0 -> UMMA0
        load2mma0_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=load2mma0_stage,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
        )

        # TMA1 -> UMMA1
        load2mma1_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=load2mma1_stage,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_TS,
        )

        # UMMA0 -> tcgen05.ld
        mma02transform_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=mma02transform_stage,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=128,
        )

        # tcgen05.st -> UMMA1
        transform2mma1_pipe = cute_ext.AsyncToUMMAPipeline.create(
            num_stages=transform2mma1_stage,
            producer=cute_ext.OperationTypeEnum.SM100_COPY_R2T,
            producer_arv_count=128,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_TS,
        )

        # UMMA1 -> tcgen05.ld
        mma12epi_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=mma12epi_stage,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_TS,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=128,
        )

        tma_store_warp_id = 0

        # tcgen05.st -> TMA store
        epi2tmastore_pipe = cute_ext.TMAStorePipeline(
            stages=self.EPI2TMA_STORE_STAGE,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=tma_store_warp_id,
        )

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        is_tma0_warp = warp_idx == 4
        is_tma1_warp = warp_idx == 5
        is_mma0_warp = warp_idx == 6
        is_mma1_warp = warp_idx == 7
        is_transform_warp = (warp_idx >= 8) & (warp_idx < 12)
        is_epi_warp = warp_idx < 4

        local_tid_x_in_transform = tid_x - 8 * 32

        k0_tile_size = cute.size(gA_mkl, mode=[3])
        k1_tile_size = cute.size(gB1_nkl, mode=[3])

        if is_tma0_warp:
            for k in cutlass.range(0, k0_tile_size, 1, unroll=1):
                load2mma0_stage_token, load2mma0_stage_idx = (
                    load2mma0_pipe.producer_acquire_and_get_stage()
                )

                mbar = cute_ext.get_mbarrier(load2mma0_stage_token)
                gA_k = tCgA[(None, None, None, cta_m, k, cta_l)]
                gB0_k = tCgB0[(None, None, None, 0, k, cta_l)]
                cute_ext.tma_load(
                    gA_k,
                    bufferA[None, None, None, load2mma0_stage_idx],
                    mbar,
                )
                cute_ext.tma_load(
                    gB0_k,
                    bufferB0[None, None, None, load2mma0_stage_idx],
                    mbar,
                )

                load2mma0_pipe.producer_commit_and_advance()

        if is_mma0_warp:
            _, mma02transform_stage_idx = (
                mma02transform_pipe.producer_acquire_and_get_stage()
            )

            mma02transform_accumulators = bufferAcc0[
                None, None, None, mma02transform_stage_idx
            ]

            (updated_a_pipe, _updated_b_pipe) = cute_ext.mainloop_mma(
                tiled_mma0,
                bufferA,
                bufferB0,
                mma02transform_accumulators,
                0,
                k0_tile_size,
                mma_inst_tile_k,
                load2mma0_pipe,
                load2mma0_pipe,
            )
            load2mma0_pipe = updated_a_pipe

            mma02transform_pipe.producer_commit_and_advance()

        if is_tma1_warp:
            for k in cutlass.range(0, k1_tile_size, 1, unroll=1):
                load2mma1_stage_token, load2mma1_stage_idx = (
                    load2mma1_pipe.producer_acquire_and_get_stage()
                )
                mbar = cute_ext.get_mbarrier(load2mma1_stage_token)
                gB1_k = tCgB1[(None, None, None, cta_n, k, cta_l)]
                cute_ext.tma_load(
                    gB1_k,
                    bufferB1[None, None, None, load2mma1_stage_idx],
                    mbar,
                )

                load2mma1_pipe.producer_commit_and_advance()

        if is_transform_warp:
            _, mma02transform_stage_idx = (
                mma02transform_pipe.consumer_wait_and_get_stage()
            )
            accumulators = bufferAcc0[(None, None), 0, 0, mma02transform_stage_idx]
            mma02transform_div = cute.zipped_divide(accumulators, tiler_mk)

            for k in cutlass.range(0, k1_tile_size, 1, unroll=1):
                _, transform2mma1_stage_idx = (
                    transform2mma1_pipe.producer_acquire_and_get_stage()
                )
                cute_ext.partition_and_copy(
                    mma02transform_copy_atom_t2r.get_slice(local_tid_x_in_transform),
                    mma02transform_div[(None, None), k],
                    bufferRAcc_mma02transform,
                )

                # Transform the accumulators
                bufferRA_mma02transform.store(
                    self.mma1_transform(
                        bufferRAcc_mma02transform.load().to(self.ab_dtype)
                    )
                )

                # Copy A from RMEM to TMEM
                cute_ext.partition_and_copy(
                    mma02transform_copy_atom_r2t.get_slice(local_tid_x_in_transform),
                    bufferRA_mma02transform,
                    bufferA1[None, None, None, transform2mma1_stage_idx],
                )

                transform2mma1_pipe.producer_commit_and_advance()

            mma02transform_pipe.consumer_release_and_advance()

        if is_mma1_warp:
            _, mma12epi_stage_idx = mma12epi_pipe.producer_acquire_and_get_stage()

            #  MMA1 -> EPI producer body begin #
            mma12epi_accumulators = bufferAcc1[None, None, None, mma12epi_stage_idx]

            (updated_a_pipe, updated_b_pipe) = cute_ext.mainloop_mma(
                tiled_mma1,
                bufferA1,
                bufferB1,
                mma12epi_accumulators,
                0,
                k1_tile_size,
                mma_inst_tile_k,
                transform2mma1_pipe,
                load2mma1_pipe,
                ab_buffer_same_pipeline=False,
            )
            transform2mma1_pipe = updated_a_pipe
            load2mma1_pipe = updated_b_pipe

            #  MMA1 -> EPI producer body end #
            mma12epi_pipe.producer_commit_and_advance()

        if is_epi_warp:
            _, mma12epi_stage_idx = mma12epi_pipe.consumer_wait_and_get_stage()

            accumulators_sliced = bufferAcc1[(None, None), 0, 0, mma12epi_stage_idx]
            cta_d_tile_coord = (cta_m, cta_n, cta_l)

            epi2tmastore_pipe = cute_ext.epilogue_tma_store(
                cta_tile_shape_mnk,
                use_2cta_instrs,
                accumulators_sliced,
                mD,
                cta_d_tile_coord,
                epi2tmastore_pipe,
                tma_store_warp_id,
                self.epilogue_op,
            )

            mma12epi_pipe.consumer_release_and_advance()


# The intermediate result (A @ B0) lives in TMEM and must be CTA-resident, which
# pins B0's N and B1's K to 128.
B2B_INTERMEDIATE_N = 128


def create_b2b_tensors(l, m, n, k, a_major, b_major, c_major, ab_dtype, c_dtype):
    """Create the four B2B GEMM operands as CPU torch tensors plus CuTe views.

    Shapes follow the kernel contract: A (M, K, L), B0 (128, K, L),
    B1 (N, 128, L), D (M, N, L).
    """
    torch.manual_seed(1111)

    a_torch_cpu = cutlass_torch.matrix(l, m, k, a_major == "m", ab_dtype)
    b0_torch_cpu = cutlass_torch.matrix(
        l, B2B_INTERMEDIATE_N, k, b_major == "n", ab_dtype
    )
    b1_torch_cpu = cutlass_torch.matrix(
        l, n, B2B_INTERMEDIATE_N, b_major == "n", ab_dtype
    )
    d_torch_cpu = cutlass_torch.matrix(l, m, n, c_major == "m", c_dtype)

    a_tensor, _ = cutlass_torch.cute_tensor_like(
        a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    b0_tensor, _ = cutlass_torch.cute_tensor_like(
        b0_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    b1_tensor, _ = cutlass_torch.cute_tensor_like(
        b1_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    d_tensor, d_torch_gpu = cutlass_torch.cute_tensor_like(
        d_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
    )

    return (
        a_tensor,
        b0_tensor,
        b1_tensor,
        d_tensor,
        a_torch_cpu,
        b0_torch_cpu,
        b1_torch_cpu,
        d_torch_cpu,
        d_torch_gpu,
    )


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
    """Run and benchmark the back-to-back GEMM D = (A @ B0) @ B1 on Blackwell.

    Args:
        mnkl: (M, N, K, L); K is the reduction extent of the first GEMM. The
            intermediate extent is fixed at 128 by the TMEM-resident design.
        mma_tiler_mn: MMA tile (M, N). N must be 128 to match the intermediate.
        ab_dtype/c_dtype/acc_dtype: Operand, output and accumulator types.
        a_major/b_major/c_major: Operand layouts.
        warmup_iterations/iterations: Benchmark loop counts.
        use_cold_l2: Cycle fresh workspaces so every iteration misses L2.
        tolerance/skip_ref_check: Reference-check controls.
        kwargs: Absorbs the extra BenchmarkConfig fields that perf_benchmark
            passes to every run(); they are not forwarded any further.

    Returns:
        Execution time in microseconds per iteration.

    Raises:
        ValueError: If mma_tiler_mn[1] is not the fixed intermediate extent
            B2B_INTERMEDIATE_N.
        AssertionError: If reference checking is enabled and the output does
            not match the two-GEMM Torch reference within tolerance.
    """
    cli.print_problem_config(
        "Blackwell B2B GEMM",
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

    if mma_tiler_mn[1] != B2B_INTERMEDIATE_N:
        raise ValueError(
            f"mma_tiler_mn[1] must be {B2B_INTERMEDIATE_N} for B2B GEMM, "
            f"got {mma_tiler_mn[1]}"
        )

    (
        a_tensor,
        b0_tensor,
        b1_tensor,
        d_tensor,
        a_torch_cpu,
        b0_torch_cpu,
        b1_torch_cpu,
        d_torch_cpu,
        d_torch_gpu,
    ) = create_b2b_tensors(l, m, n, k, a_major, b_major, c_major, ab_dtype, c_dtype)

    b2b_gemm = B2BGemmKernel(
        mn_tiler=mma_tiler_mn,
        mma_dtype=(ab_dtype, acc_dtype),
    )

    compiled_b2b_gemm = cute_ext.compile(
        b2b_gemm, a_tensor, b0_tensor, b1_tensor, d_tensor
    )
    compiled_b2b_gemm.engine.initialize()
    compiled_b2b_gemm(a_tensor, b0_tensor, b1_tensor, d_tensor)

    if not skip_ref_check:
        ref_mma0 = torch.einsum("mkl,nkl->mnl", a_torch_cpu, b0_torch_cpu)
        ref = torch.einsum("mkl,nkl->mnl", ref_mma0, b1_torch_cpu)
        torch.testing.assert_close(
            d_torch_gpu.cpu().to(torch.float32),
            ref.to(torch.float32),
            atol=tolerance,
            rtol=1e-05,
        )
        print("check reference: PASS")

    def generate_tensors():
        a_workspace, _ = cutlass_torch.cute_tensor_like(
            a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        b0_workspace, _ = cutlass_torch.cute_tensor_like(
            b0_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        b1_workspace, _ = cutlass_torch.cute_tensor_like(
            b1_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        d_workspace, _ = cutlass_torch.cute_tensor_like(
            d_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
        )
        return testing.JitArguments(
            a_workspace, b0_workspace, b1_workspace, d_workspace
        )

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_torch_cpu.numel() * a_torch_cpu.element_size()
            + b0_torch_cpu.numel() * b0_torch_cpu.element_size()
            + b1_torch_cpu.numel() * b1_torch_cpu.element_size()
            + d_torch_cpu.numel() * d_torch_cpu.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_b2b_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Example of B2B GEMM on Blackwell.")

    cli.add_mnkl_arg(parser, default=(1024, 512, 2048, 1), strict_length=True)
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
