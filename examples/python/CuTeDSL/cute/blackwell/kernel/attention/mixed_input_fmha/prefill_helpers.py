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

from typing import Tuple, Optional

import cutlass
import cutlass.cute as cute
import cutlass.cute.nvgpu.tcgen05 as tcgen05
import cutlass.pipeline as pipeline


@cute.jit
def load_qk(
    iterations: int,
    kv_step: cutlass.Int32,
    k_args: Tuple,
    scale_k_args: Optional[Tuple] = None,
    q_args: Optional[Tuple] = None,
) -> Tuple[pipeline.PipelineProducer, pipeline.PipelineProducer]:
    if cutlass.const_expr(q_args is not None):
        tQgQ, tQsQ, tma_atom_q, load_q_producer = q_args
    else:
        tQgQ, tQsQ, tma_atom_q, load_q_producer = None, None, None, None
    tKgK, tKsK, tma_atom_k, load_k_producer = k_args
    tKgScaleK, tKsScaleK, tma_atom_scale_k, load_scale_k_producer = scale_k_args

    scale_k_handle = load_scale_k_producer.acquire_and_advance()
    cute.copy(
        tma_atom_scale_k,
        tKgScaleK[None, kv_step],
        tKsScaleK[None, scale_k_handle.index],
        tma_bar_ptr=scale_k_handle.barrier,
    )
    for iter in cutlass.range(iterations, unroll=1):
        if cutlass.const_expr(q_args is not None):
            q_handle = load_q_producer.acquire_and_advance()
            cute.copy(
                tma_atom_q,
                tQgQ[None, iter],
                tQsQ[None, q_handle.index],
                tma_bar_ptr=q_handle.barrier,
            )
        k_handle = load_k_producer.acquire_and_advance()
        cute.copy(
            tma_atom_k,
            tKgK[None, kv_step, iter],
            tKsK[None, k_handle.index],
            tma_bar_ptr=k_handle.barrier,
        )
    if cutlass.const_expr(q_args is not None):
        return load_k_producer, load_scale_k_producer, load_q_producer
    else:
        return load_k_producer, load_scale_k_producer


@cute.jit
def load_v(
    iterations: int,
    kv_step: cutlass.Int32,
    v_args: Tuple,
    scale_v_args: Tuple,
) -> pipeline.PipelineProducer:
    tVgV, tVsV, tma_atom_v, load_v_producer = v_args
    tScaleVgV, tScaleVsV, tma_atom_scale_v, load_scale_v_producer = scale_v_args
    scale_v_handle = load_scale_v_producer.acquire_and_advance()
    cute.copy(
        tma_atom_scale_v,
        tScaleVgV[None, kv_step],
        tScaleVsV[None, scale_v_handle.index],
        tma_bar_ptr=scale_v_handle.barrier,
    )
    for iter in cutlass.range(iterations, unroll=1):
        v_handle = load_v_producer.acquire_and_advance()
        cute.copy(
            tma_atom_v,
            tVgV[None, iter, kv_step],
            tVsV[None, v_handle.index],
            tma_bar_ptr=v_handle.barrier,
        )
    return load_v_producer, load_scale_v_producer


