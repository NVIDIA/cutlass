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
import os
import sys

import torch
from typing import Type, Tuple

import cutlass
from cutlass.cute import experimental as cute_ext
from cutlass.base_dsl.typing import Numeric
from cutlass import cute as cute
from cutlass import utils
from cutlass import torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils

from cutlass import testing

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../"))

from helpers import cli_helper as cli


class PersistentDenseGemmKernel:
    def __init__(
        self,
        mn_tiler: tuple[int, int],
        mma_dtype: tuple[Type[Numeric], Type[Numeric]],
        tmem_output_dtype: Type[Numeric],
        max_active_clusters: int,
        epilogue_op=lambda x: x,
        use_2cta_instrs: bool = False,
        cluster_shape_mn: Tuple[int, int] = (2, 1),
        fallback_cluster_shape_mn: Tuple[int, int] = None,
        max_active_fallback_clusters: int = None,
        mainloop_stage: int = 4,
        acc_stage: int = 2,
        tma_store_stage: int = 2,
        swizzle_size: int = 1,
        raster_along_m: bool = True,
    ):
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.tmem_output_dtype = tmem_output_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.mainloop_stage = mainloop_stage
        self.acc_stage = acc_stage
        self.TMA_STORE_STAGE = tma_store_stage
        self.epilogue_op = epilogue_op
        self.swizzle_size = swizzle_size
        self.raster_along_m = raster_along_m
        # Validate tuning inputs up front so invalid values fail with a clear
        # message instead of much later during pipeline/layout construction.
        for _name, _val in (
            ("mainloop_stage", mainloop_stage),
            ("acc_stage", acc_stage),
            ("tma_store_stage", tma_store_stage),
            ("swizzle_size", swizzle_size),
        ):
            if _val <= 0:
                raise ValueError(f"{_name} must be a positive integer, got {_val}")
        self.cluster_shape = (cluster_shape_mn[0], cluster_shape_mn[1], 1)
        cluster_shape_mn_selfcast = (2, 1) if use_2cta_instrs else (1, 1)
        self.use_tma_multicast = cluster_shape_mn != cluster_shape_mn_selfcast
        self.max_active_clusters = max_active_clusters
        if fallback_cluster_shape_mn is None:
            self.fallback_cluster_shape = self.cluster_shape
            self.max_active_fallback_clusters = max_active_clusters
        else:
            if fallback_cluster_shape_mn[0] < 1 or fallback_cluster_shape_mn[1] < 1:
                raise ValueError(
                    "fallback_cluster_shape_mn dims must be >= 1, got "
                    f"{fallback_cluster_shape_mn}"
                )
            if use_2cta_instrs and (
                fallback_cluster_shape_mn[0] < 2
                or fallback_cluster_shape_mn[0] % 2 != 0
            ):
                raise ValueError(
                    "2CTA mode requires fallback_cluster_shape_mn[0] >= 2 and "
                    f"a multiple of 2, got {fallback_cluster_shape_mn[0]}"
                )
            self.fallback_cluster_shape = (
                fallback_cluster_shape_mn[0],
                fallback_cluster_shape_mn[1],
                1,
            )
            self.max_active_fallback_clusters = (
                max_active_fallback_clusters
                if max_active_fallback_clusters is not None
                else max_active_clusters
            )

    @cute.experimental.jit
    def __call__(self, mA: cute.Tensor, mB: cute.Tensor, mD: cute.Tensor):
        cta_tile_mnk = (
            self.mn_tiler[0] // 2 if self.use_2cta_instrs else self.mn_tiler[0],
            self.mn_tiler[1],
            1,
        )
        num_ctas_mnl = cute.ceil_div(mD.shape, cta_tile_mnk)
        sched_params = utils.PersistentTileSchedulerParams(
            num_ctas_mnl,
            self.cluster_shape,
            swizzle_size=self.swizzle_size,
            raster_along_m=self.raster_along_m,
            fallback_cluster_shape_mnk=self.fallback_cluster_shape,
        )
        grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            sched_params, self.max_active_clusters
        )
        self.kernel(mA, mB, mD, sched_params).launch(
            grid=grid,
            block=(192, 1, 1),
            cluster=self.cluster_shape,
            fallback_cluster=self.fallback_cluster_shape,
            smem=cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_100")),
        )

    @cute.experimental.kernel
    def kernel(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mD: cute.Tensor,
        sched_params: utils.PersistentTileSchedulerParams,
    ):
        # Determine CTA group based on 2-CTA mode
        if cutlass.const_expr(self.use_2cta_instrs):
            cta_group = cute.nvgpu.tcgen05.CtaGroup.TWO
        else:
            cta_group = cute.nvgpu.tcgen05.CtaGroup.ONE

        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.ab_dtype,
            self.ab_dtype,
            cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            cutlass.tensor_utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
            self.acc_dtype,
            cta_group,
            self.mn_tiler,
        )

        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4

        # Tiler for 2xSM if use 2xSM, otherwise it's for 1 SM/cta.
        mnk_tiler = (
            self.mn_tiler[0],
            self.mn_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )

        # Tiler down to 1 SM
        # For 2xSM, each CTA loads half of mma_M for A and half of mma_N for B.
        # The accumulator is split along M only (each CTA holds full N columns).
        num_mma_ctas = cute.size(tiled_mma.thr_id.shape)
        cta_tile_shape_mnk = cute.shape_div(mnk_tiler, (num_mma_ctas, 1, 1))
        # A is tiled (M/2, K) for 2CTA
        a_tiler_mk = (cta_tile_shape_mnk[0], cta_tile_shape_mnk[2])
        # B is tiled (N/2, K) for 2CTA
        b_tiler_nk = (cta_tile_shape_mnk[1] // num_mma_ctas, cta_tile_shape_mnk[2])

        gA = cute.zipped_divide(mA, a_tiler_mk)
        gB = cute.zipped_divide(mB, b_tiler_nk)

        mainloop_stage = self.mainloop_stage
        acc_stage = self.acc_stage

        cta_m, cta_n, cta_l = cute.arch.block_idx()

        cluster_shape = cute.arch.block_in_cluster_dim()
        cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(cluster_shape),
            (tiled_mma.thr_id.shape,),
        )
        cluster_layout_v_size = cute.size(cluster_layout_vmnk.shape[0])

        # MMA coordinate within cluster
        mma_coord_vmnk = (
            cta_m % cluster_layout_v_size,
            cta_m // cluster_layout_v_size,
            cta_n,
        )
        is_leader_cta = mma_coord_vmnk[0] == 0
        thr_mma = tiled_mma.get_slice(mma_coord_vmnk[0])

        # Compute A/B/C shared memory layout
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

        # UMMA ACC TMEM Layout
        tmem_layout = cute_ext.make_tmem_layout_acc(tiled_mma, mnk_tiler, acc_stage)

        # Allocate UMMA Buffers
        bufferA = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )

        bufferB = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )

        bufferAcc = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.tmem,
            tmem_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )

        # TMA multicast projection modes
        # A is shared by CTAs with same M (multicast across N, proj=2)
        # B is shared by CTAs with same N (multicast across M, proj=1)
        tma_mcast_proj_A = 2
        tma_mcast_proj_B = 1

        # Determine pipeline operation types based on 2-CTA mode and TMA multicast
        if cutlass.const_expr(self.use_2cta_instrs):
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_2SM_SS
            if cutlass.const_expr(self.use_tma_multicast):
                tma_operation_type = (
                    cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST
                )
            else:
                tma_operation_type = cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM
        else:
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS
            if cutlass.const_expr(self.use_tma_multicast):
                tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD_MULTICAST
            else:
                tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD

        # TMA -> UMMA pipeline
        mainloop_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=mainloop_stage,
            mma_operation_type=mma_operation_type,
            tma_operation_type=tma_operation_type,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # UMMA -> Load to tensor memory pipeline
        # For 2-CTA MMA, warpgroup from both peer and leader CTA consumer release
        acc_pipe_consumer_arv_count = 256 if self.use_2cta_instrs else 128
        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=acc_stage,
            mma_operation_type=mma_operation_type,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=acc_pipe_consumer_arv_count,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        # warp assignment: [0]-tma_store, [0-3]-epi, [4]-mma, [5]-tma_load
        tma_store_warp_id = 0
        mma_warp_id = 4
        tma_load_warp_id = 5
        is_tma_thr = warp_idx == tma_load_warp_id
        is_mma_thr = warp_idx == mma_warp_id
        is_epi_thr = warp_idx < 4

        # store to smem -> TMA store to global
        tma_store_pipe = cute_ext.TMAStorePipeline(
            stages=self.TMA_STORE_STAGE,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=tma_store_warp_id,
        )

        k_tile_size = cute.size(gA, mode=[1, 1])

        #
        # Persistent tile scheduling loop
        #
        tile_sched = utils.StaticPersistentTileScheduler.create(
            sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()
        gA_mkl = cute.local_tile(
            mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gB_nkl = cute.local_tile(
            mB, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        tCgA = thr_mma.partition_A(gA_mkl)
        tCgB = thr_mma.partition_B(gB_nkl)

        if is_tma_thr:
            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                # The tile scheduler takes into account splitting of the M mode for 2CTA instructions
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_m = cur_tile_coord[0] // cluster_layout_v_size
                tAgA_slice = tCgA[
                    (None, None, None, mma_tile_coord_m, None, cur_tile_coord[2])
                ]
                tBgB_slice = tCgB[
                    (None, None, None, cur_tile_coord[1], None, cur_tile_coord[2])
                ]

                for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                    gA_k = tAgA_slice[(None, None, None, k)]
                    gB_k = tBgB_slice[(None, None, None, k)]
                    # Scoped state management - pipeline object manages state internally
                    (
                        producer_stage_token,
                        idx,
                    ) = mainloop_pipe.producer_acquire_and_get_stage()
                    mbar = cute_ext.get_mbarrier(producer_stage_token)
                    ## producer_body begin ##
                    bufferA_sliced = bufferA[None, None, None, idx]
                    bufferB_sliced = bufferB[None, None, None, idx]
                    cute_ext.tma_load(
                        gA_k,
                        bufferA_sliced,
                        mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_A,
                    )
                    cute_ext.tma_load(
                        gB_k,
                        bufferB_sliced,
                        mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_B,
                    )
                    ## producer_body end ##
                    mainloop_pipe.producer_commit_and_advance()
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

        if is_mma_thr and is_leader_cta:
            while work_tile.is_valid_tile:
                _, idx = acc_pipe.producer_acquire_and_get_stage()
                accumulators_sliced = bufferAcc[None, None, None, idx]

                (updated_a_pipe, _updated_b_pipe) = cute_ext.mainloop_mma(
                    tiled_mma,
                    bufferA,
                    bufferB,
                    accumulators_sliced,
                    0,
                    k_tile_size,
                    mma_inst_tile_k,
                    mainloop_pipe,
                    mainloop_pipe,
                )
                mainloop_pipe = updated_a_pipe

                acc_pipe.producer_commit_and_advance()
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

        if is_epi_thr:
            while work_tile.is_valid_tile:
                _, idx = acc_pipe.consumer_wait_and_get_stage()
                accumulators_sliced = bufferAcc[(None, None), 0, 0, idx]

                tma_store_pipe = cute_ext.epilogue_tma_store(
                    cta_tile_shape_mnk,
                    self.use_2cta_instrs,
                    accumulators_sliced,
                    mD,
                    work_tile.tile_idx,
                    tma_store_pipe,
                    tma_store_warp_id,
                    self.epilogue_op,
                )

                acc_pipe.consumer_release_and_advance()

                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()


def create_tensors(l, m, n, k, a_major, b_major, c_major, ab_dtype, c_dtype):
    torch.manual_seed(1111)

    a_torch_cpu = cutlass_torch.matrix(l, m, k, a_major == "m", ab_dtype)
    b_torch_cpu = cutlass_torch.matrix(l, n, k, b_major == "n", ab_dtype)
    c_torch_cpu = cutlass_torch.matrix(l, m, n, c_major == "m", c_dtype)

    a_tensor, _ = cutlass_torch.cute_tensor_like(
        a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    b_tensor, _ = cutlass_torch.cute_tensor_like(
        b_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    c_tensor, c_torch_gpu = cutlass_torch.cute_tensor_like(
        c_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
    )

    return (
        a_tensor,
        b_tensor,
        c_tensor,
        a_torch_cpu,
        b_torch_cpu,
        c_torch_cpu,
        c_torch_gpu,
    )


def compare(a_torch_cpu, b_torch_cpu, c_torch_gpu, c_dtype, tolerance):
    ref = torch.einsum("mkl,nkl->mnl", a_torch_cpu, b_torch_cpu)

    _, ref_torch_gpu = cutlass_torch.cute_tensor_like(
        ref, c_dtype, is_dynamic_layout=True, assumed_align=16
    )
    ref_result = ref_torch_gpu.cpu()
    torch.testing.assert_close(
        c_torch_gpu.cpu(), ref_result, atol=tolerance, rtol=1e-05
    )


def run(
    mnkl: Tuple[int, int, int, int],
    mma_tiler_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    ab_dtype: Type[Numeric],
    c_dtype: Type[Numeric],
    acc_dtype: Type[Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    warmup_iterations: int = 0,
    iterations: int = 1,
    use_cold_l2: bool = False,
    tolerance: float = 1e-02,
    skip_ref_check: bool = False,
    use_2cta_instrs: bool = False,
    fallback_cluster_shape_mn: Tuple[int, int] = None,
    mainloop_stage: int = 4,
    acc_stage: int = 2,
    tma_store_stage: int = 2,
    swizzle_size: int = 1,
    raster_along: str = "m",
):
    """Execute a batched dense GEMM operation on Blackwell architecture with performance benchmarking.

    This function prepares input tensors, configures and launches the GEMM kernel,
    optionally performs reference validation, and benchmarks the execution performance.

    :param mnkl: Problem size (M, N, K, L)
    :type mnkl: Tuple[int, int, int, int]
    :param mma_tiler_mn: MMA tiling size.
    :type mma_tiler_mn: Tuple[int, int]
    :param cluster_shape_mn: Cluster shape.
    :type cluster_shape_mn: Tuple[int, int]
    :param ab_dtype: Data type for input tensors A and B
    :type ab_dtype: Type[Numeric]
    :param c_dtype: Data type for output tensor C
    :type c_dtype: Type[Numeric]
    :param use_2cta_instrs: Use 2-CTA (2SM) instructions for larger tile sizes
    :type use_2cta_instrs: bool
    :param fallback_cluster_shape_mn: Optional. When provided and different
        from cluster_shape_mn, the kernel runs in mixed-cluster mode.
    :type fallback_cluster_shape_mn: Optional[Tuple[int, int]]
    """
    cli.print_problem_config(
        "Blackwell Dense GEMM",
        mnkl,
        dtypes={"AB": ab_dtype, "C": c_dtype, "Acc": acc_dtype},
        majors={"A": a_major, "B": b_major, "C": c_major},
        mma_tiler_mn=mma_tiler_mn,
        cluster_shape_mn=cluster_shape_mn,
    )
    if fallback_cluster_shape_mn is not None:
        print(f"Fallback Cluster Shape (M, N): {fallback_cluster_shape_mn}")
    print(f"Use 2-CTA instructions: {use_2cta_instrs}")
    cli.print_benchmark_config(
        tolerance=tolerance,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        skip_ref_check=skip_ref_check,
        use_cold_l2=use_cold_l2,
    )

    m, n, k, l = mnkl

    ab_dtype = ab_dtype
    c_dtype = c_dtype

    sm100_utils.check_gemm_tma_alignment(
        m,
        n,
        k,
        ab_dtype,
        ab_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        output_tensor_name="C",
    )

    a_tensor, b_tensor, c_tensor, a_torch_cpu, b_torch_cpu, c_torch_cpu, c_torch_gpu = (
        create_tensors(l, m, n, k, a_major, b_major, c_major, ab_dtype, c_dtype)
    )
    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )
    if fallback_cluster_shape_mn is not None:
        max_active_fallback_clusters = utils.HardwareInfo().get_max_active_clusters(
            fallback_cluster_shape_mn[0] * fallback_cluster_shape_mn[1]
        )
    else:
        max_active_fallback_clusters = None

    dense_gemm = PersistentDenseGemmKernel(
        mn_tiler=mma_tiler_mn,
        mma_dtype=(ab_dtype, acc_dtype),
        tmem_output_dtype=c_dtype,
        use_2cta_instrs=use_2cta_instrs,
        cluster_shape_mn=cluster_shape_mn,
        max_active_clusters=max_active_clusters,
        fallback_cluster_shape_mn=fallback_cluster_shape_mn,
        max_active_fallback_clusters=max_active_fallback_clusters,
        mainloop_stage=mainloop_stage,
        acc_stage=acc_stage,
        tma_store_stage=tma_store_stage,
        swizzle_size=swizzle_size,
        raster_along_m=(raster_along == "m"),
    )

    compiled_dense_gemm = cute_ext.compile(dense_gemm, a_tensor, b_tensor, c_tensor)
    compiled_dense_gemm.engine.initialize()

    compiled_dense_gemm(a_tensor, b_tensor, c_tensor)

    if not skip_ref_check:
        compare(a_torch_cpu, b_torch_cpu, c_torch_gpu, c_dtype, tolerance)
        print("check reference: PASS")

    def generate_tensors():
        a_tensor, _ = cutlass_torch.cute_tensor_like(
            a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        b_tensor, _ = cutlass_torch.cute_tensor_like(
            b_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        c_tensor, _ = cutlass_torch.cute_tensor_like(
            c_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
        )
        return testing.JitArguments(a_tensor, b_tensor, c_tensor)

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_torch_cpu.numel() * a_torch_cpu.element_size()
            + b_torch_cpu.numel() * b_torch_cpu.element_size()
            + c_torch_cpu.numel() * c_torch_cpu.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_dense_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Example of Dense GEMM on Blackwell.")

    cli.add_mnkl_arg(parser)
    cli.add_mma_tiler_arg(parser)
    cli.add_cluster_shape_arg(parser)
    cli.add_dtype_args(parser, ab=cutlass.Float32, c=cutlass.Float32)
    cli.add_major_args(parser)
    cli.add_benchmark_args(parser, tolerance=1e-02)

    parser.add_argument(
        "--fallback_cluster_shape_mn",
        type=cli.comma_separated_ints,
        default=None,
        help="Optional fallback cluster shape (comma-separated).",
    )
    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Use 2-CTA (2SM) instructions for larger tile sizes",
    )
    parser.add_argument(
        "--mainloop_stage",
        type=int,
        default=4,
        help="Number of AB pipeline stages.",
    )
    parser.add_argument(
        "--acc_stage",
        type=int,
        default=2,
        help="Number of accumulator pipeline stages.",
    )
    parser.add_argument(
        "--tma_store_stage",
        type=int,
        default=2,
        help="Number of TMA store pipeline stages.",
    )
    parser.add_argument(
        "--swizzle_size",
        type=int,
        default=1,
        help="Swizzling size in the unit of cluster for improving L2 cache hit rate",
    )
    parser.add_argument(
        "--raster_along",
        type=str,
        choices=["m", "n"],
        default="m",
        help="Rasterization order of clusters",
    )

    args = parser.parse_args()

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    if len(args.mma_tiler_mn) != 2:
        parser.error("--mma_tiler_mn must contain exactly 2 values")

    if (
        args.fallback_cluster_shape_mn is not None
        and len(args.fallback_cluster_shape_mn) != 2
    ):
        parser.error("--fallback_cluster_shape_mn must contain exactly 2 values")

    exec_time = run(
        args.mnkl,
        args.mma_tiler_mn,
        args.cluster_shape_mn,
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
        args.use_2cta_instrs,
        fallback_cluster_shape_mn=args.fallback_cluster_shape_mn,
        mainloop_stage=args.mainloop_stage,
        acc_stage=args.acc_stage,
        tma_store_stage=args.tma_store_stage,
        swizzle_size=args.swizzle_size,
        raster_along=args.raster_along,
    )

    print(f"Execution time: {exec_time} microseconds per iteration")
