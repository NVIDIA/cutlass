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

import torch
from typing import Type, Tuple, List

import cutlass
from cutlass.cute import experimental as cute_ext
from cutlass.base_dsl.typing import Numeric
from cutlass import cute as cute
from cutlass import utils
from cutlass import torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils

import cutlass.cute.testing as testing

class DenseGemmPtrArrayKernel:
    def __init__(
        self,
        mn_tiler: tuple[int, int],
        mma_dtype: tuple[Type[Numeric], Type[Numeric], Type[Numeric]],
        tmem_output_dtype: Type[Numeric],
        batch_count: int,  # Number of batches, each batch will have its own pointer for the matrix
        A_shape: tuple,  # Shape of the matrix A
        A_stride: tuple,  # Stride of the matrix A
        B_shape: tuple,  # Shape of the matrix B
        B_stride: tuple,  # Stride of the matrix B
        D_shape: tuple,  # Shape of the matrix D
        D_stride: tuple,  # Stride of the matrix D
        epilogue_op=lambda x: x,
    ):
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype, self.d_dtype = mma_dtype
        self.tmem_output_dtype = tmem_output_dtype
        self.use_2cta_instrs = False
        self.TMA_STORE_STAGE = 4
        self.epilogue_op = epilogue_op
        self.batch_count = batch_count
        self.A_shape = A_shape
        self.A_stride = A_stride
        self.B_shape = B_shape
        self.B_stride = B_stride
        self.D_shape = D_shape
        self.D_stride = D_stride

    """
    Helper function to convert an int64 to a cute.ptr of a certain type.
    The cute.ptr is always located in Gmem.
    This is used to load the pointers for A/B/D from the Ptr array.
    """

    @cute.experimental.jit
    def _get_pointer(self, address_as_int, cute_type):
        cute_ptr = cute.make_ptr(
            cute_type,
            address_as_int,
            mem_space=cute.AddressSpace.gmem,
            assumed_align=16,
        )
        return cute_ptr

    @cute.experimental.jit
    def __call__(
        self, mA_tensor: cute.Tensor, mB_tensor: cute.Tensor, mD_tensor: cute.Tensor
    ):
        # Get the pointer to the first batch of D
        d_ptr = self._get_pointer(mD_tensor[0], self.d_dtype)
        d_ptr_base_tensor = cute.make_tensor(
            d_ptr, layout=cute.make_layout(self.D_shape, stride=self.D_stride)
        )
        tile_mn = cute.core._pack_shape((*self.mn_tiler, 1))
        div = cute.tiled_divide(d_ptr_base_tensor, tile_mn)
        grid = (div.shape[1], div.shape[2], div.shape[3])
        self.kernel(mA_tensor, mB_tensor, mD_tensor).launch(
            grid=grid,
            block=(192, 1, 1),
            cluster=(1, 1, 1),
            smem=cute.Int64(utils.get_smem_capacity_in_bytes("sm_100")),
        )

    @cute.experimental.kernel
    def kernel(
        self,
        mA_tensor: cute.Tensor,
        mB_tensor: cute.Tensor,
        mD_tensor: cute.Tensor,
    ):
        # Get pointers for the first batch to perform shape and stage calculations
        A_0_ptr = self._get_pointer(mA_tensor[0], self.ab_dtype)
        B_0_ptr = self._get_pointer(mB_tensor[0], self.ab_dtype)
        D_0_ptr = self._get_pointer(mD_tensor[0], self.d_dtype)

        mA = cute.make_tensor(
            A_0_ptr, layout=cute.make_layout(self.A_shape, stride=self.A_stride)
        )

        mB = cute.make_tensor(
            B_0_ptr, layout=cute.make_layout(self.B_shape, stride=self.B_stride)
        )

        mD = cute.make_tensor(
            D_0_ptr, layout=cute.make_layout(self.D_shape, stride=self.D_stride)
        )

        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.ab_dtype,
            utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
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

        d_layout = utils.LayoutEnum.from_tensor(mD)
        d_dtype = mD.element_type

        tiler_mk = (mnk_tiler[0], mnk_tiler[2])
        tiler_nk = (mnk_tiler[1], mnk_tiler[2])
        tiler_mn = (mnk_tiler[0], mnk_tiler[1])

        gA = cute.zipped_divide(mA, tiler_mk)
        gB = cute.zipped_divide(mB, tiler_nk)
        gD = cute.zipped_divide(mD, tiler_mn)

        mainloop_stage = 2
        acc_stage = 2

        cta_m, cta_n, cta_l = cute.arch.block_idx()
        tid_x, _, _ = cute.arch.thread_idx()

        gA_tile = gA[(None, None), (cta_m, None, cta_l)]
        gB_tile = gB[(None, None), (cta_n, None, cta_l)]
        gD_tile = gD[(None, None), (cta_m, cta_n, cta_l)]

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

        cta_tile_shape_mnk = cute.shape_div(
            mnk_tiler, (cute.size(tiled_mma.thr_id.shape), 1, 1)
        )
        epi_tile = sm100_utils.compute_epilogue_tile_shape(
            cta_tile_shape_mnk,
            self.use_2cta_instrs,
            d_layout,
            d_dtype,
        )
        sc_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            d_dtype,
            d_layout,
            epi_tile,
            self.TMA_STORE_STAGE,
        )

        # UMMA ACC TMEM Layout
        tmem_layout = cute_ext.make_tmem_layout_acc(tiled_mma, mnk_tiler, acc_stage)

        # Allocate UMMA Buffers
        bufferA = cute_ext.allocate(
            self.ab_dtype,
            cute.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )

        bufferB = cute_ext.allocate(
            self.ab_dtype,
            cute.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )

        bufferAcc = cute_ext.allocate(
            self.acc_dtype,
            cute.AddressSpace.tmem,
            tmem_layout,
            alignment=16,
        )

        # Allocate SMEM buffer for C
        bufferC = cute_ext.allocate(
            d_dtype,
            cute.AddressSpace.smem,
            sc_smem_layout_staged,
            alignment=1024,
        )

        # Create the TMEM load atom
        copy_atom_t2r = sm100_utils.get_tmem_load_op(
            cta_tile_shape_mnk,
            d_layout,
            self.tmem_output_dtype,
            self.acc_dtype,
            epi_tile,
            self.use_2cta_instrs,
        )

        # Take only one stage of the TMEM buffer
        accumulators = cute.zipped_divide(bufferAcc, ((epi_tile), 1))
        acc_epi_div = accumulators[((None, None), 0), 0]

        # Create the TMEM copy atom based on the size of transfer within one iteration of epilogue
        tiled_copy_t2r = cute.nvgpu.tcgen05.make_tmem_copy(copy_atom_t2r, acc_epi_div)

        # Calculate the per thread destination size per iteration for output of TMEM and input of SMEM
        gC_mnl_epi = cute.flat_divide(gD_tile, epi_tile)
        acc_d_rmem_layout = cute_ext.make_t2r_rmem_layout(
            tiled_copy_t2r, gC_mnl_epi, tid_x
        )

        # Allocate RMEM buffers
        bufferRAcc = cute_ext.allocate(
            self.acc_dtype,
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

        # TMA -> UMMA
        mainloop_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=mainloop_stage,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
        )

        # UMMA -> TMEM
        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=acc_stage,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=128,
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

        # SMEM -> GMEM
        tma_store_pipe = cute_ext.TMAStorePipeline(
            stages=self.TMA_STORE_STAGE,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=tma_store_warp_id,
        )

        k_tile_size = cute.size(gA, mode=[1, 1])

        # Outer loop over batches and perform GEMM for each batch as usual
        # This is a dynamic for loop that lowers to an scf.for
        # Note that the tensor loading is done in the if `thread` warp specialized
        # sections. This is essential to ensure proper synchronization of tma loads
        # and tma updates across batches.
        for batch_idx in range(0, self.batch_count):
            # Load pointers for the current batch
            ptr_A = self._get_pointer(mA_tensor[batch_idx], self.ab_dtype)
            ptr_B = self._get_pointer(mB_tensor[batch_idx], self.ab_dtype)
            ptr_D = self._get_pointer(mD_tensor[batch_idx], self.d_dtype)

            gALayout = cute.zipped_divide(mA, tiler_mk)
            k_tile_size = cute.size(gALayout, mode=[1, 1])

            if is_tma_thr:
                mA = cute.make_tensor(
                    ptr_A, layout=cute.make_layout(self.A_shape, stride=self.A_stride)
                )
                mB = cute.make_tensor(
                    ptr_B, layout=cute.make_layout(self.B_shape, stride=self.B_stride)
                )
                gA = cute.zipped_divide(mA, tiler_mk)
                gB = cute.zipped_divide(mB, tiler_nk)
                gA_tile = gA[(None, None), (cta_m, None, cta_l)]
                gB_tile = gB[(None, None), (cta_n, None, cta_l)]
                for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                    gA_k = gA_tile[None, None, k]
                    gB_k = gB_tile[None, None, k]

                    # Scoped state management - pipeline object manages state internally
                    (
                        producer_stage_token,
                        idx,
                    ) = mainloop_pipe.producer_acquire_and_get_stage()
                    mbar = cute_ext.get_mbarrier(producer_stage_token)
                    ## producer_body begin ##
                    bufferA_sliced = bufferA[None, None, None, idx]
                    bufferB_sliced = bufferB[None, None, None, idx]
                    a_cta_v_map = cute_ext.get_cta_v_map_ab(
                        mA, mnk_tiler, tiled_mma, "A"
                    )
                    b_cta_v_map = cute_ext.get_cta_v_map_ab(
                        mB, mnk_tiler, tiled_mma, "B"
                    )
                    cute_ext.tma_load(
                        gA_k,
                        bufferA_sliced,
                        mbar,
                        cta_v_map=a_cta_v_map,
                    )
                    cute_ext.tma_load(
                        gB_k,
                        bufferB_sliced,
                        mbar,
                        cta_v_map=b_cta_v_map,
                    )
                    ## producer_body end ##
                    mainloop_pipe.producer_commit_and_advance()

            # MMA section remains same as a regular GEMM
            if is_mma_thr:
                producer_stage_token, idx = acc_pipe.producer_acquire_and_get_stage()
                ## acc_producer_body begin ##
                accumulators_sliced = bufferAcc[None, None, None, idx]

                mma_atom = cute.make_mma_atom(tiled_mma.op)
                mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)
                for k_tile in cutlass.range(0, k_tile_size, 1, unroll=1):
                    # Scoped state management - pipeline object manages consumer state internally
                    (
                        _,
                        mainloop_idx,
                    ) = mainloop_pipe.consumer_wait_and_get_stage()
                    ## tma_consumer_body begin ##

                    bufferA_sliced_stage = cute.core.slice_(
                        bufferA, (None, None, None, mainloop_idx)
                    )
                    bufferB_sliced_stage = cute.core.slice_(
                        bufferB, (None, None, None, mainloop_idx)
                    )

                    for k_block in cutlass.range(mma_inst_tile_k, unroll_full=True):
                        bufferA_sliced = bufferA_sliced_stage[None, None, k_block]
                        bufferB_sliced = bufferB_sliced_stage[None, None, k_block]

                        cute_ext.dot(
                            mma_atom,
                            cute.append_ones(bufferA_sliced, up_to_rank=3),
                            cute.append_ones(bufferB_sliced, up_to_rank=3),
                            accumulators_sliced,
                        )
                        mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)

                    ## tma_consumer_body end ##
                    mainloop_pipe.consumer_release_and_advance()

                ## acc_producer_body end ##
                acc_pipe.producer_commit_and_advance()

            if is_epi_thr:
                # Load the D tensor in the warp specialized section
                mD = cute.make_tensor(
                    ptr_D, layout=cute.make_layout(self.D_shape, stride=self.D_stride)
                )
                gD = cute.zipped_divide(mD, tiler_mn)
                gD_tile = gD[(None, None), (cta_m, cta_n, cta_l)]
                gC_mnl_epi = cute.flat_divide(gD_tile, epi_tile)
                _, idx = acc_pipe.consumer_wait_and_get_stage()
                ## acc_consume_body begin ##
                accumulators_sliced = bufferAcc[(None, None), 0, 0, idx]
                acc_epi_div_tiled = cute.flat_divide(accumulators_sliced, epi_tile)

                subtile_cnt = cute.size(acc_epi_div_tiled.shape, mode=[3])
                for mn in range(subtile_cnt):
                    # TMEM -> RMEM
                    cute_ext.partition_and_copy(
                        tiled_copy_t2r.get_slice(tid_x),
                        acc_epi_div_tiled[None, None, 0, mn],
                        bufferRAcc,
                    )

                    # RMEM -> RMEM
                    bufferRD.store(self.epilogue_op(bufferRAcc.load().to(self.d_dtype)))

                    # Acquire pipeline stage and synchronize before RMEM->SMEM copy
                    tma_store_pipe.acquire_sync()
                    idx = tma_store_pipe.get_index()

                    # RMEM -> SMEM
                    tiled_copy_r2s = cute.make_tiled_copy_D(
                        cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), self.d_dtype),
                        tiled_copy_t2r,
                    )
                    cute_ext.partition_and_copy(
                        tiled_copy_r2s.get_slice(tid_x),
                        bufferRD,
                        bufferC[None, None, idx],
                    )

                    # Fence SMEM writes and synchronize before TMA store
                    tma_store_pipe.commit_sync()

                    # SMEM -> GMEM (only designated TMA store warp performs TMA store)
                    if warp_idx == tma_store_warp_id:
                        c_cta_v_map = cute_ext.get_cta_v_map_c(mD, epi_tile)
                        cute_ext.tma_store(
                            bufferC[None, None, idx],
                            gC_mnl_epi[None, None, 0, mn],
                            cta_v_map=c_cta_v_map,
                        )

                    # Release pipeline stage and advance
                    tma_store_pipe.release_advance()

                tma_store_pipe.tail()
                acc_pipe.consumer_release_and_advance()


