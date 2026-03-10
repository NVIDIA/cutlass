# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

"""
2SM Dense GEMM example using cute_ext decorators.
"""

import torch
import math
import cutlass
from cutlass import cute
from cutlass.cute import experimental as cute_ext
from cutlass.cute.runtime import from_dlpack
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils as utils
from cutlass.base_dsl.typing import Numeric
from typing import Type


def create_gemm_tensors_torch(
    M,
    N,
    K,
    majors: tuple[
        cute.nvgpu.tcgen05.OperandMajorMode,
        cute.nvgpu.tcgen05.OperandMajorMode,
        cute.nvgpu.tcgen05.OperandMajorMode,
    ],
    dtypes: tuple[torch.dtype, torch.dtype, torch.dtype],
):
    A = None
    B = None
    D = None

    if majors[0] == cute.nvgpu.tcgen05.OperandMajorMode.MN:
        A = torch.empty(K, M).random_(-4, 4).permute(1, 0).to(dtypes[0]).cuda()
    elif majors[0] == cute.nvgpu.tcgen05.OperandMajorMode.K:
        A = torch.empty(M, K).random_(-4, 4).permute(0, 1).to(dtypes[0]).cuda()
    if majors[1] == cute.nvgpu.tcgen05.OperandMajorMode.MN:
        B = torch.empty(K, N).random_(-4, 4).permute(1, 0).to(dtypes[1]).cuda()
    elif majors[1] == cute.nvgpu.tcgen05.OperandMajorMode.K:
        B = torch.empty(N, K).random_(-4, 4).permute(0, 1).to(dtypes[1]).cuda()
    if majors[2] == cute.nvgpu.tcgen05.OperandMajorMode.MN:
        D = torch.empty(N, M).random_(-4, 4).permute(1, 0).to(dtypes[2]).cuda()
    elif majors[2] == cute.nvgpu.tcgen05.OperandMajorMode.K:
        D = torch.empty(M, N).random_(-4, 4).permute(0, 1).to(dtypes[2]).cuda()

    return A, B, D


def get_gemm_tensors(
    M,
    N,
    K,
    majors: tuple[
        cute.nvgpu.tcgen05.OperandMajorMode,
        cute.nvgpu.tcgen05.OperandMajorMode,
        cute.nvgpu.tcgen05.OperandMajorMode,
    ],
    dtypes: tuple[torch.dtype, torch.dtype, torch.dtype],
):
    A, B, D = create_gemm_tensors_torch(M, N, K, majors, dtypes)

    A_cute = from_dlpack(A, assumed_align=16).mark_layout_dynamic(
        leading_dim=1 if majors[0] == cute.nvgpu.tcgen05.OperandMajorMode.K else 0
    )
    B_cute = from_dlpack(B, assumed_align=16).mark_layout_dynamic(
        leading_dim=1 if majors[1] == cute.nvgpu.tcgen05.OperandMajorMode.K else 0
    )
    D_cute = from_dlpack(D, assumed_align=16).mark_layout_dynamic(
        leading_dim=1 if majors[2] == cute.nvgpu.tcgen05.OperandMajorMode.K else 0
    )

    return A, B, D, A_cute, B_cute, D_cute