@cute.jit
def get_scale_smem_layout(
    scale_granularity: int,
    d_r: int,
    mma_tiler: cute.Tile,
    major_mode: tcgen05.OperandMajorMode,
) -> Tuple[cute.Layout, cute.Tile]:
    size_mn = mma_tiler[1] // 2  # 2cta by default
    if cutlass.const_expr(major_mode == tcgen05.OperandMajorMode.MN):  # v
        scale_tiler = (mma_tiler[2] * d_r,)
        tma_view_layout = cute.make_layout(
            (mma_tiler[2] * d_r),
        )
        assert scale_granularity % mma_tiler[1] == 0, (
            "scale_granularity must be divisible by mma_tiler[1]"
        )
        rest_l = scale_granularity // mma_tiler[1]
        s2r_view_layout = cute.make_layout(
            (size_mn, mma_tiler[2], (rest_l, d_r)),
            stride=(0, d_r, (0, 1)),
        )
    else:  # k
        scale_tiler = (mma_tiler[1] * d_r,)
        tma_view_layout = cute.make_layout((size_mn * d_r))
        assert scale_granularity % mma_tiler[2] == 0, (
            "scale_granularity must be divisible by mma_tiler[2]"
        )
        rest_l = scale_granularity // mma_tiler[2]
        s2r_view_layout = cute.make_layout(
            (size_mn, mma_tiler[2], (rest_l, d_r)),
            stride=(d_r, 0, (0, 1)),
        )
    # Apply a trivial swizzle to make it a composed layout, which could be used to construct TMA atom
    tma_view_smem_layout = cute.make_composed_layout(
        cute.make_swizzle(0, 4, 3), 0, tma_view_layout
    )
    return tma_view_smem_layout, scale_tiler, s2r_view_layout


@cute.jit
def mma_qk(
    iterations: int,
    qk_tiled_mma: cute.TiledMma,
    tensor_args: Tuple,
    pipeline_args: Tuple,
):
    tStS, tSrQ, tSrK_trans = tensor_args
    mma_s_producer, load_q_consumer, load_q_releaser, dequant_kv_consumer = (
        pipeline_args
    )
    cta_rank_in_cluster = cute.arch.make_warp_uniform(cute.arch.block_idx_in_cluster())
    is_leader_cta = cta_rank_in_cluster % 2 == 0
    if is_leader_cta:
        s_handle = mma_s_producer.acquire_and_advance()
        tStS_slice = tStS[None, None, None, s_handle.index]
        qk_tiled_mma.set(tcgen05.Field.ACCUMULATE, False)
        for iter in cutlass.range(iterations, unroll=1):
            if cutlass.const_expr(load_q_consumer is not None):
                load_q_consumer.wait_and_advance()
            tSrQ_slice = tSrQ[None, None, None, iter]
            k_trans_handle = dequant_kv_consumer.wait_and_advance()
            tSrK_trans_slice = tSrK_trans[None, None, None, k_trans_handle.index]
            num_kphases = cute.size(tSrQ_slice, mode=[2])
            for kphase_idx in cutlass.range(num_kphases, unroll_full=True):
                kphase_coord = (None, None, kphase_idx)
                cute.gemm(
                    qk_tiled_mma,
                    tStS_slice,
                    tSrQ_slice[kphase_coord],
                    tSrK_trans_slice[kphase_coord],
                    tStS_slice,
                )
                qk_tiled_mma.set(tcgen05.Field.ACCUMULATE, True)
            k_trans_handle.release()
            if cutlass.const_expr(load_q_releaser is not None):
                load_q_releaser.release()
                load_q_releaser.advance()
        s_handle.commit()
    return mma_s_producer, load_q_consumer, dequant_kv_consumer