def create_tensors(l, m, n, k, a_major, b_major, d_major, ab_dtype, d_dtype):
    torch.manual_seed(1111)

    a_torch_cpu = cutlass_torch.matrix(l, m, k, a_major == "m", ab_dtype)
    b_torch_cpu = cutlass_torch.matrix(l, n, k, b_major == "n", ab_dtype)
    d_torch_cpu = cutlass_torch.matrix(l, m, n, d_major == "m", d_dtype)

    a_tensor, a_torch_gpu = cutlass_torch.cute_tensor_like(
        a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    b_tensor, b_torch_gpu = cutlass_torch.cute_tensor_like(
        b_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    d_tensor, d_torch_gpu = cutlass_torch.cute_tensor_like(
        d_torch_cpu, d_dtype, is_dynamic_layout=True, assumed_align=16
    )

    return (
        a_tensor,
        b_tensor,
        d_tensor,
        a_torch_cpu,
        b_torch_cpu,
        d_torch_cpu,
        a_torch_gpu,
        b_torch_gpu,
        d_torch_gpu,
    )


# Helper creates a cute.Tensor from a List of device pointers
def make_tensor_of_ptrs(torch_tensor_array: List):
    tensor_of_ptrs_torch = torch.tensor(
        [t.data_ptr() for t in torch_tensor_array],
        dtype=torch.int64,
        device="cuda",
        requires_grad=False,
    )
    tensor_of_ptrs_cute, backing_torch_tensor = cutlass_torch.cute_tensor_like(
        tensor_of_ptrs_torch,
        cutlass.Int64,
        is_dynamic_layout=False,
        assumed_align=16,
    )
    return tensor_of_ptrs_cute, backing_torch_tensor


def create_tensors_for_ptr_array(
    l, m, n, k, a_major, b_major, d_major, ab_dtype, d_dtype
):
    # Store torch gpu pointers
    As_torch_gpu = []
    Bs_torch_gpu = []
    Ds_torch_gpu = []
    # Store cute tensors
    A_cutes = []
    B_cutes = []
    D_cutes = []

    for batch_idx in range(l):
        torch.manual_seed(111 + batch_idx)

        (
            A_tensor,
            B_tensor,
            D_tensor,
            A_torch_cpu,
            B_torch_cpu,
            D_torch_cpu,
            A_torch_gpu,
            B_torch_gpu,
            D_torch_gpu,
        ) = create_tensors(
            1,  # outer loop creates a new tensor for each batch
            m,
            n,
            k,
            a_major,
            b_major,
            d_major,
            ab_dtype,
            d_dtype,
        )

        A_cutes.append(A_tensor)
        B_cutes.append(B_tensor)
        D_cutes.append(D_tensor)
        As_torch_gpu.append(A_torch_gpu)
        Bs_torch_gpu.append(B_torch_gpu)
        Ds_torch_gpu.append(D_torch_gpu)

    # Create cute tensors of pointers
    a_tensor, a_backing_torch_tensor = make_tensor_of_ptrs(As_torch_gpu)
    b_tensor, b_backing_torch_tensor = make_tensor_of_ptrs(Bs_torch_gpu)
    d_tensor, d_backing_torch_tensor = make_tensor_of_ptrs(Ds_torch_gpu)

    return (
        a_tensor,
        b_tensor,
        d_tensor,
        a_backing_torch_tensor,
        b_backing_torch_tensor,
        d_backing_torch_tensor,
        A_cutes,
        B_cutes,
        D_cutes,
        As_torch_gpu,
        Bs_torch_gpu,
        Ds_torch_gpu,
    )


def compare(a_torch_cpu, b_torch_cpu, d_torch_gpu, d_dtype, tolerance):
    ref = torch.einsum("mkl,nkl->mnl", a_torch_cpu, b_torch_cpu)

    _, ref_torch_gpu = cutlass_torch.cute_tensor_like(
        ref, d_dtype, is_dynamic_layout=True, assumed_align=16
    )
    ref_result = ref_torch_gpu.cpu()
    torch.testing.assert_close(
        d_torch_gpu.cpu(), ref_result, atol=tolerance, rtol=1e-05
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
    **kwargs,
):
    """Execute a Pointer array batched dense GEMM operation on Blackwell architecture with performance benchmarking.
    The main difference between this and a regular bathced GEMM is that the inputs to the kernel are arrays of pointers.
    Every batch of each operand (A/B/D) has its own pointer. Thus, the size of the array of pointers is the batch size.
    These pointers NEED NOT be stored contiguously in memory.
    This example also demonstrates how cute_ext.tma_load/cute_ext.tma_store performs automatic device side TMA updates.
    Note that the dimensions of the operand for each batch are the same across all batches. That is, all batches of A have the same shape and stride, same for B and D.

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
    :param d_dtype: Data type for output tensor D
    :type d_dtype: Type[Numeric]
    """
    print("Running Blackwell Dense GEMM test with:")
    print(f"mnkl: {mnkl}")
    print(f"AB dtype: {ab_dtype}, D dtype: {c_dtype}, Acc dtype: {acc_dtype}")
    print(f"Matrix majors - A: {a_major}, B: {b_major}, D: {c_major}")
    print(f"Mma Tiler (M, N): {mma_tiler_mn}, Cluster Shape (M, N): {cluster_shape_mn}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")

    m, n, k, l = mnkl

    ab_dtype = ab_dtype
    d_major = c_major
    d_dtype = c_dtype

    # a_tensor, b_tensor, d_tensor are cute Tensors where each element is an Int64 pointer to global memory
    # A_cutes, B_cutes, D_cutes are lists of cute Tensors for each batch of A/B/D
    (
        a_tensor,
        b_tensor,
        d_tensor,
        a_backing_torch_tensor,
        b_backing_torch_tensor,
        d_backing_torch_tensor,
        A_cutes,
        B_cutes,
        D_cutes,
        As_torch_gpu,
        Bs_torch_gpu,
        Ds_torch_gpu,
    ) = create_tensors_for_ptr_array(
        l, m, n, k, a_major, b_major, d_major, ab_dtype, d_dtype
    )

    ptr_array_dense_gemm = DenseGemmPtrArrayKernel(
        mn_tiler=mma_tiler_mn,
        mma_dtype=(ab_dtype, acc_dtype, d_dtype),
        tmem_output_dtype=d_dtype,
        batch_count=l,
        A_shape=A_cutes[0].shape,
        A_stride=A_cutes[0].stride,
        B_shape=B_cutes[0].shape,
        B_stride=B_cutes[0].stride,
        D_shape=D_cutes[0].shape,
        D_stride=D_cutes[0].stride,
    )

    compiled_dense_gemm = cute_ext.compile(
        ptr_array_dense_gemm, a_tensor, b_tensor, d_tensor
    )
    compiled_dense_gemm(a_tensor, b_tensor, d_tensor)

    if not skip_ref_check:
        for batch_idx in range(l):
            compare(
                As_torch_gpu[batch_idx].cpu(),
                Bs_torch_gpu[batch_idx].cpu(),
                Ds_torch_gpu[batch_idx],
                d_dtype,
                tolerance,
            )
        print("check reference: PASS")

    def generate_tensors():
        (
            a_tensor,
            b_tensor,
            d_tensor,
            a_backing_torch_tensor,
            b_backing_torch_tensor,
            d_backing_torch_tensor,
            A_cutes,
            B_cutes,
            D_cutes,
            As_torch_gpu,
            Bs_torch_gpu,
            Ds_torch_gpu,
        ) = create_tensors_for_ptr_array(
            l, m, n, k, a_major, b_major, d_major, ab_dtype, d_dtype
        )
        args = testing.JitArguments(a_tensor, b_tensor, d_tensor)
        args.add_to_scope([A_cutes, B_cutes, D_cutes])
        return args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            sum(
                As_torch_gpu[batch_idx].numel() * As_torch_gpu[batch_idx].element_size()
                for batch_idx in range(l)
            )
            + sum(
                Bs_torch_gpu[batch_idx].numel() * Bs_torch_gpu[batch_idx].element_size()
                for batch_idx in range(l)
            )
            + sum(
                Ds_torch_gpu[batch_idx].numel() * Ds_torch_gpu[batch_idx].element_size()
                for batch_idx in range(l)
            )
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

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser(description="Example of Dense GEMM on Blackwell.")

    parser.add_argument(
        "--mnkl",
        type=parse_comma_separated_ints,
        default=(256, 256, 512, 1),
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument(
        "--mma_tiler_mn",
        type=parse_comma_separated_ints,
        default=(128, 128),
        help="Mma tile shape (comma-separated)",
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(1, 1),
        help="Cluster shape (comma-separated)",
    )

    parser.add_argument("--ab_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--d_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)

    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--d_major", choices=["n", "m"], type=str, default="n")

    parser.add_argument(
        "--warmup_iterations", type=int, default=0, help="Warmup iterations"
    )
    parser.add_argument(
        "--iterations", type=int, default=1, help="Number of iterations"
    )
    parser.add_argument("--use_cold_l2", action="store_true", help="Use cold L2")
    parser.add_argument(
        "--tolerance", type=float, default=1e-02, help="Tolerance for validation"
    )
    parser.add_argument(
        "--skip_ref_check", action="store_true", help="Skip reference checking"
    )

    args = parser.parse_args()

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    if len(args.mma_tiler_mn) != 2:
        parser.error("--mma_tiler_mn must contain exactly 2 values")

    exec_time = run(
        args.mnkl,
        args.mma_tiler_mn,
        args.cluster_shape_mn,
        args.ab_dtype,
        args.d_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.d_major,
        args.warmup_iterations,
        args.iterations,
        args.use_cold_l2,
        args.tolerance,
        args.skip_ref_check,
    )

    print(f"Execution time: {exec_time} microseconds per iteration")
