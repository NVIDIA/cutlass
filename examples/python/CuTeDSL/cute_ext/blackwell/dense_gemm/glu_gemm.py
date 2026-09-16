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

"""
This kernel is a implementation of a gated linear unit GEMM with TMA load and TMA store.

D = (A @ B0) * gated_activation(A @ B1) where @ is a matrix multiplication and * is a element-wise multiplication

For reference, see: https://arxiv.org/pdf/2002.05202
"""


class GatedLinearUnitGemmKernel:
    TMA_STORE_STAGE = 4

    def __init__(
        self,
        mn_tiler: tuple[int, int],
        mma_dtype: tuple[Type[Numeric], Type[Numeric]],
        gate_activation=lambda x: x,
    ):
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.gate_activation = gate_activation

    @cute.experimental.jit
    def __call__(
        self, mA: cute.Tensor, mB0: cute.Tensor, mB1: cute.Tensor, mD: cute.Tensor
    ):
        tile_mn = cute.core._pack_shape((*self.mn_tiler, 1))
        div = cute.tiled_divide(mD, tile_mn)
        grid = (div.shape[1], div.shape[2], div.shape[3])
        self.kernel(mA, mB0, mB1, mD).launch(
            grid=grid,
            block=(192, 1, 1),
            cluster=(1, 1, 1),
            smem=cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_100")),
        )

    @cute.experimental.kernel
    def kernel(
        self, mA: cute.Tensor, mB0: cute.Tensor, mB1: cute.Tensor, mD: cute.Tensor
    ):
        use_2cta_instrs = False

        c_dtype = mD.element_type
        c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(mD)

        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.ab_dtype,
            self.ab_dtype,
            cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            cutlass.tensor_utils.LayoutEnum.from_tensor(mB0).mma_major_mode(),
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

        gA_mkl = cute.local_tile(
            mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gB0_nkl = cute.local_tile(
            mB0, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        gB1_nkl = cute.local_tile(
            mB1, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        gD = cute.zipped_divide(mD, tiler_mn)

        mainloop_stage = 2
        acc_stage = 1

        cta_m, cta_n, cta_l = cute.arch.block_idx()
        tid_x, _, _ = cute.arch.thread_idx()

        gD_tile = gD[(None, None), (cta_m, cta_n, cta_l)]

        thr_mma = tiled_mma.get_slice(0)
        tCgA = thr_mma.partition_A(gA_mkl)
        tCgB0 = thr_mma.partition_B(gB0_nkl)
        tCgB1 = thr_mma.partition_B(gB1_nkl)

        # Compute A/B shared memory layouts
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

        cta_tile_shape_mnk = cute.shape_div(
            mnk_tiler, (cute.size(tiled_mma.thr_id.shape), 1, 1)
        )

        epi_tile = (128, 32)
        sc_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            c_dtype,
            c_layout,
            epi_tile,
            self.TMA_STORE_STAGE,
        )

        # UMMA ACC TMEM Layout
        tmem_layout = cute_ext.make_tmem_layout_acc(tiled_mma, mnk_tiler, 2 * acc_stage)

        # Allocate UMMA Buffers
        bufferA = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )
        bufferB0 = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )
        bufferB1 = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )

        bufferAcc0 = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.tmem,
            tmem_layout,
            alignment=16,
        )

        # Allocate SMEM buffer for C
        bufferC = cute_ext.allocate(
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

        # Take only one stage of the TMEM buffer
        accumulators0 = cute.zipped_divide(bufferAcc0, ((epi_tile), 1))
        acc_epi_div0 = accumulators0[((None, None), 0), 0]

        # Create the TMEM copy atom based on the size of transfer within one iteration of epilogue
        tiled_copy_t2r = cute.nvgpu.tcgen05.make_tmem_copy(copy_atom_t2r, acc_epi_div0)

        # Calculate the per thread destination size per iteration for output of TMEM and input of SMEM
        thr_copy_t2r = tiled_copy_t2r.get_slice(tid_x)
        gC_mnl_epi = cute.flat_divide(gD_tile, epi_tile)
        tTR_gC = thr_copy_t2r.partition_D(gC_mnl_epi)
        acc_d_rmem_layout = cute.make_fragment_like(
            tTR_gC[(None, None, None, 0, 0)].layout
        )

        # Allocate RMEM buffers
        bufferRAcc0 = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.rmem,
            acc_d_rmem_layout,
            alignment=32,
        )
        bufferRAcc1 = cute_ext.allocate(
            self.acc_dtype,
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

        k_tile_size = cute.size(gA_mkl, mode=[3])

        if is_tma_warp:
            for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                gA_k = tCgA[(None, None, None, cta_m, k, cta_l)]
                gB0_k = tCgB0[(None, None, None, cta_n, k, cta_l)]
                gB1_k = tCgB1[(None, None, None, cta_n, k, cta_l)]
                producer_stage_token, idx = (
                    mainloop_pipe.producer_acquire_and_get_stage()
                )
                mbar = cute_ext.get_mbarrier(producer_stage_token)
                bufferA_sliced = bufferA[None, None, None, idx]
                bufferB0_sliced = bufferB0[None, None, None, idx]
                bufferB1_sliced = bufferB1[None, None, None, idx]
                cute_ext.tma_load(
                    gA_k,
                    bufferA_sliced,
                    mbar,
                )
                cute_ext.tma_load(
                    gB0_k,
                    bufferB0_sliced,
                    mbar,
                )
                cute_ext.tma_load(
                    gB1_k,
                    bufferB1_sliced,
                    mbar,
                )
                mainloop_pipe.producer_commit_and_advance()

        if is_mma_warp:
            producer_stage_token, idx = acc_pipe.producer_acquire_and_get_stage()
            accumulators0_sliced = bufferAcc0[None, None, None, 2 * idx]
            accumulators1_sliced = bufferAcc0[None, None, None, 2 * idx + 1]
            mma_atom = cute.make_mma_atom(tiled_mma.op)
            mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)
            for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                _, mainloop_idx = mainloop_pipe.consumer_wait_and_get_stage()
                bufferA_sliced_stage = bufferA[None, None, None, mainloop_idx]
                bufferB0_sliced_stage = bufferB0[None, None, None, mainloop_idx]
                bufferB1_sliced_stage = bufferB1[None, None, None, mainloop_idx]
                for k_tile in cutlass.range(mma_inst_tile_k, unroll_full=True):
                    bufferA_sliced = bufferA_sliced_stage[None, None, k_tile]
                    bufferB0_sliced = bufferB0_sliced_stage[None, None, k_tile]
                    bufferB1_sliced = bufferB1_sliced_stage[None, None, k_tile]

                    cute_ext.dot(
                        mma_atom,
                        bufferA_sliced,
                        bufferB0_sliced,
                        accumulators0_sliced,
                    )
                    cute_ext.dot(
                        mma_atom,
                        bufferA_sliced,
                        bufferB1_sliced,
                        accumulators1_sliced,
                    )
                    mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)

                mainloop_pipe.consumer_release_and_advance()
            acc_pipe.producer_commit_and_advance()

        # ---- Custom Epilogue (Gating + TMA Store) ----
        if is_epi_warp:
            _, idx = acc_pipe.consumer_wait_and_get_stage()
            accumulators0_sliced = bufferAcc0[((None, None), 0, 0, 2 * idx)]
            accumulators1_sliced = bufferAcc0[((None, None), 0, 0, 2 * idx + 1)]
            acc_epi_div0_tiled = cute.flat_divide(accumulators0_sliced, epi_tile)
            acc_epi_div1_tiled = cute.flat_divide(accumulators1_sliced, epi_tile)
            subtile_cnt = cute.size(acc_epi_div0_tiled.shape, mode=[3])

            for mn in range(subtile_cnt):
                # TMEM -> RMEM
                cute_ext.partition_and_copy(
                    tiled_copy_t2r.get_slice(tid_x),
                    acc_epi_div0_tiled[None, None, 0, mn],
                    bufferRAcc0,
                )
                cute_ext.partition_and_copy(
                    tiled_copy_t2r.get_slice(tid_x),
                    acc_epi_div1_tiled[None, None, 0, mn],
                    bufferRAcc1,
                )
                racc0 = bufferRAcc0.load().to(c_dtype)
                racc1 = bufferRAcc1.load().to(c_dtype)
                gated_racc1 = self.gate_activation(racc1)
                gated_result = racc0 * gated_racc1
                bufferRD.store(gated_result)

                tma_store_pipe.acquire_sync()
                store_idx = tma_store_pipe.get_index()
                # RMEM -> SMEM
                copy_atom_r2s = sm100_utils.get_smem_store_op(
                    c_layout,
                    c_dtype,
                    self.acc_dtype,
                    tiled_copy_t2r,
                )
                tiled_copy_r2s = cute.make_tiled_copy_D(copy_atom_r2s, tiled_copy_t2r)
                cute_ext.partition_and_copy(
                    tiled_copy_r2s.get_slice(tid_x),
                    bufferRD,
                    bufferC[None, None, store_idx],
                )
                tma_store_pipe.commit_sync()

                if warp_idx == tma_store_warp_id:
                    bufferEpi_partitioned_tma_store = bufferC[None, None, store_idx]
                    gd_div_sliced = gC_mnl_epi[None, None, 0, mn]
                    cute_ext.tma_store(
                        bufferEpi_partitioned_tma_store,
                        gd_div_sliced,
                    )

                tma_store_pipe.release_advance()

            tma_store_pipe.tail()
            acc_pipe.consumer_release_and_advance()