@cute.jit
def dequant_k(
    iterations: int,
    transform_warp_ids: Tuple,
    dtype_args: Tuple,
    tensor_args: Tuple,
    pipeline_args: Tuple,
):
    (k_dtype, q_dtype) = dtype_args
    (sOrig, sScale, sTrans) = tensor_args
    (load_kv_consumer, load_scale_consumer, dequant_kv_producer) = pipeline_args
    tidx, _, _ = cute.arch.thread_idx()
    THREADS_PER_WARP = 32
    thread_idx = tidx % (THREADS_PER_WARP * len(transform_warp_ids))
    r2s_copy_atom = cute.make_copy_atom(
        cute.nvgpu.CopyUniversalOp(), k_dtype, num_bits_per_copy=32
    )
    # Construct tiled_copy satisfying 16 contiguous elts per copy atom
    r2s_tiled_copy = cute.make_cotiled_copy(
        r2s_copy_atom,
        cute.make_layout((256, 16), stride=(16, 1)),
        sTrans[(None, None, None, 0)].layout,
    )
    thr_r2s_tiled_copy = r2s_tiled_copy.get_slice(thread_idx)
    tOsOrig = thr_r2s_tiled_copy.partition_S(sOrig)
    tTsTrans = thr_r2s_tiled_copy.partition_D(sTrans)
    tOrOrig = cute.make_rmem_tensor_like(
        cute.append(
            tOsOrig[None, None, None, None, 0].layout,
            cute.make_layout(
                2, stride=cute.cosize(tOsOrig[None, None, None, None, 0].layout)
            ),
        ),
        k_dtype,
    )
    tTrTrans = cute.make_rmem_tensor_like(
        cute.append(
            tTsTrans[None, None, None, None, 0].layout,
            cute.make_layout(
                2, stride=cute.cosize(tTsTrans[None, None, None, None, 0].layout)
            ),
        ),
        q_dtype,
    )
    tSsScale = thr_r2s_tiled_copy.partition_S(sScale)
    tSrScale = cute.make_rmem_tensor_like(tSsScale[None, None, None, None, None, 0])
    scale_handle = load_scale_consumer.wait_and_advance()
    cute.autovec_copy(
        tSsScale[None, None, None, None, None, scale_handle.index], tSrScale
    )
    cute.arch.fence_view_async_shared()
    scale_handle.release()
    # prefetch iter = 0
    kv_handle = load_kv_consumer.wait_and_advance()
    cute.autovec_copy(
        tOsOrig[None, None, None, None, kv_handle.index],
        tOrOrig[None, None, None, None, 0],
    )
    transformed_tensor = tOrOrig[None, None, None, None, 0].load().to(q_dtype)
    scale = cute.TensorSSA(
        tSrScale[None, None, None, None, 0].load(),
        transformed_tensor.shape,
        q_dtype,
    )
    transformed_tensor = transformed_tensor * scale
    tTrTrans[None, None, None, None, 0].store(transformed_tensor)
    cute.arch.fence_view_async_shared()
    kv_handle.release()
    for iter in cutlass.range(1, iterations, unroll_full=True):
        kv_trans_handle = dequant_kv_producer.acquire_and_advance()
        cute.autovec_copy(
            tTrTrans[None, None, None, None, (iter - 1) % 2],
            tTsTrans[None, None, None, None, kv_trans_handle.index],
        )
        cute.arch.fence_view_async_shared()
        kv_trans_handle.commit()
        kv_handle = load_kv_consumer.wait_and_advance()
        cute.autovec_copy(
            tOsOrig[None, None, None, None, kv_handle.index],
            tOrOrig[None, None, None, None, iter % 2],
        )
        transformed_tensor = (
            tOrOrig[None, None, None, None, iter % 2].load().to(q_dtype)
        )
        scale = cute.TensorSSA(
            tSrScale[None, None, None, None, iter].load(),
            transformed_tensor.shape,
            q_dtype,
        )
        transformed_tensor = transformed_tensor * scale
        tTrTrans[None, None, None, None, iter % 2].store(transformed_tensor)
        cute.arch.fence_view_async_shared()
        kv_handle.release()
    kv_trans_handle = dequant_kv_producer.acquire_and_advance()
    cute.autovec_copy(
        tTrTrans[None, None, None, None, (iterations - 1) % 2],
        tTsTrans[None, None, None, None, kv_trans_handle.index],
    )
    cute.arch.fence_view_async_shared()
    kv_trans_handle.commit()
    return load_kv_consumer, load_scale_consumer, dequant_kv_producer