def sm100_4x4x1_kernel_builder(
    use_tma_multicast: bool,
    use_2cta_instrs: bool,
    acc_dtype: Type[Numeric],
    M: int,
    N: int,
):
    CLUSTER_SHAPE = (2, 1, 1)
    GRID_SHAPE = (
        math.ceil(M / 128),
        math.ceil(N / 256),
        1,
    )  # TODO (xpbowler): remove hard-code
    NUM_WARPS_PER_CTA = 6
    TMA_STORE_PIPE_DEPTH = 4
    MAINLOOP_STAGE_DEPTH = 4  # pipeline depth of TMA->MMA
    # pipeline depth of mainloop->epilogue. only useful if using persistent CTA
    EPILOGUE_STAGE_DEPTH = 1

    # m256n256k16 2SM MMA / m128n256k16 1SM MMA
    mma_inst_shape_mnk = (256, 256, 16) if use_2cta_instrs else (128, 256, 16)

    @cute_ext.kernel
    def kernel(
        mA: cute.Tensor,
        mB: cute.Tensor,
        mD: cute.Tensor,
    ):
        d_layout = utils.LayoutEnum.from_tensor(mD)
        d_dtype = mD.element_type
        ab_dtype = mA.element_type

        mma_inst_shape_m, mma_inst_shape_n, mma_inst_shape_k = mma_inst_shape_mnk
        if cutlass.const_expr(use_2cta_instrs):
            cta_group = cute.nvgpu.tcgen05.CtaGroup.TWO
        else:
            cta_group = cute.nvgpu.tcgen05.CtaGroup.ONE

        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            ab_dtype,
            utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
            acc_dtype,
            cta_group,
            (mma_inst_shape_m, mma_inst_shape_n),
        )

        mma_inst_tile_k = (
            4  # 4 MMAs per MMA tile K. For 16b types, tcgen05.mma has K=16.
        )
        mma_inst_tile_m = mma_inst_tile_n = 1  # 1 MMAs per MMA tile M/N
        bM = mma_inst_shape_m * mma_inst_tile_m
        bN = mma_inst_shape_n * mma_inst_tile_n
        bK = mma_inst_shape_k * mma_inst_tile_k
        mnk_tiler = (bM, bN, bK)

        cta_m, cta_n, _ = cute.arch.block_idx()
        tid_x, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(CLUSTER_SHAPE),
            cute.core._pack_shape((cute.size(tiled_mma.thr_id.shape),)),
        )
        cluster_layout_v_size = cute.size(cluster_layout_vmnk.shape[0])
        mma_coord_vmnk = (
            cta_m % cluster_layout_v_size,
            cta_m // cluster_layout_v_size,
            cta_n,
        )

        gA = cute.zipped_divide(mA, (bM, bK))  # ((bM, bK), (M/bM, K/bK))
        gA_tma = cute.zipped_divide(
            mA, (bM // cluster_layout_v_size, bK)
        )  # ((bM/2, bK), (2*M/bM, K/bK))
        tAgA = gA_tma[(None, None), (cta_m, None)]  # ((bM/2, bK), (1, K/bK))

        gB_tma = cute.zipped_divide(
            mB, (bN // cluster_layout_v_size, bK)
        )  # ((bN/2, bK), (2*M/bM, K/bK))
        # ((bN/2, bK), (1, K/bK))
        tBgB = gB_tma[
            (None, None),
            (cluster_layout_v_size * cta_n + cta_m % cluster_layout_v_size, None),
        ]

        gD_tma = cute.zipped_divide(
            mD, (bM // cluster_layout_v_size, bN)
        )  # ((bM/2, bN), (2*M/bM, N/bN))
        tDgD = gD_tma[(None, None), (cta_m, cta_n)]  # ((bM/2, bN), (1, 1))

        a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mnk_tiler,
            ab_dtype,
            MAINLOOP_STAGE_DEPTH,
        )
        b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma,
            mnk_tiler,
            ab_dtype,
            MAINLOOP_STAGE_DEPTH,
        )

        cta_tile_shape_mnk = cute.shape_div(mnk_tiler, (cluster_layout_v_size, 1, 1))
        epi_tile = sm100_utils.compute_epilogue_tile_shape(
            cta_tile_shape_mnk,
            use_2cta_instrs,
            d_layout,
            d_dtype,
        )
        sc_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            d_dtype,
            d_layout,
            epi_tile,
            TMA_STORE_PIPE_DEPTH,
        )

        tmem_layout = cute_ext.make_tmem_layout_acc(
            tiled_mma, mnk_tiler, EPILOGUE_STAGE_DEPTH
        )

        bufferA = cute_ext.allocate(
            ab_dtype,
            cute.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )

        bufferB = cute_ext.allocate(
            ab_dtype,
            cute.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )

        bufferAcc = cute_ext.allocate(
            acc_dtype,
            cute.AddressSpace.tmem,
            tmem_layout,
            alignment=16,
            is2cta=use_2cta_instrs,
        )

        bufferC = cute_ext.allocate(
            d_dtype,
            cute.AddressSpace.smem,
            sc_smem_layout_staged,
            alignment=1024,
        )

        copy_atom_t2r = sm100_utils.get_tmem_load_op(
            cta_tile_shape_mnk,
            d_layout,
            d_dtype,
            acc_dtype,
            epi_tile,
            use_2cta_instrs,
        )

        # Take only one stage of the TMEM buffer for the epilogue
        accumulators = cute.zipped_divide(bufferAcc, ((epi_tile), 1))
        acc_epi_div = accumulators[((None, None), 0), 0]

        # Create the TMEM copy atom based on the size of transfer within one iteration of epilogue
        tiled_copy_t2r = cute.nvgpu.tcgen05.make_tmem_copy(copy_atom_t2r, acc_epi_div)

        # Calculate the per thread destination size per iteration for output of TMEM and input of SMEM
        gC_mnl_epi = cute.flat_divide(tDgD, epi_tile)
        acc_d_rmem_layout = cute_ext.make_t2r_rmem_layout(
            tiled_copy_t2r, gC_mnl_epi, tid_x
        )

        bufferRAcc = cute_ext.allocate(
            acc_dtype,
            cute.AddressSpace.rmem,
            acc_d_rmem_layout,
            alignment=32,
        )
        bufferRD = cute_ext.allocate(
            d_dtype,
            cute.AddressSpace.rmem,
            acc_d_rmem_layout,
            alignment=32,
        )

        tma_mcast_proj_A = 2
        tma_mcast_proj_B = 1

        mma_operation_type = tma_operation_type = None
        acc_pipe = mainloop_pipe = None
        if cutlass.const_expr(use_2cta_instrs):
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_2SM_SS
            if cutlass.const_expr(use_tma_multicast):
                tma_operation_type = (
                    cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST
                )
            else:
                tma_operation_type = cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM

        else:
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS
            if cutlass.const_expr(use_tma_multicast):
                tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD_MULTICAST
            else:
                tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD

        # MMA <-> TMEM load pipeline
        # if 2CTA MMA, warpgroup from both peer and leader CTA consumer.release
        acc_pipe_consumer_arv_count = 256 if use_2cta_instrs else 128
        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=EPILOGUE_STAGE_DEPTH,
            mma_operation_type=mma_operation_type,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=acc_pipe_consumer_arv_count,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        if cutlass.const_expr(use_tma_multicast):
            # TMA load <-> MMA pipeline
            mainloop_pipe = cute_ext.TMAToUMMAPipeline.create_with_mask(
                num_stages=MAINLOOP_STAGE_DEPTH,
                tma_operation_type=tma_operation_type,
                mma_operation_type=mma_operation_type,
                cluster_layout_vmnk=cluster_layout_vmnk,
            )
        else:
            mainloop_pipe = cute_ext.TMAToUMMAPipeline.create(
                num_stages=MAINLOOP_STAGE_DEPTH,
                mma_operation_type=mma_operation_type,
                tma_operation_type=tma_operation_type,
                cluster_layout_vmnk=cluster_layout_vmnk,
            )

        tma_store_warp_id = 0
        mma_warp_id = 4
        tma_load_warp_id = 5
        is_tma_thr = warp_idx == tma_load_warp_id
        is_mma_thr = warp_idx == mma_warp_id
        is_epi_thr = warp_idx < 4
        is_leader_cta = mma_coord_vmnk[0] == 0

        # SMEM -> GMEM
        tma_store_pipe = cute_ext.TMAStorePipeline(
            stages=TMA_STORE_PIPE_DEPTH,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=tma_store_warp_id,
        )

        k_tile_count = cute.size(gA, mode=[1, 1])
        if is_tma_thr:
            for k_tile in cutlass.range(0, k_tile_count, 1, unroll=1):
                gA_k = tAgA[None, None, k_tile]
                gB_k = tBgB[None, None, k_tile]

                producer_stage_token, idx = (
                    mainloop_pipe.producer_acquire_and_get_stage()
                )
                mbar = cute_ext.get_mbarrier(producer_stage_token)
                bufferA_sliced = bufferA[None, None, None, idx]
                bufferB_sliced = bufferB[None, None, None, idx]
                a_cta_v_map = cute_ext.get_cta_v_map_ab(mA, mnk_tiler, tiled_mma, "A")
                b_cta_v_map = cute_ext.get_cta_v_map_ab(mB, mnk_tiler, tiled_mma, "B")

                if cutlass.const_expr(use_tma_multicast):
                    cute_ext.tma_load_multicast(
                        gA_k,
                        bufferA_sliced,
                        mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        cta_v_map=a_cta_v_map,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_A,
                    )
                    cute_ext.tma_load_multicast(
                        gB_k,
                        bufferB_sliced,
                        mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        cta_v_map=b_cta_v_map,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_B,
                    )
                else:
                    cute_ext.tma_load(
                        gA_k,
                        bufferA_sliced,
                        mbar,
                        cta_v_map=a_cta_v_map,
                        tma_operation_type=tma_operation_type,
                    )
                    cute_ext.tma_load(
                        gB_k,
                        bufferB_sliced,
                        mbar,
                        cta_v_map=b_cta_v_map,
                        tma_operation_type=tma_operation_type,
                    )

                if is_leader_cta:
                    mainloop_pipe.producer_commit()
                mainloop_pipe.producer_state = cute_ext.pipeline_advance_iterator(
                    mainloop_pipe.raw_pipeline, mainloop_pipe.producer_state
                )

        if is_mma_thr and is_leader_cta:
            producer_stage_token, idx = acc_pipe.producer_acquire_and_get_stage()
            accumulators_sliced = bufferAcc[None, None, None, idx]

            mma_atom = cute.make_mma_atom(tiled_mma.op)
            mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)
            for k_tile in cutlass.range(0, k_tile_count, 1, unroll=1):
                _, mainloop_idx = mainloop_pipe.consumer_wait_and_get_stage()
                bufferA_sliced_stage = cute.core.slice_(
                    bufferA, (None, None, None, mainloop_idx)
                )
                bufferB_sliced_stage = cute.core.slice_(
                    bufferB, (None, None, None, mainloop_idx)
                )

                for k_block in cutlass.range(mma_inst_tile_k, unroll_full=True):
                    cute_ext.dot(
                        mma_atom,
                        cute.append_ones(
                            bufferA_sliced_stage[None, None, k_block], up_to_rank=3
                        ),
                        cute.append_ones(
                            bufferB_sliced_stage[None, None, k_block], up_to_rank=3
                        ),
                        accumulators_sliced,
                    )
                    mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)

                mainloop_pipe.consumer_release_and_advance()

            acc_pipe.producer_commit_and_advance()

        if is_epi_thr:
            _, idx = acc_pipe.consumer_wait_and_get_stage()
            accumulators_sliced = bufferAcc[(None, None), 0, 0, idx]
            acc_epi_div_tiled = cute.flat_divide(accumulators_sliced, epi_tile)

            tiled_copy_r2s = cute.make_tiled_copy_D(
                cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), d_dtype),
                tiled_copy_t2r,
            )
            c_cta_v_map = cute_ext.get_cta_v_map_c(mD, epi_tile)

            subtile_cnt = cute.size(acc_epi_div_tiled.shape, mode=[3])
            for mn in range(subtile_cnt):
                # TMEM -> RMEM
                cute_ext.partition_and_copy(
                    tiled_copy_t2r.get_slice(tid_x),
                    acc_epi_div_tiled[None, None, 0, mn],
                    bufferRAcc,
                )

                # RMEM -> RMEM
                bufferRD.store(bufferRAcc.load().to(d_dtype))

                tma_store_pipe.acquire_sync()
                store_idx = tma_store_pipe.get_index()

                # RMEM -> SMEM
                cute_ext.partition_and_copy(
                    tiled_copy_r2s.get_slice(tid_x),
                    bufferRD,
                    bufferC[None, None, store_idx],
                )

                tma_store_pipe.commit_sync()

                if warp_idx == tma_store_warp_id:
                    cute_ext.tma_store(
                        bufferC[None, None, store_idx],
                        gC_mnl_epi[None, None, 0, mn],
                        cta_v_map=c_cta_v_map,
                    )

                tma_store_pipe.release_advance()

            tma_store_pipe.tail()
            acc_pipe.consumer_release_and_advance()

    # Return a callable that launches the kernel with proper grid/block/cluster
    @cute_ext.jit
    def launch_kernel(mA: cute.Tensor, mB: cute.Tensor, mD: cute.Tensor):
        kernel(mA, mB, mD).launch(
            grid=GRID_SHAPE,
            block=(32 * NUM_WARPS_PER_CTA, 1, 1),
            cluster=CLUSTER_SHAPE,
            smem=cute.Int64(utils.get_smem_capacity_in_bytes("sm_100")),
        )

    return launch_kernel