# Gate activations from the GLU-variants paper (https://arxiv.org/pdf/2002.05202).
# Each entry pairs the in-kernel CuTe form with its torch reference.
GLU_GATE_ACTIVATIONS = {
    "reglu": (
        lambda dtype: lambda x: cute.where(x > 0, x, cute.full_like(x, 0)),
        torch.relu,
    ),
    "geglu": (
        lambda dtype: lambda x: (x * 0.5 * (1 + cute.erf(x / 1.41421356237))).to(dtype),
        torch.nn.functional.gelu,
    ),
    "swiglu": (
        lambda dtype: lambda x: (x / (1 + cute.exp2(x * -1.4426950408889634))).to(
            dtype
        ),
        lambda x: x * torch.nn.functional.sigmoid(x),
    ),
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
    gate_activation: str = "swiglu",
    warmup_iterations: int = 0,
    iterations: int = 1,
    use_cold_l2: bool = False,
    tolerance: float = 1e-01,
    skip_ref_check: bool = False,
    **kwargs,
):
    """Run and benchmark the GLU GEMM D = (A @ B0) * gate(A @ B1) on Blackwell.

    Args:
        mnkl: Problem size (M, N, K, L).
        mma_tiler_mn: MMA tile (M, N).
        ab_dtype/c_dtype/acc_dtype: Operand, output and accumulator types.
        a_major/b_major/c_major: Operand layouts.
        gate_activation: One of GLU_GATE_ACTIVATIONS ("reglu", "geglu", "swiglu").
        warmup_iterations/iterations: Benchmark loop counts.
        use_cold_l2: Cycle fresh workspaces so every iteration misses L2.
        tolerance/skip_ref_check: Reference-check controls.
        kwargs: Absorbs the extra BenchmarkConfig fields that perf_benchmark
            passes to every run(); they are not forwarded any further.

    Returns:
        Execution time in microseconds per iteration.

    Raises:
        ValueError: If gate_activation is not one of GLU_GATE_ACTIVATIONS.
        AssertionError: If reference checking is enabled and the output does
            not match the Torch reference within tolerance.
    """
    cli.print_problem_config(
        "Blackwell GLU GEMM",
        mnkl,
        dtypes={"AB": ab_dtype, "C": c_dtype, "Acc": acc_dtype},
        majors={"A": a_major, "B": b_major, "C": c_major},
        mma_tiler_mn=mma_tiler_mn,
    )
    print(f"Gate activation: {gate_activation}")
    cli.print_benchmark_config(
        tolerance=tolerance,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        skip_ref_check=skip_ref_check,
        use_cold_l2=use_cold_l2,
    )

    m, n, k, l = mnkl

    if gate_activation not in GLU_GATE_ACTIVATIONS:
        raise ValueError(
            f"Unknown gate_activation {gate_activation!r}, "
            f"expected one of {sorted(GLU_GATE_ACTIVATIONS)}"
        )
    make_cute_gate, torch_gate = GLU_GATE_ACTIVATIONS[gate_activation]
    cute_gate = make_cute_gate(c_dtype)

    torch.manual_seed(1111)
    a_torch_cpu = cutlass_torch.matrix(l, m, k, a_major == "m", ab_dtype)
    b0_torch_cpu = cutlass_torch.matrix(l, n, k, b_major == "n", ab_dtype)
    b1_torch_cpu = cutlass_torch.matrix(l, n, k, b_major == "n", ab_dtype)
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

    glu_gemm = GatedLinearUnitGemmKernel(
        mn_tiler=mma_tiler_mn,
        mma_dtype=(ab_dtype, acc_dtype),
        gate_activation=cute_gate,
    )

    compiled_glu_gemm = cute_ext.compile(
        glu_gemm, a_tensor, b0_tensor, b1_tensor, d_tensor
    )
    compiled_glu_gemm.engine.initialize()
    compiled_glu_gemm(a_tensor, b0_tensor, b1_tensor, d_tensor)

    if not skip_ref_check:
        ref_c0 = torch.einsum("mkl,nkl->mnl", a_torch_cpu, b0_torch_cpu)
        ref_c1 = torch.einsum("mkl,nkl->mnl", a_torch_cpu, b1_torch_cpu)
        ref = ref_c0 * torch_gate(ref_c1)
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
        compiled_glu_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Example of GLU GEMM on Blackwell.")

    cli.add_mnkl_arg(parser, default=(4096, 2048, 7168, 1), strict_length=True)
    cli.add_mma_tiler_arg(parser, default=(128, 256), strict_length=True)
    cli.add_dtype_args(parser, ab=cutlass.Float16, c=cutlass.Float16)
    cli.add_major_args(parser)
    cli.add_benchmark_args(parser)

    parser.add_argument(
        "--gate_activation",
        choices=sorted(GLU_GATE_ACTIVATIONS),
        default="swiglu",
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
        args.gate_activation,
        args.warmup_iterations,
        args.iterations,
        args.use_cold_l2,
        args.tolerance,
        args.skip_ref_check,
    )
    print("PASS")