@cute.jit
def dequant_v(
    iterations: int,
    transform_warp_ids: Tuple,
    dtype_args: Tuple,
    tensor_args: Tuple,
    pipeline_args: Tuple,
):
    (v_dtype, q_dtype) = dtype_args
    (sOrig, sScale, sTrans) = tensor_args
    (load_kv_consumer, load_scale_consumer, dequant_kv_producer) = pipeline_args
    tidx, _, _ = cute.arch.thread_idx()
    THREADS_PER_WARP = 32
    thread_idx = tidx % (THREADS_PER_WARP * len(transform_warp_ids))
    r2s_copy_atom = cute.make_copy_atom(
        cute.nvgpu.CopyUniversalOp(), v_dtype, num_bits_per_copy=32
    )
    # Construct tiled_copy satisfying 16 contiguous elts per copy atom
    r2s_tiled_copy = cute.make_cotiled_copy(
        r2s_copy_atom,
        cute.make_layout((256, 16), stride=(16, 1)),
        sTrans[(None, None, None, 0)].layout,
    )
    thr_r2s_tiled_copy = r2s_tiled_copy.get_slice(thread_idx)
    tOsOrig = thr_r2s_tiled_copy.partition_S(sOrig)
    tTsTrans = thr_r2s_tiled_copy.partition_D(sTrans)
    # double buffer for better perf
    tOrOrig = cute.make_rmem_tensor_like(
        cute.append(
            tOsOrig[None, None, None, None, 0].layout,
            cute.make_layout(
                2, stride=cute.cosize(tOsOrig[None, None, None, None, 0].layout)
            ),
        ),
        v_dtype,
    )
    tTrTrans = cute.make_rmem_tensor_like(
        cute.append(
            tTsTrans[None, None, None, None, 0].layout,
            cute.make_layout(
                2, stride=cute.cosize(tTsTrans[None, None, None, None, 0].layout)
            ),
        ),
        q_dtype,
    )
    tSsScale = thr_r2s_tiled_copy.partition_S(sScale)
    tSrScale = cute.make_rmem_tensor_like(tSsScale[None, None, None, None, None, 0])
    scale_v_handle = load_scale_consumer.wait_and_advance()
    cute.autovec_copy(
        tSsScale[None, None, None, None, None, scale_v_handle.index],
        tSrScale,
    )
    cute.arch.fence_view_async_shared()
    scale_v_handle.release()
    # prefetch iter = 0
    kv_handle = load_kv_consumer.wait_and_advance()
    cute.autovec_copy(
        tOsOrig[None, None, None, None, kv_handle.index],
        tOrOrig[None, None, None, None, 0],
    )
    transformed_tensor = tOrOrig[None, None, None, None, 0].load().to(q_dtype)
    scale = cute.TensorSSA(
        tSrScale[None, None, None, None, 0].load(),
        transformed_tensor.shape,
        q_dtype,
    )
    transformed_tensor = transformed_tensor * scale
    tTrTrans[None, None, None, None, 0].store(transformed_tensor)
    cute.arch.fence_view_async_shared()
    kv_handle.release()
    for iter in cutlass.range(1, iterations, unroll_full=True):
        kv_trans_handle = dequant_kv_producer.acquire_and_advance()
        cute.autovec_copy(
            tTrTrans[None, None, None, None, (iter - 1) % 2],
            tTsTrans[None, None, None, None, kv_trans_handle.index],
        )
        cute.arch.fence_view_async_shared()
        kv_trans_handle.commit()
        kv_handle = load_kv_consumer.wait_and_advance()
        cute.autovec_copy(
            tOsOrig[None, None, None, None, kv_handle.index],
            tOrOrig[None, None, None, None, iter % 2],
        )
        transformed_tensor = (
            tOrOrig[None, None, None, None, iter % 2].load().to(q_dtype)
        )
        scale = cute.TensorSSA(
            tSrScale[
                None,
                None,
                None,
                None,
                iter,
            ].load(),
            transformed_tensor.shape,
            q_dtype,
        )
        transformed_tensor = transformed_tensor * scale
        tTrTrans[None, None, None, None, iter % 2].store(transformed_tensor)
        cute.arch.fence_view_async_shared()
        kv_handle.release()
    kv_trans_handle = dequant_kv_producer.acquire_and_advance()
    cute.autovec_copy(
        tTrTrans[None, None, None, None, (iterations - 1) % 2],
        tTsTrans[None, None, None, None, kv_trans_handle.index],
    )
    cute.arch.fence_view_async_shared()
    kv_trans_handle.commit()
    return load_kv_consumer, load_scale_consumer, dequant_kv_producer