if __name__ == "__main__":
    M = 256
    N = 256
    K = 64
    use_tma_multicast = True
    use_2cta_instrs = True
    acc_dtype = cutlass.Float32

    majors = (
        cute.nvgpu.tcgen05.OperandMajorMode.K,
        cute.nvgpu.tcgen05.OperandMajorMode.K,
        cute.nvgpu.tcgen05.OperandMajorMode.K,
    )
    dtypes = (torch.float16, torch.float16, torch.float16)

    A_torch, B_torch, D_torch, A_cute, B_cute, D_cute = get_gemm_tensors(
        M, N, K, majors, dtypes
    )

    kernel_launcher = sm100_4x4x1_kernel_builder(
        use_tma_multicast, use_2cta_instrs, acc_dtype, M, N
    )

    compiled_kernel = cute_ext.compile(kernel_launcher, A_cute, B_cute, D_cute)

    compiled_kernel(A_cute, B_cute, D_cute)

    # Reference check (may fail on simulator/unsupported GPU)
    try:
        ref = torch.mm(A_torch.float(), B_torch.float().T)
        torch.testing.assert_close(D_torch.float(), ref, atol=1e-2, rtol=1e-2)
        print("PASS")
    except RuntimeError as e:
        if "no kernel image is available" in str(e):
            print("SKIP: Reference check skipped - GPU not supported by PyTorch")
        else:
            raise
