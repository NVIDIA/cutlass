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

import os
import argparse
import csv
import socket
import time
from pathlib import Path
from math import gcd

from typing import Literal, Tuple, Type, Union

import cuda.bindings.driver as cuda

import torch
import torch.distributed as dist
import torch.distributed._symmetric_memory as symm_mem

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
import cutlass.torch as cutlass_torch
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
from cutlass.cute.nvgpu import cpasync, tcgen05, OperandMajorMode
import cutlass.utils.blockscaled_layout as blockscaled_utils
from cutlass.cute.runtime import from_dlpack, make_ptr
from cutlass.cutlass_dsl import BaseDSL

"""
SM100 BlockScale GEMM + AllReduce (LDMCxSTMC) Fusion Kernel

* Test (correctness only — single launch)
python3 -m torch.distributed.run --nproc-per-node=auto \
    examples/python/CuTeDSL/cute/blackwell/kernel/distributed/distributed_gemm_blockscaled_all_reduce_ldmcxstmc_blackwell.py \
    --a_dtype Float4E2M1FN --b_dtype Float4E2M1FN --sf_dtype Float8E4M3FN --sf_vec_size 16 \
    --c_dtype Float16 --a_major k --b_major k --c_major n \
    --mma_tiler_mn 256,256 --cluster_shape_mn 2,1 \
    --mnkl 8192,8192,8192,1 \
    --all_reduce LDMCxSTMC \
    --benchmark_or_test test

* Benchmark One
python3 -m torch.distributed.run --nproc-per-node=auto \
    examples/python/CuTeDSL/cute/blackwell/kernel/distributed/distributed_gemm_blockscaled_all_reduce_ldmcxstmc_blackwell.py \
    --a_dtype Float4E2M1FN --b_dtype Float4E2M1FN --sf_dtype Float8E4M3FN --sf_vec_size 16 \
    --c_dtype Float16 --a_major k --b_major k --c_major n \
    --mma_tiler_mn 256,256 --cluster_shape_mn 2,1 \
    --mnkl 8192,8192,8192,1 --warmup_iterations 10 --iterations 20 \
    --swizzle_size 1 --raster_order m \
    --all_reduce LDMCxSTMC \
    --benchmark_or_test benchmark --use_cuda_graph --csv_report ./csv_report_blockscaled_ar.csv

* Benchmark All (sweeps mma_tiler_mn x cluster_shape_mn; sf_vec_size/dtypes fixed per invocation)
python3 -m torch.distributed.run --nproc-per-node=auto \
    examples/python/CuTeDSL/cute/blackwell/kernel/distributed/distributed_gemm_blockscaled_all_reduce_ldmcxstmc_blackwell.py \
    --a_dtype Float4E2M1FN --b_dtype Float4E2M1FN --sf_dtype Float8E4M3FN --sf_vec_size 16 \
    --c_dtype Float16 \
    --mnkl 8192,8192,8192,1 --warmup_iterations 10 --iterations 20 \
    --benchmark_or_test benchmark_all --use_cuda_graph --csv_report ./csv_report_blockscaled_ar.csv

NOTE:
* benchmark_all sweeps (mma_tiler_mn, cluster_shape_mn, raster_order, swizzle_size). use_2cta_instrs is implied by
  mma_tiler_mn[0]==256. dtype/sf_vec_size/majors are FIXED per invocation.
"""

#####################################################################
#### KERNEL IMPLEMENTATION START HERE ####
#####################################################################


@cute.jit
def LDMCxSTMC(
    kernel,
    cur_tile_coord,
    tiled_mma: cute.TiledMma,
    comm_tidx: cutlass.Int32,
    tCgCommInMC: cute.Tensor,
    tCgCommOutMC: cute.Tensor,
) -> None:
    mma_tile_coord_mnl = (
        cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
        cur_tile_coord[1],
        cur_tile_coord[2],
    )

    # partition and slice at tile level
    tCgCommInMC_slice = tCgCommInMC[((None, None), 0, 0, *mma_tile_coord_mnl)]
    tCgCommOutMC_slice = tCgCommOutMC[((None, None), 0, 0, *mma_tile_coord_mnl)]

    #
    # Partition s.t. each rank handle 1/P of this tile
    # For row-major (N-contiguous): split along M to keep memory contiguous per rank
    # For col-major (M-contiguous): split along N to keep memory contiguous per rank
    #
    cta_mma_tile_m = kernel.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape)
    cta_tile_n = kernel.mma_tiler[1]
    total_comm_threads = len(kernel.comm_warp_id) * cute.arch.WARP_SIZE

    if cutlass.const_expr(kernel.c_layout.is_n_major_c()):
        # Row-major (N-contiguous): split along M
        m_local_rank = int(cta_mma_tile_m / kernel.num_ranks)
        tCgCommInMC_slice_partitioned = cute.zipped_divide(
            tCgCommInMC_slice, (m_local_rank, cta_tile_n)
        )
        tCgCommOutMC_slice_partitioned = cute.zipped_divide(
            tCgCommOutMC_slice, (m_local_rank, cta_tile_n)
        )
        # Data processed by local rank: select M chunk
        tCgCommInMC_local_rank = cute.slice_(
            tCgCommInMC_slice_partitioned, ((None, None), (kernel.rank_id, 0))
        )
        tCgCommOutMC_local_rank = cute.slice_(
            tCgCommOutMC_slice_partitioned, ((None, None), (kernel.rank_id, 0))
        )
        local_tile_m = m_local_rank
        local_tile_n = cta_tile_n
    else:
        # Col-major (M-contiguous): split along N
        n_local_rank = int(cta_tile_n / kernel.num_ranks)
        tCgCommInMC_slice_partitioned = cute.zipped_divide(
            tCgCommInMC_slice, (cta_mma_tile_m, n_local_rank)
        )
        tCgCommOutMC_slice_partitioned = cute.zipped_divide(
            tCgCommOutMC_slice, (cta_mma_tile_m, n_local_rank)
        )
        # Data processed by local rank: select N chunk
        tCgCommInMC_local_rank = cute.slice_(
            tCgCommInMC_slice_partitioned, ((None, None), (0, kernel.rank_id))
        )
        tCgCommOutMC_local_rank = cute.slice_(
            tCgCommOutMC_slice_partitioned, ((None, None), (0, kernel.rank_id))
        )
        local_tile_m = cta_mma_tile_m
        local_tile_n = n_local_rank

    #
    # Determine vectorization length based on data size per thread
    # Always use 128-bit instructions (guaranteed by _pick_num_comm_warp_for_128b)
    #
    elements_per_thread = (local_tile_m * local_tile_n) // total_comm_threads

    # Always use 128-bit atom size
    # Guaranteed by _pick_num_comm_warp_for_128b which selects T to ensure
    # elements_per_thread is divisible by 128-bit atom (16B = 128 bits)
    atom_num_elements_128 = 128 // kernel.c_dtype.width
    atom_num_elements = atom_num_elements_128

    # COMPILE-TIME ASSERTION: Verify 128-bit PTX instruction usage
    # _pick_num_comm_warp_for_128b selects num_warps such that every thread
    # in the AllReduce warp group handles exactly atom_num_elements_128 elements,
    # which means exactly one 128-bit LDMC/STMC instruction per AR slab iteration.
    assert elements_per_thread % atom_num_elements_128 == 0, (
        f"KERNEL ASSERTION: 128-bit PTX instruction invariant violated. "
        f"elements_per_thread={elements_per_thread} must be divisible by "
        f"atom_num_elements_128={atom_num_elements_128}. "
        f"This ensures every thread executes exactly one 128-bit instruction. "
        f"Configuration: local_tile=({local_tile_m},{local_tile_n}), "
        f"total_comm_threads={total_comm_threads}, c_dtype={kernel.c_dtype}"
    )

    #
    # Create thr_copy_fake with dynamically selected atom size
    # For row-major: threads spread along N (contiguous), load along N
    # For col-major: threads spread along M (contiguous), load along M
    #
    if cutlass.const_expr(kernel.c_layout.is_n_major_c()):
        # Row-major: N is contiguous, spread threads along N.
        # Use GCD to handle non-power-of-2 tile widths (e.g. cta_n=192)
        # that don't naively divide the thread count.
        max_thr_n = local_tile_n // atom_num_elements
        atom_thr_n = gcd(max_thr_n, total_comm_threads)
        atom_thr_m = total_comm_threads // atom_thr_n
        thr_layout = cute.make_layout((atom_thr_m, atom_thr_n), stride=(atom_thr_n, 1))
        val_layout = cute.make_layout(
            (1, atom_num_elements), stride=(atom_num_elements, 1)
        )
    else:
        # Col-major: M is contiguous, spread threads along M.
        max_thr_m = local_tile_m // atom_num_elements
        atom_thr_m = gcd(max_thr_m, total_comm_threads)
        atom_thr_n = total_comm_threads // atom_thr_m
        thr_layout = cute.make_layout((atom_thr_m, atom_thr_n), stride=(1, atom_thr_m))
        val_layout = cute.make_layout(
            (atom_num_elements, 1), stride=(1, atom_num_elements)
        )

    copy_atom_load = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), kernel.c_dtype)
    tiled_copy_fake = cute.make_tiled_copy_tv(copy_atom_load, thr_layout, val_layout)
    thr_copy_fake = tiled_copy_fake.get_slice(comm_tidx - kernel.comm_warp_id[0] * 32)

    #
    # Partition per thread
    #
    tTR_gCommInMC = thr_copy_fake.partition_S(tCgCommInMC_local_rank)
    tTR_gCommOutMC = thr_copy_fake.partition_S(tCgCommOutMC_local_rank)
    _atom, loop_m, loop_n = tTR_gCommInMC.shape

    #
    # All Reduce LDMCxSTMC — adaptive variant based on ldmcxstmc_default_inflight_depth:
    # - ldmcxstmc_default_inflight_depth=2: pair-issue (2-element chunks)
    # - ldmcxstmc_default_inflight_depth=4: quad-issue (4-element chunks)
    # The chunk loop is staged as scf.for with explicit `unroll=1` hint.
    #
    total_iters = loop_m * loop_n

    if cutlass.const_expr(kernel.ldmcxstmc_default_inflight_depth == 2):
        # Pair-issue variant (inflight2)
        num_pairs = total_iters // 2
        for k in cutlass.range(num_pairs, unroll=1):
            i0 = (2 * k) // loop_n
            j0 = (2 * k) % loop_n
            i1 = (2 * k + 1) // loop_n
            j1 = (2 * k + 1) % loop_n

            in0 = tTR_gCommInMC[None, i0, j0].iterator
            out0 = tTR_gCommOutMC[None, i0, j0].iterator
            in1 = tTR_gCommInMC[None, i1, j1].iterator
            out1 = tTR_gCommOutMC[None, i1, j1].iterator

            regs0 = utils.distributed.multimem_ld_reduce(
                in0, dtype=kernel.c_dtype, num_elements=atom_num_elements
            )
            regs1 = utils.distributed.multimem_ld_reduce(
                in1, dtype=kernel.c_dtype, num_elements=atom_num_elements
            )
            utils.distributed.multimem_st(out0, *regs0)
            utils.distributed.multimem_st(out1, *regs1)

        # Trailing odd iteration (singleton) when total_iters is odd.
        if cutlass.const_expr(total_iters % 2 == 1):
            last = total_iters - 1
            i = last // loop_n
            j = last % loop_n
            in_ = tTR_gCommInMC[None, i, j].iterator
            out_ = tTR_gCommOutMC[None, i, j].iterator
            regs = utils.distributed.multimem_ld_reduce(
                in_, dtype=kernel.c_dtype, num_elements=atom_num_elements
            )
            utils.distributed.multimem_st(out_, *regs)
    else:
        # Quad-issue variant (inflight4, default)
        num_quads = total_iters // 4
        for k in cutlass.range(num_quads, unroll=1):
            i0 = (4 * k) // loop_n
            j0 = (4 * k) % loop_n
            i1 = (4 * k + 1) // loop_n
            j1 = (4 * k + 1) % loop_n
            i2 = (4 * k + 2) // loop_n
            j2 = (4 * k + 2) % loop_n
            i3 = (4 * k + 3) // loop_n
            j3 = (4 * k + 3) % loop_n

            in0 = tTR_gCommInMC[None, i0, j0].iterator
            out0 = tTR_gCommOutMC[None, i0, j0].iterator
            in1 = tTR_gCommInMC[None, i1, j1].iterator
            out1 = tTR_gCommOutMC[None, i1, j1].iterator
            in2 = tTR_gCommInMC[None, i2, j2].iterator
            out2 = tTR_gCommOutMC[None, i2, j2].iterator
            in3 = tTR_gCommInMC[None, i3, j3].iterator
            out3 = tTR_gCommOutMC[None, i3, j3].iterator

            regs0 = utils.distributed.multimem_ld_reduce(
                in0, dtype=kernel.c_dtype, num_elements=atom_num_elements
            )
            regs1 = utils.distributed.multimem_ld_reduce(
                in1, dtype=kernel.c_dtype, num_elements=atom_num_elements
            )
            regs2 = utils.distributed.multimem_ld_reduce(
                in2, dtype=kernel.c_dtype, num_elements=atom_num_elements
            )
            regs3 = utils.distributed.multimem_ld_reduce(
                in3, dtype=kernel.c_dtype, num_elements=atom_num_elements
            )
            utils.distributed.multimem_st(out0, *regs0)
            utils.distributed.multimem_st(out1, *regs1)
            utils.distributed.multimem_st(out2, *regs2)
            utils.distributed.multimem_st(out3, *regs3)

        # Tail: total_iters % 4 == 1 → 1 trailing LDMC + 1 STMC.
        if cutlass.const_expr(total_iters % 4 == 1):
            last = total_iters - 1
            i = last // loop_n
            j = last % loop_n
            in_ = tTR_gCommInMC[None, i, j].iterator
            out_ = tTR_gCommOutMC[None, i, j].iterator
            regs = utils.distributed.multimem_ld_reduce(
                in_, dtype=kernel.c_dtype, num_elements=atom_num_elements
            )
            utils.distributed.multimem_st(out_, *regs)
        # Tail: total_iters % 4 == 2 → 2 trailing LDMCs + 2 STMCs.
        if cutlass.const_expr(total_iters % 4 == 2):
            flat0 = total_iters - 2
            flat1 = total_iters - 1
            i0 = flat0 // loop_n
            j0 = flat0 % loop_n
            i1 = flat1 // loop_n
            j1 = flat1 % loop_n
            in0 = tTR_gCommInMC[None, i0, j0].iterator
            out0 = tTR_gCommOutMC[None, i0, j0].iterator
            in1 = tTR_gCommInMC[None, i1, j1].iterator
            out1 = tTR_gCommOutMC[None, i1, j1].iterator
            regs0 = utils.distributed.multimem_ld_reduce(
                in0, dtype=kernel.c_dtype, num_elements=atom_num_elements
            )
            regs1 = utils.distributed.multimem_ld_reduce(
                in1, dtype=kernel.c_dtype, num_elements=atom_num_elements
            )
            utils.distributed.multimem_st(out0, *regs0)
            utils.distributed.multimem_st(out1, *regs1)
        # Tail: total_iters % 4 == 3 → 3 trailing LDMCs + 3 STMCs.
        if cutlass.const_expr(total_iters % 4 == 3):
            flat0 = total_iters - 3
            flat1 = total_iters - 2
            flat2 = total_iters - 1
            i0 = flat0 // loop_n
            j0 = flat0 % loop_n
            i1 = flat1 // loop_n
            j1 = flat1 % loop_n
            i2 = flat2 // loop_n
            j2 = flat2 % loop_n
            in0 = tTR_gCommInMC[None, i0, j0].iterator
            out0 = tTR_gCommOutMC[None, i0, j0].iterator
            in1 = tTR_gCommInMC[None, i1, j1].iterator
            out1 = tTR_gCommOutMC[None, i1, j1].iterator
            in2 = tTR_gCommInMC[None, i2, j2].iterator
            out2 = tTR_gCommOutMC[None, i2, j2].iterator
            regs0 = utils.distributed.multimem_ld_reduce(
                in0, dtype=kernel.c_dtype, num_elements=atom_num_elements
            )
            regs1 = utils.distributed.multimem_ld_reduce(
                in1, dtype=kernel.c_dtype, num_elements=atom_num_elements
            )
            regs2 = utils.distributed.multimem_ld_reduce(
                in2, dtype=kernel.c_dtype, num_elements=atom_num_elements
            )
            utils.distributed.multimem_st(out0, *regs0)
            utils.distributed.multimem_st(out1, *regs1)
            utils.distributed.multimem_st(out2, *regs2)


class Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel:
    """SM100 Persistent block-scaled GEMM + AllReduce (LDMCxSTMC) fusion kernel for Blackwell GPUs.

    **Example:**
        gemm = Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel(
            sf_vec_size=16,
            mma_tiler_mn=(256, 256),
            cluster_shape_mn=(2, 1),
            c_dtype=cutlass.Float16,
            rank_id=rank,
            num_ranks=world_size,
        )
        gemm(a_ptr, b_ptr, sfa_ptr, sfb_ptr, c_ptr, layouts, problem_mnkl,
             max_active_clusters, stream, comm_in_multicast_tensor=...,
             comm_out_multicast_tensor=..., barrier_flag_unicast=...,
             barrier_flag_multicast=...)
    """

    def __init__(
        self,
        sf_vec_size: int,
        mma_tiler_mn: Tuple[int, int] = (256, 256),
        cluster_shape_mn: Tuple[int, int] = (2, 1),
        c_dtype: Type[cutlass.Numeric] = cutlass.Float16,
        rank_id: int = 0,
        num_ranks: int = 8,
        swizzle_size: int = 1,
        raster_order: Literal["m", "n"] = "m",
    ):
        self.acc_dtype = cutlass.Float32
        self.sf_vec_size = sf_vec_size
        self.use_2cta_instrs = mma_tiler_mn[0] == 256
        self.cluster_shape_mn = cluster_shape_mn
        self.swizzle_size = swizzle_size
        self.raster_order = raster_order
        arch_enum = BaseDSL._get_dsl().get_arch_enum()
        self.arch = f"sm_{arch_enum.major}{arch_enum.minor}"
        self.mma_tiler_mn = mma_tiler_mn
        self.c_dtype = c_dtype
        # K dimension is deferred in _setup_attributes
        self.mma_tiler = (*mma_tiler_mn, 1)

        self.cta_group = (
            tcgen05.CtaGroup.TWO if self.use_2cta_instrs else tcgen05.CtaGroup.ONE
        )

        self.occupancy = 1
        # Set specialized warp ids
        self.epilogue_warp_id = (0, 1, 2, 3)
        self.mma_warp_id = 4
        self.tma_warp_id = 5
        self.rank_id = rank_id
        self.num_ranks = num_ranks
        num_comm_warps = self._pick_num_comm_warp_for_128b(c_dtype)
        self.comm_warp_id = tuple(range(6, 6 + num_comm_warps))
        cta_tile_m = mma_tiler_mn[0] // 2 if mma_tiler_mn[0] == 256 else mma_tiler_mn[0]
        cta_tile_n = mma_tiler_mn[1]
        self.ldmcxstmc_default_inflight_depth = 4
        self.comm_sync_bar_id = 4
        self.all_reduce = "LDMCxSTMC"
        self.threads_per_warp = 32
        self.threads_per_cta = self.threads_per_warp * len(
            (
                self.mma_warp_id,
                self.tma_warp_id,
                *self.epilogue_warp_id,
                *self.comm_warp_id,
            )
        )
        # Set barrier id for epilogue sync and tmem ptr sync
        self.epilogue_sync_barrier = pipeline.NamedBarrier(
            barrier_id=1,
            num_threads=self.threads_per_warp * len(self.epilogue_warp_id),
        )
        self.tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=2,
            num_threads=self.threads_per_warp
            * len((self.mma_warp_id, *self.epilogue_warp_id)),
        )
        self.smem_capacity = utils.get_smem_capacity_in_bytes(self.arch)
        self.num_tmem_alloc_cols = cute.arch.get_max_tmem_alloc_cols(self.arch)

    def _pick_num_comm_warp_for_128b(self, c_dtype):
        """Pick the LARGEST comm-warp count W ∈ {4, 3, 2, 1} (T = W·32 ∈
        {128, 96, 64, 32}) such that the AR slab is evenly distributed
        across T threads AND every thread gets a full 128 b LDMC payload
        (= ``atom_128`` elements, where ``atom_128 = 16 / sizeof(c_dtype)``).

        Iterates W = 4 → 1 and returns the first match, so the largest
        viable W is returned. Smaller W is only chosen when strictly
        necessary, because larger W means more parallel AR threads and
        proportionally fewer per-thread PTX instructions.
        """
        # cta-tile dims (the per-CTA M·N output the AR walks). 2cta halves M.
        cta_mma_tile_m = self.mma_tiler_mn[0] // (2 if self.use_2cta_instrs else 1)
        cta_tile_n = self.mma_tiler_mn[1]
        slab_elements = (cta_mma_tile_m * cta_tile_n) // self.num_ranks
        atom_128 = 16 // (c_dtype.width // 8)
        for num_warps in (4, 3, 2, 1):
            T = num_warps * 32
            if slab_elements % T:
                continue
            if (slab_elements // T) % atom_128 == 0:
                return num_warps
        raise ValueError(
            f"no comm-warp count enables 128 b PTX for c_dtype={c_dtype}, "
            f"cta=({cta_mma_tile_m},{cta_tile_n}), P={self.num_ranks}"
        )

    def _setup_attributes(self):
        # (MMA_Tile_Shape_M, MMA_Tile_Shape_N, MMA_Inst_Shape_K)
        self.mma_inst_shape_mn = (
            self.mma_tiler[0],
            self.mma_tiler[1],
        )
        # (CTA_Tile_Shape_M, Round_Up(MMA_Tile_Shape_N, 128), MMA_Inst_Shape_K)
        self.mma_inst_shape_mn_sfb = (
            self.mma_inst_shape_mn[0] // (2 if self.use_2cta_instrs else 1),
            cute.round_up(self.mma_inst_shape_mn[1], 128),
        )

        tiled_mma = utils.sm100.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape_mn,
        )

        tiled_mma_sfb = utils.sm100.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            cute.nvgpu.tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_mn_sfb,
        )

        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        self.mma_tiler = (
            self.mma_inst_shape_mn[0],
            self.mma_inst_shape_mn[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )
        self.mma_tiler_sfb = (
            self.mma_inst_shape_mn_sfb[0],
            self.mma_inst_shape_mn_sfb[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )
        self.cta_tile_shape_mnk_sfb = (
            self.mma_tiler_sfb[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler_sfb[1],
            self.mma_tiler_sfb[2],
        )

        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )
        self.cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma_sfb.thr_id.shape,),
        )

        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.num_mcast_ctas_sfb = cute.size(self.cluster_layout_sfb_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1
        self.is_sfb_mcast = self.num_mcast_ctas_sfb > 1

        self.epi_tile = utils.sm100.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.c_layout,
            self.c_dtype,
        )
        self.epi_tile_n = cute.size(self.epi_tile[1])

        self.num_acc_stage, self.num_ab_stage, self.num_c_stage = self._compute_stages(
            tiled_mma,
            self.mma_tiler,
            self.smem_alloc_a_dtype,
            self.smem_alloc_b_dtype,
            self.epi_tile,
            self.c_dtype,
            self.c_layout,
            self.sf_dtype,
            self.sf_vec_size,
            self.smem_capacity,
            self.occupancy,
        )

        self.a_smem_layout_staged = utils.sm100.make_smem_layout_a(
            tiled_mma,
            self.mma_tiler,
            self.smem_alloc_a_dtype,
            self.num_ab_stage,
        )
        self.b_smem_layout_staged = utils.sm100.make_smem_layout_b(
            tiled_mma,
            self.mma_tiler,
            self.smem_alloc_b_dtype,
            self.num_ab_stage,
        )
        self.sfa_smem_layout_staged = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            self.num_ab_stage,
        )
        self.sfb_smem_layout_staged = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            self.num_ab_stage,
        )
        self.c_smem_layout_staged = utils.sm100.make_smem_layout_epi(
            self.c_dtype,
            self.c_layout,
            self.epi_tile,
            self.num_c_stage,
        )

        # Overlap and double buffer accumulator when num_acc_stage == 1 for cta_tile_n = 256 case
        self.overlapping_accum = self.num_acc_stage == 1

        sf_atom_mn = 32
        self.num_sfa_tmem_cols = (
            self.cta_tile_shape_mnk[0] // sf_atom_mn
        ) * mma_inst_tile_k
        self.num_sfb_tmem_cols = (
            self.cta_tile_shape_mnk_sfb[1] // sf_atom_mn
        ) * mma_inst_tile_k
        self.num_sf_tmem_cols = self.num_sfa_tmem_cols + self.num_sfb_tmem_cols
        self.num_accumulator_tmem_cols = (
            self.cta_tile_shape_mnk[1] * self.num_acc_stage
            if not self.overlapping_accum
            else self.cta_tile_shape_mnk[1] * 2 - self.num_sf_tmem_cols
        )

        self.iter_acc_early_release_in_epilogue = (
            self.num_sf_tmem_cols // self.epi_tile_n
        )

    @cute.jit
    def __call__(
        self,
        a_ptr: cute.Pointer,
        b_ptr: cute.Pointer,
        sfa_ptr: cute.Pointer,
        sfb_ptr: cute.Pointer,
        c_ptr: cute.Pointer,
        layouts: cutlass.Constexpr[
            Tuple[OperandMajorMode, OperandMajorMode, utils.LayoutEnum]
        ],
        problem_mnkl: Tuple[int, int, int, int],
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        epilogue_op: cutlass.Constexpr = lambda x: x,
        comm_in_multicast_tensor: cute.Tensor = None,
        comm_out_multicast_tensor: cute.Tensor = None,
        barrier_flag_unicast: cute.Tensor = None,
        barrier_flag_multicast: cute.Tensor = None,
    ):
        # Setup static attributes before smem/grid/tma computation
        self.a_dtype: Type[cutlass.Numeric] = a_ptr.value_type
        self.b_dtype: Type[cutlass.Numeric] = b_ptr.value_type
        self.sf_dtype: Type[cutlass.Numeric] = sfa_ptr.value_type
        self.c_dtype: Type[cutlass.Numeric] = c_ptr.value_type
        self.mxf8f6f4 = self.needs_unpack_tma(self.a_dtype, self.b_dtype)
        self.smem_alloc_a_dtype = (
            cutlass.Int8 if (self.mxf8f6f4 and self.a_dtype.width < 8) else self.a_dtype
        )
        self.smem_alloc_b_dtype = (
            cutlass.Int8 if (self.mxf8f6f4 and self.b_dtype.width < 8) else self.b_dtype
        )
        m, n, k, l = problem_mnkl
        self.a_major_mode, self.b_major_mode, self.c_layout = layouts

        # Setup attributes that dependent on gemm inputs
        self._setup_attributes()

        a_layout = cute.make_ordered_layout((m, cute.assume(k, 32), l), order=(0, 1, 2))
        if cutlass.const_expr(self.a_major_mode == OperandMajorMode.K):
            a_layout = cute.make_ordered_layout(
                (cute.assume(m, 32), k, l), order=(1, 0, 2)
            )
        b_layout = cute.make_ordered_layout((n, cute.assume(k, 32), l), order=(0, 1, 2))
        if cutlass.const_expr(self.b_major_mode == OperandMajorMode.K):
            b_layout = cute.make_ordered_layout(
                (cute.assume(n, 32), k, l), order=(1, 0, 2)
            )
        c_layout = cute.make_ordered_layout((cute.assume(m, 32), n, l), order=(0, 1, 2))
        if cutlass.const_expr(self.c_layout == utils.LayoutEnum.ROW_MAJOR):
            c_layout = cute.make_ordered_layout(
                (m, cute.assume(n, 32), l), order=(1, 0, 2)
            )
        a_tensor = cute.make_tensor(a_ptr, a_layout)
        b_tensor = cute.make_tensor(b_ptr, b_layout)
        c_tensor = cute.make_tensor(c_ptr, c_layout)

        mCommInMC_mnl = comm_in_multicast_tensor
        mCommOutMC_mnl = comm_out_multicast_tensor

        # Setup sfa/sfb tensor by filling A/B tensor to scale factor atom layout
        # ((Atom_M, Rest_M),(Atom_K, Rest_K),RestL)
        sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(
            a_tensor.shape, self.sf_vec_size
        )
        sfa_tensor = cute.make_tensor(sfa_ptr, sfa_layout)

        # ((Atom_N, Rest_N),(Atom_K, Rest_K),RestL)
        sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(
            b_tensor.shape, self.sf_vec_size
        )
        sfb_tensor = cute.make_tensor(sfb_ptr, sfb_layout)

        tiled_mma = utils.sm100.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape_mn,
        )

        # For 2CTA blockscaled kernels, SFB needs to be replicated across peer CTAs.
        tiled_mma_sfb = utils.sm100.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            cute.nvgpu.tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_mn_sfb,
        )
        atom_thr_size = cute.size(tiled_mma.thr_id.shape)

        # Setup TMA load for A
        a_op = utils.sm100.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, None, 0))
        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            a_op,
            a_tensor,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=self.smem_alloc_a_dtype
            if (self.mxf8f6f4 and self.a_dtype.width < 8)
            else None,
        )

        # Setup TMA load for B
        b_op = utils.sm100.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        b_smem_layout = cute.slice_(self.b_smem_layout_staged, (None, None, None, 0))
        tma_atom_b, tma_tensor_b = cute.nvgpu.make_tiled_tma_atom_B(
            b_op,
            b_tensor,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=self.smem_alloc_b_dtype
            if (self.mxf8f6f4 and self.b_dtype.width < 8)
            else None,
        )

        # Setup TMA load for SFA
        sfa_op = utils.sm100.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfa_smem_layout = cute.slice_(
            self.sfa_smem_layout_staged, (None, None, None, 0)
        )
        tma_atom_sfa, tma_tensor_sfa = cute.nvgpu.make_tiled_tma_atom_A(
            sfa_op,
            sfa_tensor,
            sfa_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=cutlass.Int16,
        )

        # Setup TMA load for SFB
        sfb_op = utils.sm100.cluster_shape_to_tma_atom_SFB(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfb_smem_layout = cute.slice_(
            self.sfb_smem_layout_staged, (None, None, None, 0)
        )
        tma_atom_sfb, tma_tensor_sfb = cute.nvgpu.make_tiled_tma_atom_B(
            sfb_op,
            sfb_tensor,
            sfb_smem_layout,
            self.mma_tiler_sfb,
            tiled_mma_sfb,
            self.cluster_layout_sfb_vmnk.shape,
            internal_type=cutlass.Int16,
        )

        if cutlass.const_expr(self.cta_tile_shape_mnk[1] == 192):
            x = tma_tensor_sfb.stride[0][1]
            y = cute.ceil_div(tma_tensor_sfb.shape[0][1], 4)

            new_shape = (
                (tma_tensor_sfb.shape[0][0], ((2, 2), y)),
                tma_tensor_sfb.shape[1],
                tma_tensor_sfb.shape[2],
            )
            # Use right multiplication for ScaledBasis (3 * x instead of x * 3)
            x_times_3 = 3 * x
            new_stride = (
                (tma_tensor_sfb.stride[0][0], ((x, x), x_times_3)),
                tma_tensor_sfb.stride[1],
                tma_tensor_sfb.stride[2],
            )
            tma_tensor_sfb_new_layout = cute.make_layout(new_shape, stride=new_stride)
            tma_tensor_sfb = cute.make_tensor(
                tma_tensor_sfb.iterator, tma_tensor_sfb_new_layout
            )

        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        sfa_copy_size = cute.size_in_bytes(self.sf_dtype, sfa_smem_layout)
        sfb_copy_size = cute.size_in_bytes(self.sf_dtype, sfb_smem_layout)
        self.num_tma_load_bytes = (
            a_copy_size + b_copy_size + sfa_copy_size + sfb_copy_size
        ) * atom_thr_size

        # Setup TMA store for C
        epi_smem_layout = cute.slice_(self.c_smem_layout_staged, (None, None, 0))
        tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileS2GOp(),
            c_tensor,
            epi_smem_layout,
            self.epi_tile,
        )

        # Compute grid size
        self.tile_sched_params, grid = self._compute_grid(
            c_tensor,
            self.cta_tile_shape_mnk,
            self.cluster_shape_mn,
            self.swizzle_size,
            self.raster_order,
            max_active_clusters,
        )

        self.buffer_align_bytes = 1024

        # Define shared storage for kernel
        @cute.struct
        class SharedStorage:
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            ab_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            acc_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            tmem_dealloc_mbar: cutlass.Int64
            tmem_holding_buf: cutlass.Int32
            # (EPI_TILE_M, EPI_TILE_N, STAGE)
            sC: cute.struct.Align[
                cute.struct.MemRange[
                    self.c_dtype,
                    cute.cosize(self.c_smem_layout_staged.outer),
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_M, MMA_K, STAGE)
            sA: cute.struct.Align[
                cute.struct.MemRange[
                    self.smem_alloc_a_dtype,
                    cute.cosize(self.a_smem_layout_staged.outer),
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sB: cute.struct.Align[
                cute.struct.MemRange[
                    self.smem_alloc_b_dtype,
                    cute.cosize(self.b_smem_layout_staged.outer),
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_M, MMA_K, STAGE)
            sSFA: cute.struct.Align[
                cute.struct.MemRange[
                    self.sf_dtype, cute.cosize(self.sfa_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sSFB: cute.struct.Align[
                cute.struct.MemRange[
                    self.sf_dtype, cute.cosize(self.sfb_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        # Launch the kernel synchronously
        self.kernel(
            tiled_mma=tiled_mma,
            tiled_mma_sfb=tiled_mma_sfb,
            tma_atom_a=tma_atom_a,
            mA_mkl=tma_tensor_a,
            tma_atom_b=tma_atom_b,
            mB_nkl=tma_tensor_b,
            tma_atom_sfa=tma_atom_sfa,
            mSFA_mkl=tma_tensor_sfa,
            tma_atom_sfb=tma_atom_sfb,
            mSFB_nkl=tma_tensor_sfb,
            tma_atom_c=tma_atom_c,
            mC_mnl=tma_tensor_c,
            mCommInMC_mnl=mCommInMC_mnl,
            mCommOutMC_mnl=mCommOutMC_mnl,
            barrier_flag_unicast=barrier_flag_unicast,
            barrier_flag_multicast=barrier_flag_multicast,
            cluster_layout_vmnk=self.cluster_layout_vmnk,
            cluster_layout_sfb_vmnk=self.cluster_layout_sfb_vmnk,
            a_smem_layout_staged=self.a_smem_layout_staged,
            b_smem_layout_staged=self.b_smem_layout_staged,
            sfa_smem_layout_staged=self.sfa_smem_layout_staged,
            sfb_smem_layout_staged=self.sfb_smem_layout_staged,
            c_smem_layout_staged=self.c_smem_layout_staged,
            epi_tile=self.epi_tile,
            tile_sched_params=self.tile_sched_params,
            epilogue_op=epilogue_op,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            stream=stream,
            min_blocks_per_mp=1,
        )
        return

    # GPU device kernel
    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tiled_mma_sfb: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_sfa: cute.CopyAtom,
        mSFA_mkl: cute.Tensor,
        tma_atom_sfb: cute.CopyAtom,
        mSFB_nkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom,
        mC_mnl: cute.Tensor,
        mCommInMC_mnl: cute.Tensor,
        mCommOutMC_mnl: cute.Tensor,
        barrier_flag_unicast: cute.Tensor,
        barrier_flag_multicast: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        cluster_layout_sfb_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout],
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        epilogue_op: cutlass.Constexpr,
    ):
        """
        GPU device kernel performing the Persistent batched GEMM computation.
        """
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        #
        # Prefetch tma desc
        #
        if warp_idx == self.tma_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            cpasync.prefetch_descriptor(tma_atom_sfa)
            cpasync.prefetch_descriptor(tma_atom_sfb)
            cpasync.prefetch_descriptor(tma_atom_c)

        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2

        #
        # Setup cta/thread coordinates
        #
        # Coords inside cluster
        bidx, bidy, bidz = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        block_in_cluster_coord_sfb_vmnk = cluster_layout_sfb_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        # Coord inside cta
        tidx, _, _ = cute.arch.thread_idx()

        #
        # Alloc and init: a+b full/empty, accumulator full/empty, tensor memory dealloc barrier
        #
        smem = utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # Initialize mainloop ab_pipeline (barrier) and states
        ab_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        ab_pipeline_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        ab_pipeline = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_pipeline_producer_group,
            consumer_group=ab_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
            cta_layout_vmnk=cluster_layout_vmnk,
            enable_multicast_signaling=True,
            defer_sync=True,
        )

        # Initialize acc_pipeline (barrier) and states
        acc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_acc_consumer_threads = (
            self.threads_per_warp
            * len(self.epilogue_warp_id)
            * (2 if use_2cta_instrs else 1)
        )
        acc_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_acc_consumer_threads
        )
        acc_pipeline = pipeline.PipelineUmmaAsync.create(
            barrier_storage=storage.acc_full_mbar_ptr.data_ptr(),
            num_stages=self.num_acc_stage,
            producer_group=acc_pipeline_producer_group,
            consumer_group=acc_pipeline_consumer_group,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )

        # Tensor memory dealloc barrier init
        tmem = utils.TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=self.tmem_alloc_barrier,
            allocator_warp_id=self.epilogue_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar.ptr,
        )

        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=self.cluster_shape_mn, is_relaxed=True)

        #
        # Setup smem tensor A/B/SFA/SFB/C
        #
        # (EPI_TILE_M, EPI_TILE_N, STAGE)
        sC = storage.sC.get_tensor(
            c_smem_layout_staged.outer, swizzle=c_smem_layout_staged.inner
        )
        # (MMA, MMA_M, MMA_K, STAGE)
        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        # (MMA, MMA_N, MMA_K, STAGE)
        sB = storage.sB.get_tensor(
            b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
        )
        # (MMA, MMA_M, MMA_K, STAGE)
        sSFA = storage.sSFA.get_tensor(sfa_smem_layout_staged)
        # (MMA, MMA_N, MMA_K, STAGE)
        sSFB = storage.sSFB.get_tensor(sfb_smem_layout_staged)

        #
        # Compute multicast mask for A/B/SFA/SFB buffer full
        #
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        sfa_full_mcast_mask = None
        sfb_full_mcast_mask = None
        if cutlass.const_expr(self.is_a_mcast or self.is_b_mcast or use_2cta_instrs):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )
            sfa_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            sfb_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_sfb_vmnk, block_in_cluster_coord_sfb_vmnk, mcast_mode=1
            )

        #
        # Local_tile partition global tensors
        #
        # (bM, bK, RestM, RestK, RestL)
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
        )
        # (bN, bK, RestN, RestK, RestL)
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(self.mma_tiler, (0, None, None)), (None, None, None)
        )
        # (bM, bK, RestM, RestK, RestL)
        gSFA_mkl = cute.local_tile(
            mSFA_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
        )
        # (bN, bK, RestN, RestK, RestL)
        gSFB_nkl = cute.local_tile(
            mSFB_nkl,
            cute.slice_(self.mma_tiler_sfb, (0, None, None)),
            (None, None, None),
        )
        # (bM, bN, RestM, RestN, RestL)
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )
        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        #
        # Partition global tensor for TiledMMA_A/B/C
        #
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        thr_mma_sfb = tiled_mma_sfb.get_slice(mma_tile_coord_v)
        # (MMA, MMA_M, MMA_K, RestM, RestK, RestL)
        tCgA = thr_mma.partition_A(gA_mkl)
        # (MMA, MMA_N, MMA_K, RestN, RestK, RestL)
        tCgB = thr_mma.partition_B(gB_nkl)
        # (MMA, MMA_M, MMA_K, RestM, RestK, RestL)
        tCgSFA = thr_mma.partition_A(gSFA_mkl)
        # (MMA, MMA_N, MMA_K, RestN, RestK, RestL)
        tCgSFB = thr_mma_sfb.partition_B(gSFB_nkl)
        # (MMA, MMA_M, MMA_N, RestM, RestN, RestL)
        tCgC = thr_mma.partition_C(gC_mnl)

        #
        # Partition global/shared tensor for TMA load A/B
        #
        # TMA load A partition_S/D
        a_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), RestM, RestK, RestL)
        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sA, 0, 3),
            cute.group_modes(tCgA, 0, 3),
        )
        # TMA load B partition_S/D
        b_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), RestN, RestK, RestL)
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB, 0, 3),
            cute.group_modes(tCgB, 0, 3),
        )

        #  TMA load scaled factor A partition_S/D
        sfa_cta_layout = a_cta_layout
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), RestM, RestK, RestL)
        tAsSFA, tAgSFA = cute.nvgpu.cpasync.tma_partition(
            tma_atom_sfa,
            block_in_cluster_coord_vmnk[2],
            sfa_cta_layout,
            cute.group_modes(sSFA, 0, 3),
            cute.group_modes(tCgSFA, 0, 3),
        )
        tAsSFA = cute.filter_zeros(tAsSFA)
        tAgSFA = cute.filter_zeros(tAgSFA)

        # TMA load scaled factor B partition_S/D
        sfb_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_sfb_vmnk, (0, None, 0, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), RestN, RestK, RestL)
        tBsSFB, tBgSFB = cute.nvgpu.cpasync.tma_partition(
            tma_atom_sfb,
            block_in_cluster_coord_sfb_vmnk[1],
            sfb_cta_layout,
            cute.group_modes(sSFB, 0, 3),
            cute.group_modes(tCgSFB, 0, 3),
        )
        tBsSFB = cute.filter_zeros(tBsSFB)
        tBgSFB = cute.filter_zeros(tBgSFB)

        #
        # Partition shared/tensor memory tensor for TiledMMA_A/B/C
        #
        # (MMA, MMA_M, MMA_K, STAGE)
        tCrA = tiled_mma.make_fragment_A(sA)
        # (MMA, MMA_N, MMA_K, STAGE)
        tCrB = tiled_mma.make_fragment_B(sB)
        # (MMA, MMA_M, MMA_N)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        if cutlass.const_expr(self.overlapping_accum):
            num_acc_stage_overlapped = 2
            tCtAcc_fake = tiled_mma.make_fragment_C(
                cute.append(acc_shape, num_acc_stage_overlapped)
            )
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_fake = cute.make_tensor(
                tCtAcc_fake.iterator,
                cute.make_layout(
                    tCtAcc_fake.shape,
                    stride=(
                        tCtAcc_fake.stride[0],
                        tCtAcc_fake.stride[1],
                        tCtAcc_fake.stride[2],
                        (256 - self.num_sf_tmem_cols) * tCtAcc_fake.stride[0][1],
                    ),
                ),
            )
        else:
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_fake = tiled_mma.make_fragment_C(
                cute.append(acc_shape, self.num_acc_stage)
            )

        #
        # Cluster wait before tensor memory alloc
        #
        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        #
        # Construct the scheduler (shared across all warp specializations)
        #
        tile_sched = utils.StaticPersistentTileScheduler.create(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()

        #
        # Specialized TMA load warp
        #
        if warp_idx == self.tma_warp_id:
            ab_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_ab_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                #
                # Slice to per mma tile index
                #
                # ((atom_v, rest_v), RestK)
                tAgA_slice = tAgA[
                    (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                ]
                # ((atom_v, rest_v), RestK)
                tBgB_slice = tBgB[
                    (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                ]

                # ((atom_v, rest_v), RestK)
                tAgSFA_slice = tAgSFA[
                    (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                ]

                # Apply SFB slicing hack when cta_tile_shape_n=64
                slice_n = mma_tile_coord_mnl[1]
                if cutlass.const_expr(self.cta_tile_shape_mnk[1] == 64):
                    slice_n = mma_tile_coord_mnl[1] // 2
                # ((atom_v, rest_v), RestK)
                tBgSFB_slice = tBgSFB[(None, slice_n, None, mma_tile_coord_mnl[2])]

                # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt
                ab_producer_state.reset_count()
                peek_ab_empty_status = cutlass.Boolean(1)
                if ab_producer_state.count < k_tile_cnt:
                    peek_ab_empty_status = ab_pipeline.producer_try_acquire(
                        ab_producer_state
                    )
                #
                # Tma load loop
                #
                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    # Conditionally wait for AB buffer empty
                    ab_pipeline.producer_acquire(
                        ab_producer_state, peek_ab_empty_status
                    )

                    # TMA load A/B/SFA/SFB
                    cute.copy(
                        tma_atom_a,
                        tAgA_slice[(None, ab_producer_state.count)],
                        tAsA[(None, ab_producer_state.index)],
                        tma_bar_ptr=ab_pipeline.producer_get_barrier(ab_producer_state),
                        mcast_mask=a_full_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_slice[(None, ab_producer_state.count)],
                        tBsB[(None, ab_producer_state.index)],
                        tma_bar_ptr=ab_pipeline.producer_get_barrier(ab_producer_state),
                        mcast_mask=b_full_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_sfa,
                        tAgSFA_slice[(None, ab_producer_state.count)],
                        tAsSFA[(None, ab_producer_state.index)],
                        tma_bar_ptr=ab_pipeline.producer_get_barrier(ab_producer_state),
                        mcast_mask=sfa_full_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_sfb,
                        tBgSFB_slice[(None, ab_producer_state.count)],
                        tBsSFB[(None, ab_producer_state.index)],
                        tma_bar_ptr=ab_pipeline.producer_get_barrier(ab_producer_state),
                        mcast_mask=sfb_full_mcast_mask,
                    )

                    # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt + k_tile + 1
                    ab_producer_state.advance()
                    peek_ab_empty_status = cutlass.Boolean(1)
                    if ab_producer_state.count < k_tile_cnt:
                        peek_ab_empty_status = ab_pipeline.producer_try_acquire(
                            ab_producer_state
                        )

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Wait A/B buffer empty
            #
            ab_pipeline.producer_tail(ab_producer_state)

        #
        # Specialized MMA warp
        #
        if warp_idx == self.mma_warp_id:
            #
            # Bar sync for retrieve tensor memory ptr from shared mem
            #
            tmem.wait_for_alloc()

            #
            # Retrieving tensor memory ptr and make accumulator/SFA/SFB tensor
            #
            acc_tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # Make accumulator tmem tensor
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(acc_tmem_ptr, tCtAcc_fake.layout)

            # Make SFA tmem tensor
            sfa_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr + self.num_accumulator_tmem_cols,
                dtype=self.sf_dtype,
            )
            # (MMA, MMA_M, MMA_K)
            tCtSFA_layout = blockscaled_utils.make_tmem_layout_sfa(
                tiled_mma,
                self.mma_tiler,
                self.sf_vec_size,
                cute.slice_(sfa_smem_layout_staged, (None, None, None, 0)),
            )
            tCtSFA = cute.make_tensor(sfa_tmem_ptr, tCtSFA_layout)

            # Make SFB tmem tensor
            sfb_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr + self.num_accumulator_tmem_cols + self.num_sfa_tmem_cols,
                dtype=self.sf_dtype,
            )
            # (MMA, MMA_N, MMA_K)
            tCtSFB_layout = blockscaled_utils.make_tmem_layout_sfb(
                tiled_mma,
                self.mma_tiler,
                self.sf_vec_size,
                cute.slice_(sfb_smem_layout_staged, (None, None, None, 0)),
            )
            tCtSFB = cute.make_tensor(sfb_tmem_ptr, tCtSFB_layout)
            #
            # Partition for S2T copy of SFA/SFB
            #
            (
                tiled_copy_s2t_sfa,
                tCsSFA_compact_s2t,
                tCtSFA_compact_s2t,
            ) = self.mainloop_s2t_copy_and_partition(sSFA, tCtSFA)
            (
                tiled_copy_s2t_sfb,
                tCsSFB_compact_s2t,
                tCtSFB_compact_s2t,
            ) = self.mainloop_s2t_copy_and_partition(sSFB, tCtSFB)

            ab_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_ab_stage
            )
            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                # Get accumulator stage index
                if cutlass.const_expr(self.overlapping_accum):
                    acc_stage_index = acc_producer_state.phase ^ 1
                else:
                    acc_stage_index = acc_producer_state.index

                # Set tensor memory buffer for current tile
                # (MMA, MMA_M, MMA_N)
                tCtAcc = tCtAcc_base[(None, None, None, acc_stage_index)]

                # Peek (try_wait) AB buffer full for k_tile = 0
                ab_consumer_state.reset_count()
                peek_ab_full_status = cutlass.Boolean(1)
                if ab_consumer_state.count < k_tile_cnt and is_leader_cta:
                    peek_ab_full_status = ab_pipeline.consumer_try_wait(
                        ab_consumer_state
                    )

                #
                # Wait for accumulator buffer empty
                #
                if is_leader_cta:
                    acc_pipeline.producer_acquire(acc_producer_state)

                # Apply TMEM pointer offset hack when cta_tile_shape_n=192 or cta_tile_shape_n=64
                tCtSFB_mma = tCtSFB
                if cutlass.const_expr(self.cta_tile_shape_mnk[1] in {64, 192}):
                    # If this is an ODD tile, shift the TMEM start address for cta_tile_shape_n=192 case by two words (ignores first 64 columns of SFB)
                    offset = cutlass.Int32((mma_tile_coord_mnl[1] % 2) * 2)
                    shifted_ptr = cute.recast_ptr(
                        acc_tmem_ptr
                        + self.num_accumulator_tmem_cols
                        + self.num_sfa_tmem_cols
                        + offset,
                        dtype=self.sf_dtype,
                    )
                    tCtSFB_mma = cute.make_tensor(shifted_ptr, tCtSFB_layout)

                #
                # Reset the ACCUMULATE field for each tile
                #
                tiled_mma.set(tcgen05.Field.ACCUMULATE, False)

                #
                # Mma mainloop
                #
                for k_tile in range(k_tile_cnt):
                    if is_leader_cta:
                        # Conditionally wait for AB buffer full
                        ab_pipeline.consumer_wait(
                            ab_consumer_state, peek_ab_full_status
                        )

                        #  Copy SFA/SFB from smem to tmem
                        s2t_stage_coord = (
                            None,
                            None,
                            None,
                            None,
                            ab_consumer_state.index,
                        )
                        tCsSFA_compact_s2t_staged = tCsSFA_compact_s2t[s2t_stage_coord]
                        tCsSFB_compact_s2t_staged = tCsSFB_compact_s2t[s2t_stage_coord]
                        cute.copy(
                            tiled_copy_s2t_sfa,
                            tCsSFA_compact_s2t_staged,
                            tCtSFA_compact_s2t,
                        )
                        cute.copy(
                            tiled_copy_s2t_sfb,
                            tCsSFB_compact_s2t_staged,
                            tCtSFB_compact_s2t,
                        )

                        # tCtAcc += tCrA * tCrSFA * tCrB * tCrSFB
                        tiled_mma.set(tcgen05.Field.ACCUMULATE, k_tile != 0)
                        tile_crd = (None, None, None, ab_consumer_state.index)
                        cute.gemm(
                            tiled_mma,
                            tCtAcc,
                            [tCrA[tile_crd], tCtSFA],
                            [tCrB[tile_crd], tCtSFB_mma],
                            tCtAcc,
                        )

                        # Async arrive AB buffer empty
                        ab_pipeline.consumer_release(ab_consumer_state)

                    # Peek (try_wait) AB buffer full for k_tile = k_tile + 1
                    ab_consumer_state.advance()
                    peek_ab_full_status = cutlass.Boolean(1)
                    if ab_consumer_state.count < k_tile_cnt:
                        if is_leader_cta:
                            peek_ab_full_status = ab_pipeline.consumer_try_wait(
                                ab_consumer_state
                            )

                #
                # Async arrive accumulator buffer full
                #
                if is_leader_cta:
                    acc_pipeline.producer_commit(acc_producer_state)
                acc_producer_state.advance()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Wait for accumulator buffer empty
            #
            acc_pipeline.producer_tail(acc_producer_state)
        #
        # Specialized epilogue warps
        #
        if warp_idx < self.mma_warp_id:
            #
            # Alloc tensor memory buffer
            #
            tmem.allocate(self.num_tmem_alloc_cols)

            #
            # Bar sync for retrieve tensor memory ptr from shared memory
            #
            tmem.wait_for_alloc()

            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            acc_tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(acc_tmem_ptr, tCtAcc_fake.layout)

            # Number of CTA tiles along M — for per-tile flag linearization
            m_cta_tiles_in_total = gC_mnl.shape[2] * cute.size(tiled_mma.thr_id.shape)

            #
            # Partition for epilogue
            #
            epi_tidx = tidx
            (
                tiled_copy_t2r,
                tTR_tAcc_base,
                tTR_rAcc,
            ) = self.epilogue_tmem_copy_and_partition(
                epi_tidx, tCtAcc_base, tCgC, epi_tile, use_2cta_instrs
            )

            tTR_rC = cute.make_rmem_tensor(tTR_rAcc.shape, self.c_dtype)
            tiled_copy_r2s, tRS_rC, tRS_sC = self.epilogue_smem_copy_and_partition(
                tiled_copy_t2r, tTR_rC, epi_tidx, sC
            )
            (
                tma_atom_c,
                bSG_sC,
                bSG_gC_partitioned,
            ) = self.epilogue_gmem_copy_and_partition(
                epi_tidx, tma_atom_c, tCgC, epi_tile, sC
            )

            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )

            # Threads/warps participating in tma store pipeline
            c_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                self.threads_per_warp * len(self.epilogue_warp_id),
            )
            c_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.num_c_stage,
                producer_group=c_producer_group,
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                #
                # Slice to per mma tile index
                #
                # ((ATOM_V, REST_V), EPI_M, EPI_N)
                bSG_gC = bSG_gC_partitioned[
                    (
                        None,
                        None,
                        None,
                        *mma_tile_coord_mnl,
                    )
                ]

                # Get accumulator stage index
                if cutlass.const_expr(self.overlapping_accum):
                    acc_stage_index = acc_consumer_state.phase
                    reverse_subtile = True if acc_stage_index == 0 else False
                else:
                    acc_stage_index = acc_consumer_state.index

                # Set tensor memory buffer for current tile
                # (T2R, T2R_M, T2R_N, EPI_M, EPI_M)
                tTR_tAcc = tTR_tAcc_base[
                    (None, None, None, None, None, acc_stage_index)
                ]

                #
                # Wait for accumulator buffer full
                #
                acc_pipeline.consumer_wait(acc_consumer_state)

                tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
                bSG_gC = cute.group_modes(bSG_gC, 1, cute.rank(bSG_gC))

                #
                # Store accumulator to global memory in subtiles
                #
                subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])
                num_prev_subtiles = tile_sched.num_tiles_executed * subtile_cnt
                for subtile_idx in cutlass.range(subtile_cnt):
                    real_subtile_idx = subtile_idx
                    if cutlass.const_expr(self.overlapping_accum):
                        if reverse_subtile:
                            # Subtile always iterates on N dimension as we only have 4x1DP tmem load pattern for cta_tile_m = 128 cases.
                            real_subtile_idx = (
                                self.cta_tile_shape_mnk[1] // self.epi_tile_n
                                - 1
                                - subtile_idx
                            )
                    #
                    # Load accumulator from tensor memory buffer to register
                    #
                    tTR_tAcc_mn = tTR_tAcc[(None, None, None, real_subtile_idx)]
                    cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)

                    #
                    # Async arrive accumulator buffer empty ealier when overlapping_accum is enabled
                    #
                    if cutlass.const_expr(self.overlapping_accum):
                        if subtile_idx == self.iter_acc_early_release_in_epilogue:
                            # Fence for TMEM load
                            cute.arch.fence_view_async_tmem_load()
                            acc_pipeline.consumer_release(acc_consumer_state)
                            acc_consumer_state.advance()

                    #
                    # Convert to C type
                    #
                    acc_vec = tiled_copy_r2s.retile(tTR_rAcc).load()
                    acc_vec = epilogue_op(acc_vec.to(self.c_dtype))
                    tRS_rC.store(acc_vec)

                    #
                    # Store C to shared memory
                    #
                    c_buffer = (num_prev_subtiles + subtile_idx) % self.num_c_stage
                    cute.copy(
                        tiled_copy_r2s,
                        tRS_rC,
                        tRS_sC[(None, None, None, c_buffer)],
                    )
                    # Fence and barrier to make sure shared memory store is visible to TMA store
                    cute.arch.fence_proxy(
                        "async.shared",
                        space="cta",
                    )
                    self.epilogue_sync_barrier.arrive_and_wait()

                    #
                    # TMA store C to global memory
                    #
                    if warp_idx == self.epilogue_warp_id[0]:
                        cute.copy(
                            tma_atom_c,
                            bSG_sC[(None, c_buffer)],
                            bSG_gC[(None, real_subtile_idx)],
                        )
                        # Fence and barrier to make sure shared memory store is visible to TMA store
                        c_pipeline.producer_commit()
                        c_pipeline.producer_acquire()
                    self.epilogue_sync_barrier.arrive_and_wait()

                # AllReduce: per-tile — drain TMA then signal flag
                # (c_pipeline.producer_tail drains ALL pending TMA stores up to this point)
                c_pipeline.producer_tail()
                cta_tile_id_linear = cute.Int32(
                    cur_tile_coord[0] + cur_tile_coord[1] * m_cta_tiles_in_total
                )
                if warp_idx == self.epilogue_warp_id[0]:
                    with cute.arch.elect_one():
                        utils.distributed.multimem_red_add1(
                            lock_ptr=barrier_flag_multicast.iterator
                            + cta_tile_id_linear,
                            order="release",
                            scope="gpu",
                        )

                #
                # Async arrive accumulator buffer empty
                #
                if cutlass.const_expr(not self.overlapping_accum):
                    acc_pipeline.consumer_release(acc_consumer_state)
                    acc_consumer_state.advance()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Dealloc the tensor memory buffer
            #
            tmem.relinquish_alloc_permit()
            self.epilogue_sync_barrier.arrive_and_wait()
            tmem.free(acc_tmem_ptr)
            # Note: producer_tail() is now called per-tile in the AR path

        # ///////////////////////////////////////////////////////////////////////////////
        #  AllReduce warps
        # ///////////////////////////////////////////////////////////////////////////////
        if cutlass.const_expr(self.all_reduce == "LDMCxSTMC"):
            if warp_idx >= self.comm_warp_id[0]:
                # (bM, bN, RestM, RestN, RestL) with multicast memory as comm input
                gCommInMC_mnl = cute.local_tile(
                    mCommInMC_mnl,
                    cute.slice_(self.mma_tiler, (None, None, 0)),
                    (None, None, None),
                )
                # (bM, bN, RestM, RestN, RestL) with multicast memory as comm output
                gCommOutMC_mnl = cute.local_tile(
                    mCommOutMC_mnl,
                    cute.slice_(self.mma_tiler, (None, None, 0)),
                    (None, None, None),
                )
                # (MMA, MMA_M, MMA_N, RestM, RestN, RestL) with multicast memory
                tCgCommInMC = thr_mma.partition_C(gCommInMC_mnl)
                tCgCommOutMC = thr_mma.partition_C(gCommOutMC_mnl)

                m_cta_tiles_in_total = gC_mnl.shape[2] * cute.size(
                    tiled_mma.thr_id.shape
                )
                n_cta_tiles_in_total = gC_mnl.shape[3]

                #
                # Persistent tile scheduling loop for all reduce
                #
                comm_sync_barrier = pipeline.NamedBarrier(
                    barrier_id=self.comm_sync_bar_id,
                    num_threads=32 * len(self.comm_warp_id),
                )

                while work_tile.is_valid_tile:
                    cur_tile_coord = work_tile.tile_idx

                    # (1) Per-tile flag wait.
                    cta_tile_id_linear = (
                        cur_tile_coord[0] + cur_tile_coord[1] * m_cta_tiles_in_total
                    )
                    if warp_idx == self.comm_warp_id[0]:
                        with cute.arch.elect_one():
                            utils.distributed.spin_lock_atom_cas_acquire_wait(
                                lock_ptr=barrier_flag_unicast.iterator
                                + cta_tile_id_linear,
                                expected_val=self.num_ranks,
                                reset_val=0,
                                scope="gpu",
                            )

                    comm_sync_barrier.arrive_and_wait()

                    # (2) Per-tile data movement (multimem.ld_reduce + multimem.st).
                    LDMCxSTMC(
                        self,
                        cur_tile_coord=cur_tile_coord,
                        tiled_mma=tiled_mma,
                        comm_tidx=tidx,
                        tCgCommInMC=tCgCommInMC,
                        tCgCommOutMC=tCgCommOutMC,
                    )

                    #
                    # Advance to next tile
                    #
                    tile_sched.advance_to_next_work()
                    work_tile = tile_sched.get_current_work()

                # Ensure all threads in allreduce warp group have complete issuing all reduce operations.
                comm_sync_barrier.arrive_and_wait()

                #
                # Set Per SM Flag with Release
                #
                if warp_idx == self.comm_warp_id[0]:
                    with cute.arch.elect_one():
                        # Offset to last tile flag idx
                        total_num_cta_tile = m_cta_tiles_in_total * n_cta_tiles_in_total
                        # Linear id of current SM.
                        sm_id_linear = (
                            cute.arch.block_idx()[0]
                            + cute.arch.block_idx()[1] * cute.arch.grid_dim()[0]
                            + cute.arch.block_idx()[2]
                            * cute.arch.grid_dim()[0]
                            * cute.arch.grid_dim()[1]
                        )
                        # Release flag with sys scope
                        utils.distributed.multimem_red_add1(
                            lock_ptr=barrier_flag_multicast.iterator
                            + total_num_cta_tile
                            + sm_id_linear,
                            scope="sys",
                            order="release",
                        )
                        # Acquire spin-lock wait flag with sys scope
                        utils.distributed.spin_lock_atom_cas_acquire_wait(
                            lock_ptr=barrier_flag_unicast.iterator
                            + total_num_cta_tile
                            + sm_id_linear,
                            expected_val=self.num_ranks,
                            reset_val=0,
                            scope="sys",
                        )

    def mainloop_s2t_copy_and_partition(
        self,
        sSF: cute.Tensor,
        tSF: cute.Tensor,
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """Make tiledCopy for smem-to-tmem scale factor load; partition smem source and tmem destination."""
        # (MMA, MMA_MN, MMA_K, STAGE)
        tCsSF_compact = cute.filter_zeros(sSF)
        # (MMA, MMA_MN, MMA_K)
        tCtSF_compact = cute.filter_zeros(tSF)

        # Make S2T CopyAtom and tiledCopy
        copy_atom_s2t = cute.make_copy_atom(
            tcgen05.Cp4x32x128bOp(self.cta_group),
            self.sf_dtype,
        )
        tiled_copy_s2t = tcgen05.make_s2t_copy(copy_atom_s2t, tCtSF_compact)
        thr_copy_s2t = tiled_copy_s2t.get_slice(0)

        # ((ATOM_V, REST_V), Rest_Tiler, MMA_MN, MMA_K, STAGE)
        tCsSF_compact_s2t_ = thr_copy_s2t.partition_S(tCsSF_compact)
        # ((ATOM_V, REST_V), Rest_Tiler, MMA_MN, MMA_K, STAGE)
        tCsSF_compact_s2t = tcgen05.get_s2t_smem_desc_tensor(
            tiled_copy_s2t, tCsSF_compact_s2t_
        )
        # ((ATOM_V, REST_V), Rest_Tiler, MMA_MN, MMA_K)
        tCtSF_compact_s2t = thr_copy_s2t.partition_D(tCtSF_compact)

        return tiled_copy_s2t, tCsSF_compact_s2t, tCtSF_compact_s2t

    def epilogue_tmem_copy_and_partition(
        self,
        tidx: cutlass.Int32,
        tAcc: cute.Tensor,
        gC_mnl: cute.Tensor,
        epi_tile: cute.Tile,
        use_2cta_instrs: Union[cutlass.Boolean, bool],
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """Make tiledCopy for tmem-to-register load; partition tmem source and register destination."""
        # Make tiledCopy for tensor memory load
        copy_atom_t2r = utils.sm100.get_tmem_load_op(
            self.cta_tile_shape_mnk,
            self.c_layout,
            self.c_dtype,
            self.acc_dtype,
            epi_tile,
            use_2cta_instrs,
        )
        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, STAGE)
        tAcc_epi = cute.flat_divide(
            tAcc[((None, None), 0, 0, None)],
            epi_tile,
        )
        # (EPI_TILE_M, EPI_TILE_N)
        tiled_copy_t2r = tcgen05.make_tmem_copy(
            copy_atom_t2r, tAcc_epi[(None, None, 0, 0, 0)]
        )

        thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_M, STAGE)
        tTR_tAcc = thr_copy_t2r.partition_S(tAcc_epi)

        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, RestM, RestN, RestL)
        gC_mnl_epi = cute.flat_divide(
            gC_mnl[((None, None), 0, 0, None, None, None)], epi_tile
        )
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL)
        tTR_gC = thr_copy_t2r.partition_D(gC_mnl_epi)
        # (T2R, T2R_M, T2R_N)
        tTR_rAcc = cute.make_rmem_tensor(
            tTR_gC[(None, None, None, 0, 0, 0, 0, 0)].shape, self.acc_dtype
        )
        return tiled_copy_t2r, tTR_tAcc, tTR_rAcc

    def epilogue_smem_copy_and_partition(
        self,
        tiled_copy_t2r: cute.TiledCopy,
        tTR_rC: cute.Tensor,
        tidx: cutlass.Int32,
        sC: cute.Tensor,
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """Make tiledCopy for register-to-smem store; partition register source and smem destination."""
        copy_atom_r2s = utils.sm100.get_smem_store_op(
            self.c_layout, self.c_dtype, self.acc_dtype, tiled_copy_t2r
        )
        tiled_copy_r2s = cute.make_tiled_copy_D(copy_atom_r2s, tiled_copy_t2r)
        # (R2S, R2S_M, R2S_N, PIPE_D)
        thr_copy_r2s = tiled_copy_r2s.get_slice(tidx)
        tRS_sC = thr_copy_r2s.partition_D(sC)
        # (R2S, R2S_M, R2S_N)
        tRS_rC = tiled_copy_r2s.retile(tTR_rC)
        return tiled_copy_r2s, tRS_rC, tRS_sC

    def epilogue_gmem_copy_and_partition(
        self,
        tidx: cutlass.Int32,
        atom: Union[cute.CopyAtom, cute.TiledCopy],
        gC_mnl: cute.Tensor,
        epi_tile: cute.Tile,
        sC: cute.Tensor,
    ) -> Tuple[cute.CopyAtom, cute.Tensor, cute.Tensor]:
        """Make tiledCopy for TMA global memory store; partition smem source and gmem destination."""
        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, RestM, RestN, RestL)
        gC_epi = cute.flat_divide(
            gC_mnl[((None, None), 0, 0, None, None, None)], epi_tile
        )

        tma_atom_c = atom
        sC_for_tma_partition = cute.group_modes(sC, 0, 2)
        gC_for_tma_partition = cute.group_modes(gC_epi, 0, 2)
        # ((ATOM_V, REST_V), EPI_M, EPI_N)
        # ((ATOM_V, REST_V), EPI_M, EPI_N, RestM, RestN, RestL)
        bSG_sC, bSG_gC = cpasync.tma_partition(
            tma_atom_c,
            0,
            cute.make_layout(1),
            sC_for_tma_partition,
            gC_for_tma_partition,
        )
        return tma_atom_c, bSG_sC, bSG_gC

    @staticmethod
    def _compute_stages(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: Tuple[int, int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        epi_tile: cute.Tile,
        c_dtype: Type[cutlass.Numeric],
        c_layout: utils.LayoutEnum,
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        smem_capacity: int,
        occupancy: int,
    ) -> Tuple[int, int, int]:
        """Compute (num_acc_stage, num_ab_stage, num_c_stage) based on smem capacity heuristics."""
        # ACC stages
        num_acc_stage = 1 if mma_tiler_mnk[1] == 256 else 2

        # Default C stages
        num_c_stage = 2

        # Calculate smem layout and size for one stage of A, B, SFA, SFB and C
        a_smem_layout_stage_one = utils.sm100.make_smem_layout_a(
            tiled_mma,
            mma_tiler_mnk,
            a_dtype,
            1,  # a tmp 1 stage is provided
        )
        b_smem_layout_staged_one = utils.sm100.make_smem_layout_b(
            tiled_mma,
            mma_tiler_mnk,
            b_dtype,
            1,  # a tmp 1 stage is provided
        )
        sfa_smem_layout_staged_one = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma,
            mma_tiler_mnk,
            sf_vec_size,
            1,  # a tmp 1 stage is provided
        )
        sfb_smem_layout_staged_one = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma,
            mma_tiler_mnk,
            sf_vec_size,
            1,  # a tmp 1 stage is provided
        )

        c_smem_layout_staged_one = utils.sm100.make_smem_layout_epi(
            c_dtype,
            c_layout,
            epi_tile,
            1,
        )

        ab_bytes_per_stage = (
            cute.size_in_bytes(a_dtype, a_smem_layout_stage_one)
            + cute.size_in_bytes(b_dtype, b_smem_layout_staged_one)
            + cute.size_in_bytes(sf_dtype, sfa_smem_layout_staged_one)
            + cute.size_in_bytes(sf_dtype, sfb_smem_layout_staged_one)
        )
        mbar_helpers_bytes = 1024
        c_bytes_per_stage = cute.size_in_bytes(c_dtype, c_smem_layout_staged_one)
        c_bytes = c_bytes_per_stage * num_c_stage

        # Calculate A/B/SFA/SFB stages:
        # Start with total smem per CTA (capacity / occupancy)
        # Subtract reserved bytes and initial C stages bytes
        # Divide remaining by bytes needed per A/B/SFA/SFB stage
        num_ab_stage = (
            smem_capacity // occupancy - (mbar_helpers_bytes + c_bytes)
        ) // ab_bytes_per_stage

        # Refine epilogue stages:
        # Calculate remaining smem after allocating for A/B/SFA/SFB stages and reserved bytes
        # Add remaining unused smem to epilogue
        num_c_stage += (
            smem_capacity
            - occupancy * ab_bytes_per_stage * num_ab_stage
            - occupancy * (mbar_helpers_bytes + c_bytes)
        ) // (occupancy * c_bytes_per_stage)

        return num_acc_stage, num_ab_stage, num_c_stage

    @staticmethod
    def _compute_grid(
        c: cute.Tensor,
        cta_tile_shape_mnk: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
        swizzle_size: int,
        raster_order: Literal["m", "n"],
        max_active_clusters: cutlass.Constexpr,
    ) -> Tuple[utils.PersistentTileSchedulerParams, Tuple[int, int, int]]:
        """Compute (tile_sched_params, grid) using the persistent tile scheduler."""
        c_shape = cute.slice_(cta_tile_shape_mnk, (None, None, 0))
        gc = cute.zipped_divide(c, tiler=c_shape)
        num_ctas_mnl = gc[(0, (None, None, None))].shape
        cluster_shape_mnl = (*cluster_shape_mn, 1)

        tile_sched_params = utils.PersistentTileSchedulerParams(
            num_ctas_mnl, cluster_shape_mnl, swizzle_size, raster_order == "m"
        )
        grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )

        return tile_sched_params, grid

    @staticmethod
    def needs_unpack_tma(
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
    ) -> bool:
        """Return True if TMA must use UNPACK_U8 (U4_UNPACK_U8 / U6_UNPACK_U8).

        Required when operand widths differ (mxf8f6f4 mixed-precision) or either
        operand is 6-bit (no packed U6 TMA format exists).
        """
        if a_dtype.width != b_dtype.width:
            return True
        if a_dtype.width == 6 or b_dtype.width == 6:
            return True
        return False

    @staticmethod
    def is_valid_dtypes_and_scale_factor_vec_size(
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        c_dtype: Type[cutlass.Numeric],
    ) -> bool:
        """Return True if (a_dtype, b_dtype, sf_dtype, sf_vec_size, c_dtype) is a supported combination."""
        supported_ab_dtypes = {
            cutlass.Float4E2M1FN,
            cutlass.Float6E2M3FN,
            cutlass.Float6E3M2FN,
            cutlass.Float8E5M2,
            cutlass.Float8E4M3FN,
        }

        # Check A/B element types
        if a_dtype not in supported_ab_dtypes or b_dtype not in supported_ab_dtypes:
            return False

        # Check SF element type
        if sf_dtype not in {cutlass.Float8E8M0FNU, cutlass.Float8E4M3FN}:
            return False

        # sf_vec_size rules:
        #   * 16 is only supported for Float4E2M1FN x Float4E2M1FN (NVF4 / MXF4 fp4-pair)
        #   * 32 is required for every other A/B combination (MXF8, mxf8f6f4 mixed, MXF4-pair with MX scaling)
        # SF dtype pairing with sf_vec_size:
        #   * sf_vec_size == 16 requires sf_dtype in {Float8E4M3FN (NVF4), Float8E8M0FNU (MXF4)}
        #   * sf_vec_size == 32 requires sf_dtype == Float8E8M0FNU (MX scaling)
        both_fp4 = a_dtype is cutlass.Float4E2M1FN and b_dtype is cutlass.Float4E2M1FN
        if sf_vec_size == 16:
            if not both_fp4:
                return False
        elif sf_vec_size == 32:
            if sf_dtype is not cutlass.Float8E8M0FNU:
                return False
        else:
            return False

        # Check valid c_dtype
        if c_dtype not in {
            cutlass.Float32,
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E5M2,
            cutlass.Float8E4M3FN,
        }:
            return False

        return True

    @staticmethod
    def is_valid_layouts(
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: Literal["m", "k"],
        b_major: Literal["n", "k"],
        c_major: Literal["m", "n"],
    ) -> bool:
        """Return True if the layout/dtype combination is valid."""
        is_valid = True

        # FP4 operands can only be k-major (checked per operand)
        if a_dtype is cutlass.Float4E2M1FN and a_major != "k":
            is_valid = False
        if b_dtype is cutlass.Float4E2M1FN and b_major != "k":
            is_valid = False

        return is_valid

    @staticmethod
    def is_valid_mma_tiler_and_cluster_shape(
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
    ) -> bool:
        """Return True if mma_tiler_mn and cluster_shape_mn satisfy hardware constraints."""
        is_valid = True
        # Skip invalid mma tile shape
        if mma_tiler_mn[0] not in [128, 256]:
            is_valid = False
        if mma_tiler_mn[1] not in [64, 128, 192, 256]:
            is_valid = False
        # Skip illegal cluster shape
        if cluster_shape_mn[0] % (2 if mma_tiler_mn[0] == 256 else 1) != 0:
            is_valid = False
        # Skip invalid cluster shape
        is_power_of_2 = lambda x: x > 0 and (x & (x - 1)) == 0
        if (
            cluster_shape_mn[0] * cluster_shape_mn[1] > 16
            or cluster_shape_mn[0] <= 0
            or cluster_shape_mn[1] <= 0
            # Special cluster shape check for scale factor multicasts.
            # Due to limited size of scale factors, we can't multicast among more than 4 CTAs.
            or cluster_shape_mn[0] > 4
            or cluster_shape_mn[1] > 4
            or not is_power_of_2(cluster_shape_mn[0])
            or not is_power_of_2(cluster_shape_mn[1])
        ):
            is_valid = False
        return is_valid

    @staticmethod
    def is_valid_problem_shape_for_cluster_tile(
        m: int,
        n: int,
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
    ) -> bool:
        """Return True if (M, N) is evenly divisible by the cluster tile size.

        The LDMCxSTMC AR warp group has no boundary predicate (raw multimem.ld_reduce/
        multimem.st on every scheduler-assigned tile), so partial tiles are unsupported.
        """
        cta_tile_m = mma_tiler_mn[0] // (2 if mma_tiler_mn[0] == 256 else 1)
        cta_tile_n = mma_tiler_mn[1]
        cluster_tile_m = cta_tile_m * cluster_shape_mn[0]
        cluster_tile_n = cta_tile_n * cluster_shape_mn[1]
        return m % cluster_tile_m == 0 and n % cluster_tile_n == 0

    @staticmethod
    def is_valid_problem_shape_for_swizzle(
        m: int,
        n: int,
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        swizzle_size: int,
        raster_order: Literal["m", "n"],
    ) -> bool:
        """Return True if the cluster count divides evenly by swizzle_size along the
        swizzled axis (N for raster_order="m", M for raster_order="n").

        Same no-predicate reasoning as is_valid_problem_shape_for_cluster_tile.
        """
        cta_tile_m = mma_tiler_mn[0] // (2 if mma_tiler_mn[0] == 256 else 1)
        cta_tile_n = mma_tiler_mn[1]
        num_clusters_m = m // (cta_tile_m * cluster_shape_mn[0])
        num_clusters_n = n // (cta_tile_n * cluster_shape_mn[1])
        if raster_order == "m":
            return num_clusters_n % swizzle_size == 0
        else:
            return num_clusters_m % swizzle_size == 0

    @staticmethod
    def is_valid_tensor_alignment(
        m: int,
        n: int,
        k: int,
        l: int,
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: Literal["m", "k"],
        b_major: Literal["n", "k"],
        c_major: Literal["m", "n"],
        mma_tiler_mn: Tuple[int, int],
    ) -> bool:
        """Return True if tensor alignment satisfies TMA 16B contiguous-dim and UNPACK constraints."""
        is_valid = True

        def check_contigous_16B_alignment(dtype, is_mode0_major, tensor_shape):
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            # TMA requires the contiguous inner dimension to be a multiple of
            # 16 B (= 128 bits). Work in bits so non-byte-aligned widths
            # (e.g. 6-bit) are handled correctly: 16 * 8 // dtype.width is
            # wrong when dtype.width does not divide 128 (it returns 21 for
            # 6-bit instead of the real requirement K*6 % 128 == 0).
            return (num_major_elements * dtype.width) % (16 * 8) == 0

        def check_contigous_128_alignment(dtype, is_mode0_major, tensor_shape):
            # we only need to check alignment for subbyte dtype
            if dtype.width >= 8:
                return True
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            num_contiguous_elements = 128
            return num_major_elements % num_contiguous_elements == 0

        if (
            not check_contigous_16B_alignment(a_dtype, a_major == "m", (m, k, l))
            or not check_contigous_16B_alignment(b_dtype, b_major == "n", (n, k, l))
            or not check_contigous_16B_alignment(c_dtype, c_major == "m", (m, n, l))
        ):
            is_valid = False
        # When an operand is loaded via the UNPACK TMA variant
        # (U4_UNPACK_U8 or U6_UNPACK_U8), its inner tensor dimension in bytes
        # must be a multiple of 64B (4-bit) or 96B (6-bit); both work out to
        # a multiple of 128 elements along the contiguous dim. The check only
        # applies to sub-byte operands and only when the pair triggers UNPACK.
        if Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel.needs_unpack_tma(
            a_dtype, b_dtype
        ) and (
            not check_contigous_128_alignment(a_dtype, a_major == "m", (m, k, l))
            or not check_contigous_128_alignment(b_dtype, b_major == "n", (n, k, l))
        ):
            is_valid = False
        # Additional UNPACK constraint for any sub-byte operand on its contig
        # axis: when a sub-byte A is m-major (contig=M) or a sub-byte B is
        # n-major (contig=N), the MMA tile's contig dim (after 2CTA M-split,
        # which splits M for both A and B on the non-multicast atom path)
        # must be a multiple of 128 elements to satisfy the 64B (fp4) /
        # 96B (fp6) inner-dim requirement of U4_/U6_UNPACK_U8. Observed
        # failures: (128,192)/(1,1)/m-n-m (1CTA) and (256,128)/(2,2)/m-n-m
        # (2CTA) trigger CUDA illegal instruction for fp6 when mma_tiler_N
        # (or N/2 after 2CTA split) is not a 128-multiple; the same rule
        # applies to any other sub-byte operand on its non-K contig axis.
        use_2cta_instrs = mma_tiler_mn[0] == 256
        cta_div = 2 if use_2cta_instrs else 1
        if (
            Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel.needs_unpack_tma(
                a_dtype, b_dtype
            )
            and a_major == "m"
            and a_dtype.width < 8
            and (mma_tiler_mn[0] // cta_div) % 128 != 0
        ):
            is_valid = False
        if (
            Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel.needs_unpack_tma(
                a_dtype, b_dtype
            )
            and b_major == "n"
            and b_dtype.width < 8
            and (mma_tiler_mn[1] // cta_div) % 128 != 0
        ):
            is_valid = False
        return is_valid

    @staticmethod
    def can_implement(
        mnkl: Tuple[int, int, int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: Literal["m", "k"],
        b_major: Literal["n", "k"],
        c_major: Literal["m", "n"],
        sf_vec_size: int,
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        num_ranks: int = 8,
        swizzle_size: int = 1,
        raster_order: Literal["m", "n"] = "m",
    ) -> bool:
        """Return True if all dtype, layout, tiler, cluster-shape, alignment, and AR-warp checks pass."""
        # Unpack parameters
        m, n, k, l = mnkl
        can_implement = True
        # Skip unsupported types
        if not Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel.is_valid_dtypes_and_scale_factor_vec_size(
            a_dtype, b_dtype, sf_dtype, sf_vec_size, c_dtype
        ):
            can_implement = False
        # Skip unsupported layouts
        if not Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel.is_valid_layouts(
            a_dtype, b_dtype, c_dtype, a_major, b_major, c_major
        ):
            can_implement = False
        # Skip invalid mma tile shape and cluster shape
        if not Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel.is_valid_mma_tiler_and_cluster_shape(
            mma_tiler_mn, cluster_shape_mn
        ):
            can_implement = False
        # Skip if problem shape is not evenly divisible by the cluster tile — the AR
        # (LDMCxSTMC) warp group has no boundary predicate, so partial tiles are unsupported.
        if not Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel.is_valid_problem_shape_for_cluster_tile(
            m, n, mma_tiler_mn, cluster_shape_mn
        ):
            can_implement = False
        # Skip if swizzle doesn't evenly divide the cluster count, same no-predicate reason.
        if not Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel.is_valid_problem_shape_for_swizzle(
            m, n, mma_tiler_mn, cluster_shape_mn, swizzle_size, raster_order
        ):
            can_implement = False
        # Skip illegal problem shape for load/store alignment
        if not Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel.is_valid_tensor_alignment(
            m,
            n,
            k,
            l,
            a_dtype,
            b_dtype,
            c_dtype,
            a_major,
            b_major,
            c_major,
            mma_tiler_mn,
        ):
            can_implement = False

        # AR: verify comm warp count is achievable
        class _Tmp:
            pass

        tmp = _Tmp()
        tmp.mma_tiler_mn = mma_tiler_mn
        tmp.use_2cta_instrs = mma_tiler_mn[0] == 256
        tmp.num_ranks = num_ranks
        try:
            Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel._pick_num_comm_warp_for_128b(
                tmp, c_dtype
            )
        except (ValueError, AssertionError) as e:
            raise testing.CantImplementError(str(e))
        return can_implement


# Helper function to convert scale factor tensor from MKL layout to (32, 4, restM, 4, restK, l) format
@cute.jit
def cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
    sf_ref_ptr: cute.Pointer,
    sf_mma_ptr: cute.Pointer,
    mn: int,
    sf_k: int,
    l: int,
    mma_shape: tuple,
):
    mma_permute_order = (3, 4, 1, 5, 2, 0)
    permuted_shape = tuple(mma_shape[i] for i in mma_permute_order)
    cute_layout = cute.make_ordered_layout(permuted_shape, order=(2, 1, 4, 0, 3, 5))

    sf_ref_tensor = cute.make_tensor(
        sf_ref_ptr, cute.make_layout((mn, sf_k, l), stride=(sf_k, 1, mn * sf_k))
    )
    sf_mma_tensor = cute.make_tensor(sf_mma_ptr, cute_layout)

    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 0, 3)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 1, 3)
    for i in cutlass.range(cute.size(sf_ref_tensor)):
        mkl_coord = sf_ref_tensor.layout.get_hier_coord(i)
        sf_mma_tensor[mkl_coord] = sf_ref_tensor[mkl_coord]
    pass


# Helper function for ceil division
def ceil_div(a, b):
    return (a + b - 1) // b


# Convert scale factor tensors from (m, k, l) to (32, 4, restM, 4, restK, l) format
def create_and_reorder_scale_factor_tensor(
    l, mn, k, sf_vec_size, sf_dtype, torch_tensor
):
    """
    Create the CUTE-format scale factor tensor on CUDA based on the reference tensor.
    """
    sf_k = ceil_div(k, sf_vec_size)
    atom_m = (32, 4)
    atom_k = 4
    mma_shape = (
        l,  # batch size
        ceil_div(mn, atom_m[0] * atom_m[1]),
        ceil_div(sf_k, atom_k),
        atom_m[0],
        atom_m[1],
        atom_k,
    )

    # Generate a random int8 tensor, then convert to float8_e4m3fn
    cute_tensor = torch.ones(mma_shape, dtype=cutlass_torch.dtype(sf_dtype)).permute(
        3, 4, 1, 5, 2, 0
    )

    # Call the helper function to do layout conversion
    cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
        make_ptr(
            sf_dtype,
            torch_tensor.data_ptr(),
            cute.AddressSpace.gmem,
            assumed_align=32,
        ),
        make_ptr(
            sf_dtype,
            cute_tensor.data_ptr(),
            cute.AddressSpace.gmem,
            assumed_align=32,
        ),
        mn,
        sf_k,
        l,
        mma_shape,
    )
    return cute_tensor.cuda()


# Compile the persistent dense blockscaled GEMM operation
def scaled_mm(
    gemm_obj: Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel,
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
    max_active_clusters: cutlass.Constexpr,
    stream: cuda.CUstream,
    epilogue_op: cutlass.Constexpr = lambda x: x,
    options: str = "",
):
    # Construct CuTe Pointers
    a_ptr = make_ptr(a_dtype, 0, cute.AddressSpace.gmem, assumed_align=16)
    b_ptr = make_ptr(b_dtype, 0, cute.AddressSpace.gmem, assumed_align=16)
    c_ptr = make_ptr(c_dtype, 0, cute.AddressSpace.gmem, assumed_align=16)
    sfa_ptr = make_ptr(sf_dtype, 0, cute.AddressSpace.gmem, assumed_align=32)
    sfb_ptr = make_ptr(sf_dtype, 0, cute.AddressSpace.gmem, assumed_align=32)

    a_major_mode = OperandMajorMode.K if a_major == "k" else OperandMajorMode.MN
    b_major_mode = OperandMajorMode.K if b_major == "k" else OperandMajorMode.MN
    c_layout = (
        utils.LayoutEnum.ROW_MAJOR if c_major == "n" else utils.LayoutEnum.COL_MAJOR
    )
    return cute.compile(
        gemm_obj,
        a_ptr,
        b_ptr,
        sfa_ptr,
        sfb_ptr,
        c_ptr,
        (a_major_mode, b_major_mode, c_layout),
        (cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0)),
        max_active_clusters,
        stream,
        epilogue_op,
        options=options,
    )


def scaled_mm_ar(
    gemm_obj: Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel,
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
    max_active_clusters: cutlass.Constexpr,
    stream: cuda.CUstream,
    comm_in_multicast_tensor: cute.Tensor,
    comm_out_multicast_tensor: cute.Tensor,
    barrier_flag_unicast: cute.Tensor,
    barrier_flag_multicast: cute.Tensor,
    epilogue_op: cutlass.Constexpr = lambda x: x,
    options: str = "",
):
    # Comm tensors (dynamic layout cute.Tensor) passed directly — cannot use make_ptr for these.
    a_ptr = make_ptr(a_dtype, 0, cute.AddressSpace.gmem, assumed_align=16)
    b_ptr = make_ptr(b_dtype, 0, cute.AddressSpace.gmem, assumed_align=16)
    c_ptr = make_ptr(c_dtype, 0, cute.AddressSpace.gmem, assumed_align=16)
    sfa_ptr = make_ptr(sf_dtype, 0, cute.AddressSpace.gmem, assumed_align=32)
    sfb_ptr = make_ptr(sf_dtype, 0, cute.AddressSpace.gmem, assumed_align=32)

    a_major_mode = OperandMajorMode.K if a_major == "k" else OperandMajorMode.MN
    b_major_mode = OperandMajorMode.K if b_major == "k" else OperandMajorMode.MN
    c_layout = (
        utils.LayoutEnum.ROW_MAJOR if c_major == "n" else utils.LayoutEnum.COL_MAJOR
    )
    return cute.compile(
        gemm_obj,
        a_ptr,
        b_ptr,
        sfa_ptr,
        sfb_ptr,
        c_ptr,
        (a_major_mode, b_major_mode, c_layout),
        (cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0)),
        max_active_clusters,
        stream,
        epilogue_op,
        comm_in_multicast_tensor,
        comm_out_multicast_tensor,
        barrier_flag_unicast,
        barrier_flag_multicast,
        options=options,
    )


def is_emulated_dtype(
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
) -> bool:
    # torch natively represents A/B only when both operands share the same
    # dtype and the (dtype, sf_dtype) pair matches a supported non-emulated case.
    if a_dtype != b_dtype:
        return True
    if c_dtype in {
        cutlass.Float32,
        cutlass.Float16,
        cutlass.BFloat16,
    }:
        if a_dtype == cutlass.Float4E2M1FN and sf_dtype == cutlass.Float8E4M3FN:
            return False
        if a_dtype == cutlass.Float8E4M3FN and sf_dtype == cutlass.Float8E8M0FNU:
            return False

    return True


# Convert scale factor tensor from MKL layout to blocked layout
def to_blocked(input_matrix):
    rows, cols = input_matrix.shape
    # Please ensure rows and cols are multiples of 128 and 4 respectively
    n_row_blocks = ceil_div(rows, 128)
    n_col_blocks = ceil_div(cols, 4)
    padded_rows = n_row_blocks * 128
    padded_cols = n_col_blocks * 4

    # Pad the input matrix if necessary
    if padded_rows != rows or padded_cols != cols:
        # For FP8 types, convert to float32 for padding, then convert back
        original_dtype = input_matrix.dtype
        input_float32 = input_matrix.to(torch.float32)
        padded = torch.nn.functional.pad(
            input_float32,
            (0, padded_cols - cols, 0, padded_rows - rows),
            mode="constant",
            value=0,
        )
        # Convert back to original dtype if needed
        if original_dtype != input_float32.dtype:
            padded = padded.to(original_dtype)
    else:
        padded = input_matrix
    blocks = padded.view(n_row_blocks, 128, n_col_blocks, 4).permute(0, 2, 1, 3)
    rearranged = blocks.reshape(-1, 4, 32, 4).transpose(1, 2).reshape(-1, 32, 16)
    return rearranged.flatten()


# Reference implementation of the persistent dense blockscaled GEMM operation (emulated version)
def reference_scaled_mm_emulated(
    a: torch.Tensor,
    b: torch.Tensor,
    sfa: torch.Tensor,
    sfb: torch.Tensor,
    c: torch.Tensor,
    mnkl: Tuple[int, int, int, int],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
):
    m, n, k, l = mnkl
    sfa_expanded = (
        torch.repeat_interleave(sfa, sf_vec_size, dim=1)[:, :k, :]
        .to(dtype=torch.float32)
        .cuda()
    )
    sfb_expanded = (
        torch.repeat_interleave(sfb, sf_vec_size, dim=1)[:, :k, :]
        .to(dtype=torch.float32)
        .cuda()
    )
    res_a = torch.einsum("mkl,mkl->mkl", a, sfa_expanded)
    res_b = torch.einsum("nkl,nkl->nkl", b, sfb_expanded)
    # Cast res_a and res_b to float32 for einsum to avoid NotImplementedError on 'Byte'
    ref = torch.einsum("mkl,nkl->mnl", res_a, res_b)
    c_ref = ref.to(dtype=cutlass_torch.dtype(c_dtype))
    return c_ref


# Reference implementation of the persistent dense blockscaled GEMM operation (non-emulated version)
def reference_scaled_mm(
    a: torch.Tensor,
    b: torch.Tensor,
    sfa: torch.Tensor,
    sfb: torch.Tensor,
    c: torch.Tensor,
    mnkl: Tuple[int, int, int, int],
    c_dtype: Type[cutlass.Numeric],
):
    m, n, k, l = mnkl
    c_ref = torch.clone(c)
    for l_idx in range(l):
        # Convert the scale factor tensor to blocked format
        scale_a = to_blocked(sfa[:, :, l_idx])
        scale_b = to_blocked(sfb[:, :, l_idx])
        # Ensure a_slice is row-major (M, K) with stride (K, 1)
        a_slice = a[:, :, l_idx].contiguous()
        # Ensure b_slice is row-major (N, K) so that transpose gives column-major (K, N)
        b_slice = b[:, :, l_idx].contiguous()
        # (m, k) @ (n, k).T -> (m, n)
        res = torch._scaled_mm(
            a_slice,
            b_slice.transpose(0, 1),
            scale_a.cuda(),
            scale_b.cuda(),
            bias=None,
            out_dtype=c_ref.dtype,
        )
        c_ref[:, :, l_idx] = res
    return c_ref


# Construct CuTe Pointers for the persistent dense blockscaled GEMM operation (emulated version)
def construct_cute_pointers_emulated(
    a: torch.Tensor,
    b: torch.Tensor,
    sfa: torch.Tensor,
    sfb: torch.Tensor,
    c: torch.Tensor,
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
):
    a_cute, _ = cutlass_torch.cute_tensor_like(
        a.cpu(),
        a_dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )
    a_cute = cutlass_torch.convert_cute_tensor(
        a,
        a_cute,
        a_dtype,
        is_dynamic_layout=True,
    )
    b_cute, _ = cutlass_torch.cute_tensor_like(
        b.cpu(),
        b_dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )
    b_cute = cutlass_torch.convert_cute_tensor(
        b,
        b_cute,
        b_dtype,
        is_dynamic_layout=True,
    )
    a_ptr = a_cute.iterator
    b_ptr = b_cute.iterator

    sfa_ptr = make_ptr(
        sf_dtype, sfa.data_ptr(), cute.AddressSpace.gmem, assumed_align=32
    )
    sfb_ptr = make_ptr(
        sf_dtype, sfb.data_ptr(), cute.AddressSpace.gmem, assumed_align=32
    )
    c_ptr = make_ptr(c_dtype, c.data_ptr(), cute.AddressSpace.gmem, assumed_align=16)
    return a_ptr, b_ptr, c_ptr, sfa_ptr, sfb_ptr, a_cute, b_cute


# Construct CuTe Pointers for the persistent dense blockscaled GEMM operation (non-emulated version)
def construct_cute_pointers(
    a: torch.Tensor,
    b: torch.Tensor,
    sfa: torch.Tensor,
    sfb: torch.Tensor,
    c: torch.Tensor,
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
):
    a_ptr = make_ptr(a_dtype, a.data_ptr(), cute.AddressSpace.gmem, assumed_align=16)
    b_ptr = make_ptr(b_dtype, b.data_ptr(), cute.AddressSpace.gmem, assumed_align=16)
    sfa_ptr = make_ptr(
        sf_dtype, sfa.data_ptr(), cute.AddressSpace.gmem, assumed_align=32
    )
    sfb_ptr = make_ptr(
        sf_dtype, sfb.data_ptr(), cute.AddressSpace.gmem, assumed_align=32
    )
    c_ptr = make_ptr(c_dtype, c.data_ptr(), cute.AddressSpace.gmem, assumed_align=16)
    return a_ptr, b_ptr, c_ptr, sfa_ptr, sfb_ptr


# Use uint8 and uint32 to emulate unsupported
# dtype in torch
def prepare_tensors_emulated(
    mnkl: Tuple[int, int, int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
    ab_init_lo: int = -2,
    ab_init_hi: int = 2,
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
):
    m, n, k, l = mnkl
    sf_k = ceil_div(k, sf_vec_size)

    # Create tensor SFA/SFB with values in [1, 3)
    sfa = (
        torch.randint(0, 3, (l, m, sf_k), dtype=torch.uint8)
        .permute(1, 2, 0)
        .to(dtype=cutlass_torch.dtype(sf_dtype))
    )
    sfb = (
        torch.randint(0, 3, (l, n, sf_k), dtype=torch.uint8)
        .permute(1, 2, 0)
        .to(dtype=cutlass_torch.dtype(sf_dtype))
    )

    # Create tensor A/B
    if a_major == "k":
        a = torch.empty((l, m, k), dtype=torch.float32, device="cuda").permute(1, 2, 0)
    else:
        a = torch.empty((l, k, m), dtype=torch.float32, device="cuda").permute(2, 1, 0)
    if b_major == "k":
        b = torch.empty((l, n, k), dtype=torch.float32, device="cuda").permute(1, 2, 0)
    else:
        b = torch.empty((l, k, n), dtype=torch.float32, device="cuda").permute(2, 1, 0)

    # Initialize A/B tensors with either normal distribution or random integers
    for tensor in [a, b]:
        if init_normal:
            tensor.normal_(mean=normal_mean, std=normal_std)
        else:
            tensor.copy_(
                torch.randint(
                    ab_init_lo,
                    ab_init_hi,
                    tensor.shape,
                    dtype=torch.float32,
                    device="cuda",
                )
            )

    if c_major == "n":
        c = torch.empty(
            (l, m, n), dtype=cutlass_torch.dtype(c_dtype), device="cuda"
        ).permute(1, 2, 0)
    else:
        c = torch.empty(
            (l, n, m), dtype=cutlass_torch.dtype(c_dtype), device="cuda"
        ).permute(2, 1, 0)
    return a, b, c, sfa, sfb


def prepare_tensors(
    mnkl: Tuple[int, int, int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
    ab_init_lo: int = -2,
    ab_init_hi: int = 2,
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
):
    m, n, k, l = mnkl

    if a_dtype == cutlass.Float4E2M1FN and b_dtype == cutlass.Float4E2M1FN:
        # Using int8 for torch.float4_e2m1fn_x2 tensor allocation
        # Thus the size of k needs to be halved in this case.
        k_fct = 2
    else:
        k_fct = 1

    sf_k = ceil_div(k, sf_vec_size)

    # Create tensor SFA/SFB
    sfa = (
        torch.randint(0, 3, (l, m, sf_k), dtype=torch.uint8)
        .permute(1, 2, 0)
        .to(dtype=cutlass_torch.dtype(sf_dtype))
    )
    sfb = (
        torch.randint(0, 3, (l, n, sf_k), dtype=torch.uint8)
        .permute(1, 2, 0)
        .to(dtype=cutlass_torch.dtype(sf_dtype))
    )

    # Create tensor A/B
    if a_major == "k":
        a = torch.empty((l, m, k // k_fct), dtype=torch.int8, device="cuda").permute(
            1, 2, 0
        )
    else:
        a = torch.empty((l, k, m), dtype=torch.int8, device="cuda").permute(2, 1, 0)
    if b_major == "k":
        b = torch.empty((l, n, k // k_fct), dtype=torch.int8, device="cuda").permute(
            1, 2, 0
        )
    else:
        b = torch.empty((l, k, n), dtype=torch.int8, device="cuda").permute(2, 1, 0)

    # Initialize A/B tensors with random integers
    # Note: int8 types always use random init (normal distribution not supported),
    # consistent with use_normal_init pattern in generate_tensors
    for tensor in [a, b]:
        tensor.copy_(
            torch.randint(
                ab_init_lo, ab_init_hi, tensor.shape, dtype=torch.int8, device="cuda"
            )
        )

    # Create and initialize tensor C
    if c_major == "n":
        c_shape, c_perm = (l, m, n), (1, 2, 0)
    else:
        c_shape, c_perm = (l, n, m), (2, 1, 0)

    c = torch.randint(
        -2, 2, c_shape, dtype=cutlass_torch.dtype(c_dtype), device="cuda"
    ).permute(c_perm)

    if a_dtype == cutlass.Float4E2M1FN and b_dtype == cutlass.Float4E2M1FN:
        a = a.view(dtype=torch.float4_e2m1fn_x2)
        b = b.view(dtype=torch.float4_e2m1fn_x2)
    else:
        a = a.to(dtype=cutlass_torch.dtype(a_dtype))
        b = b.to(dtype=cutlass_torch.dtype(b_dtype))

    c = c.to(dtype=cutlass_torch.dtype(c_dtype))
    return a, b, c, sfa, sfb


# This will show how to convert torch tensor
# and pass to CuTe kernel

#####################################################################
#### KERNEL IMPLEMENTATION END HERE ####
#####################################################################

_DISTRIBUTED_INITIALIZED = False


def check_cuda_p2p_access():
    num_devices = torch.cuda.device_count()
    for i in range(num_devices - 1):
        for j in range(i + 1, num_devices):
            if not torch.cuda.can_device_access_peer(i, j):
                return False
    return True


def check_multicast_support():
    try:
        from torch._C._autograd import DeviceType
        from torch._C._distributed_c10d import _SymmetricMemory

        for device_id in range(torch.cuda.device_count()):
            if not _SymmetricMemory.has_multicast_support(DeviceType.CUDA, device_id):
                return False
        return True
    except ImportError:
        return False


def init_distributed():
    global _DISTRIBUTED_INITIALIZED

    if not dist.is_initialized() and not _DISTRIBUTED_INITIALIZED:
        if not torch.cuda.is_available():
            print("CUDA is not available")
            exit(-1)
        if torch.cuda.get_device_capability()[0] != 10:
            print("Running on non-sm100 device")
            exit(-1)
        if torch.cuda.device_count() < 2:
            print("Less than two devices")
            exit(-1)
        if torch.cuda.device_count() % 2 != 0:
            print("Odd world size")
            exit(-1)
        for var in ("LOCAL_RANK", "RANK", "WORLD_SIZE"):
            if var not in os.environ:
                print(f"{var} not in environment variables")
                exit(-1)

        local_rank = int(os.environ["LOCAL_RANK"])
        global_rank = int(os.environ["RANK"])
        world_size = int(os.environ["WORLD_SIZE"])
        device = torch.device("cuda", local_rank)
        torch.cuda.set_device(device)

        dist.init_process_group(
            backend="nccl",
            world_size=world_size,
            rank=global_rank,
            device_id=device,
        )
        _DISTRIBUTED_INITIALIZED = True
        print(
            f"[init] hostname={socket.gethostname()} global_rank={global_rank} "
            f"local_rank={local_rank} world_size={world_size} device={device}"
        )

    global_rank = dist.get_rank()
    world_size = dist.get_world_size()
    local_rank = int(os.environ.get("LOCAL_RANK", global_rank))
    device = torch.device("cuda", local_rank)
    return global_rank, world_size, device


def clean_distributed():
    if dist.is_initialized():
        dist.destroy_process_group()


def test_simple_torch_allreduce(device):
    try:
        tensor = symm_mem.empty((16384,), dtype=torch.float32, device=device)
        symm_mem.rendezvous(tensor, group=dist.group.WORLD)
        torch.ops.symm_mem.multimem_all_reduce_(
            tensor, "sum", dist.group.WORLD.group_name
        )
    except Exception:
        return False
    return True


def allocate_tensors(
    *,
    mnkl: Tuple[int, int, int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: Literal["k", "m"],
    b_major: Literal["k", "n"],
    c_major: Literal["n", "m"],
    num_workspace: int,
    slot_init_mode: Literal["test", "benchmark"],
    device=None,
    global_rank: int = 0,
    world_size: int = 1,
):
    """Allocate num_workspace slabs of A/B/SFA/SFB for L2-cold rotation,
    plus symm_mem C (comm_in) and comm_out and flag tensors for AR.

    Returns a dict with lists of cute pointers ready to pass to the compiled kernel,
    plus workspace-0 raw torch tensors for reference checking.
    """

    def _create_multicast_tensor(*, torch_tensor_ref, dtype, leading_dim):
        is_col_major = leading_dim == 0
        shape = torch_tensor_ref.shape
        ref_dtype = torch_tensor_ref.dtype

        if is_col_major:
            reversed_shape = tuple(reversed(shape))
            perm = tuple(range(len(shape) - 1, -1, -1))
            torch_symm_base = symm_mem.empty(
                reversed_shape, device=device, dtype=ref_dtype
            )
            torch_tensor_uc = torch_symm_base.permute(perm)
        else:
            torch_symm_base = symm_mem.empty(shape, device=device, dtype=ref_dtype)
            torch_tensor_uc = torch_symm_base

        torch_tensor_uc.copy_(torch_tensor_ref)

        torch_tensor_hdl = symm_mem.rendezvous(torch_symm_base, group=dist.group.WORLD)

        cute_tensor_uc = from_dlpack(torch_tensor_uc, assumed_align=16)
        cute_tensor_uc.element_type = dtype
        cute_tensor_uc = cute_tensor_uc.mark_layout_dynamic(leading_dim=leading_dim)
        cute_tensor_uc = cutlass_torch.convert_cute_tensor(
            torch_tensor_uc,
            cute_tensor_uc,
            dtype,
            is_dynamic_layout=True,
        )

        if is_col_major:
            mc_torch = cutlass_torch.as_tensor(
                torch_tensor_hdl.multicast_ptr, reversed_shape, ref_dtype
            ).permute(perm)
        else:
            mc_torch = cutlass_torch.as_tensor(
                torch_tensor_hdl.multicast_ptr, shape, ref_dtype
            )
        cute_tensor_mc = from_dlpack(mc_torch, assumed_align=16)
        cute_tensor_mc.element_type = dtype
        cute_tensor_mc = cute_tensor_mc.mark_layout_dynamic(leading_dim=leading_dim)

        return cute_tensor_uc, cute_tensor_mc, torch_tensor_uc

    torch.manual_seed(42 + global_rank)
    ab_init_lo, ab_init_hi = (-1, 1) if slot_init_mode == "test" else (-5, 5)
    m, n, k, l = mnkl
    emulated = is_emulated_dtype(a_dtype, b_dtype, sf_dtype, c_dtype)
    _prepare = prepare_tensors_emulated if emulated else prepare_tensors

    a_ptr_list, b_ptr_list, sfa_ptr_list, sfb_ptr_list = [], [], [], []
    # Keep every torch tensor alive — cute pointers hold raw addresses, not refs.
    anchors = []

    for _ in range(num_workspace):
        a, b, c, sfa_raw, sfb_raw = _prepare(
            mnkl,
            a_dtype,
            b_dtype,
            sf_dtype,
            sf_vec_size,
            c_dtype,
            a_major,
            b_major,
            c_major,
            ab_init_lo=ab_init_lo,
            ab_init_hi=ab_init_hi,
        )
        sfa_r = create_and_reorder_scale_factor_tensor(
            l, m, k, sf_vec_size, sf_dtype, sfa_raw
        )
        sfb_r = create_and_reorder_scale_factor_tensor(
            l, n, k, sf_vec_size, sf_dtype, sfb_raw
        )

        if emulated:
            a_ptr, b_ptr, _c_ptr_unused, sfa_ptr, sfb_ptr, a_cute, b_cute = (
                construct_cute_pointers_emulated(
                    a, b, sfa_r, sfb_r, c, a_dtype, b_dtype, sf_dtype, c_dtype
                )
            )
            anchors.append((a, b, c, sfa_raw, sfb_raw, sfa_r, sfb_r, a_cute, b_cute))
        else:
            a_ptr, b_ptr, _c_ptr_unused, sfa_ptr, sfb_ptr = construct_cute_pointers(
                a, b, sfa_r, sfb_r, c, a_dtype, b_dtype, sf_dtype, c_dtype
            )
            anchors.append((a, b, c, sfa_raw, sfb_raw, sfa_r, sfb_r))

        a_ptr_list.append(a_ptr)
        b_ptr_list.append(b_ptr)
        sfa_ptr_list.append(sfa_ptr)
        sfb_ptr_list.append(sfb_ptr)

    # Use workspace-0 C as the symm_mem comm_in tensor (C is written by GEMM, then AR'd)
    c_ref_cpu = anchors[0][2].cpu()
    comm_out_cpu = torch.zeros_like(c_ref_cpu)

    leading_dim = 1 if c_major == "n" else 0
    (
        cute_tensor_c,
        cute_tensor_comm_in_mc,
        torch_tensor_c_gpu,
    ) = _create_multicast_tensor(
        torch_tensor_ref=c_ref_cpu,
        dtype=c_dtype,
        leading_dim=leading_dim,
    )
    (
        _cute_tensor_comm_out_uc,
        cute_tensor_comm_out_mc,
        torch_tensor_comm_out_gpu,
    ) = _create_multicast_tensor(
        torch_tensor_ref=comm_out_cpu,
        dtype=c_dtype,
        leading_dim=leading_dim,
    )

    # Flag tensor: num_tiles + per-SM slots (160 is safe upper bound for B200)
    num_flags = (m // 64) * (n // 64) + 160

    torch_tensor_flag_unicast = symm_mem.empty(
        (num_flags,), dtype=torch.int32, device=device
    )
    torch_tensor_flag_unicast.fill_(0)
    torch_flag_hdl = symm_mem.rendezvous(
        torch_tensor_flag_unicast, group=dist.group.WORLD
    )
    torch_tensor_flag_multicast = cutlass_torch.as_tensor(
        torch_flag_hdl.multicast_ptr,
        torch_tensor_flag_unicast.shape,
        torch_tensor_flag_unicast.dtype,
    )
    cute_tensor_flag_unicast = from_dlpack(torch_tensor_flag_unicast, assumed_align=16)
    cute_tensor_flag_unicast.element_type = cutlass.Int32
    cute_tensor_flag_unicast = cute_tensor_flag_unicast.mark_layout_dynamic()
    cute_tensor_flag_multicast = from_dlpack(
        torch_tensor_flag_multicast, assumed_align=16
    )
    cute_tensor_flag_multicast.element_type = cutlass.Int32
    cute_tensor_flag_multicast = cute_tensor_flag_multicast.mark_layout_dynamic()

    return {
        "a_ptr_list": a_ptr_list,
        "b_ptr_list": b_ptr_list,
        "sfa_ptr_list": sfa_ptr_list,
        "sfb_ptr_list": sfb_ptr_list,
        "cute_tensor_c": cute_tensor_c,
        "cute_tensor_comm_in_mc": cute_tensor_comm_in_mc,
        "cute_tensor_comm_out_mc": cute_tensor_comm_out_mc,
        "cute_tensor_flag_unicast": cute_tensor_flag_unicast,
        "cute_tensor_flag_multicast": cute_tensor_flag_multicast,
        # Workspace-0 raw tensors for reference check in run_distributed_test.
        "a_raw": anchors[0][0],
        "b_raw": anchors[0][1],
        "torch_tensor_c_gpu": torch_tensor_c_gpu,
        "torch_tensor_comm_out_gpu": torch_tensor_comm_out_gpu,
        "torch_tensor_flag_unicast": torch_tensor_flag_unicast,
        "sfa_raw": anchors[0][3],
        "sfb_raw": anchors[0][4],
        "_anchors": anchors,
        "emulated": emulated,
        "_flag_handle": torch_flag_hdl,
    }


def run(
    mnkl: Tuple[int, int, int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: Literal["k", "m"],
    b_major: Literal["k", "n"],
    c_major: Literal["n", "m"],
    mma_tiler_mn: Tuple[int, int] = (256, 256),
    cluster_shape_mn: Tuple[int, int] = (2, 1),
    swizzle_size: int = 1,
    raster_order: Literal["m", "n"] = "m",
    warmup_iterations: int = 0,
    iterations: int = 1,
    benchmark_or_test: str = "test",
    use_cuda_graph: bool = False,
    csv_report: str = "./csv_report.csv",
):
    global_rank, world_size, device = init_distributed()

    if not check_cuda_p2p_access():
        print("CUDA P2P access not available")
        exit(-1)
    if not check_multicast_support():
        print("Multicast support not available")
        exit(-1)
    if not test_simple_torch_allreduce(device):
        print("Simple torch allreduce test failed")
        exit(-1)

    def _verbose():
        print(
            "Running SM100 BlockScale GEMM + AllReduce (LDMCxSTMC) Fusion Kernel with:"
        )
        print(f"mnkl: {mnkl}")
        print(f"global_rank: {global_rank}, world_size: {world_size}, device: {device}")
        print(
            f"A dtype: {a_dtype}, B dtype: {b_dtype}, SF dtype: {sf_dtype}, sf_vec_size: {sf_vec_size}"
        )
        print(f"C dtype: {c_dtype}")
        print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
        print(f"Mma Tiler (M, N): {mma_tiler_mn}")
        print(f"Cluster Shape (M, N): {cluster_shape_mn}")
        print(f"Warmup iterations: {warmup_iterations}")
        print(f"Iterations: {iterations}")
        print(f"Use CUDA Graph: {use_cuda_graph}")
        print(f"Mode: {benchmark_or_test}")
        print("AllReduce: LDMCxSTMC")

    if global_rank == 0:
        _verbose()

    if benchmark_or_test in ("benchmark", "benchmark_all"):
        run_distributed_benchmark(
            global_rank=global_rank,
            world_size=world_size,
            device=device,
            mnkl=mnkl,
            a_dtype=a_dtype,
            b_dtype=b_dtype,
            sf_dtype=sf_dtype,
            sf_vec_size=sf_vec_size,
            c_dtype=c_dtype,
            a_major=a_major,
            b_major=b_major,
            c_major=c_major,
            mma_tiler_mn=mma_tiler_mn,
            cluster_shape_mn=cluster_shape_mn,
            warmup_iterations=warmup_iterations,
            iterations=iterations,
            use_cuda_graph=use_cuda_graph,
            benchmark_all=(benchmark_or_test == "benchmark_all"),
            csv_report=csv_report,
            swizzle_size=swizzle_size,
            raster_order=raster_order,
        )
    else:
        run_distributed_test(
            global_rank=global_rank,
            world_size=world_size,
            device=device,
            mnkl=mnkl,
            a_dtype=a_dtype,
            b_dtype=b_dtype,
            sf_dtype=sf_dtype,
            sf_vec_size=sf_vec_size,
            c_dtype=c_dtype,
            a_major=a_major,
            b_major=b_major,
            c_major=c_major,
            mma_tiler_mn=mma_tiler_mn,
            cluster_shape_mn=cluster_shape_mn,
            swizzle_size=swizzle_size,
            raster_order=raster_order,
        )

    clean_distributed()


def run_distributed_test(
    global_rank: int,
    world_size: int,
    device: int,
    mnkl: Tuple[int, int, int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: Literal["k", "m"],
    b_major: Literal["k", "n"],
    c_major: Literal["n", "m"],
    mma_tiler_mn: Tuple[int, int] = (128, 128),
    cluster_shape_mn: Tuple[int, int] = (1, 1),
    swizzle_size: int = 1,
    raster_order: Literal["m", "n"] = "m",
):
    m, n, k, l = mnkl
    torch_stream = torch.cuda.Stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)

    gemm = Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel(
        sf_vec_size,
        mma_tiler_mn,
        cluster_shape_mn,
        c_dtype=c_dtype,
        rank_id=global_rank,
        num_ranks=world_size,
        swizzle_size=swizzle_size,
        raster_order=raster_order,
    )
    try:
        import hashlib

        param_str = (
            f"a{a_dtype}_b{b_dtype}_sf{sf_dtype}_sfv{sf_vec_size}_c{c_dtype}"
            f"_{a_major}{b_major}{c_major}"
            f"_tile{mma_tiler_mn[0]}x{mma_tiler_mn[1]}"
            f"_cluster{cluster_shape_mn[0]}x{cluster_shape_mn[1]}"
        )
        param_hash = hashlib.md5(param_str.encode()).hexdigest()[:8]
        unique_name = (
            f"sm100_blockscale_dense_gemm_ar_{param_hash}_r{global_rank}_w{world_size}"
        )
    except Exception:
        unique_name = f"sm100_blockscale_dense_gemm_ar_r{global_rank}_w{world_size}"
    gemm.__call__.set_name_prefix(unique_name)

    if not Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel.can_implement(
        mnkl,
        a_dtype,
        b_dtype,
        sf_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        sf_vec_size,
        mma_tiler_mn,
        cluster_shape_mn,
        num_ranks=world_size,
        swizzle_size=swizzle_size,
        raster_order=raster_order,
    ):
        raise testing.CantImplementError(
            f"Unsupported config: a={a_dtype} b={b_dtype} sf={sf_dtype} sfv={sf_vec_size} "
            f"c={c_dtype} tile={mma_tiler_mn} cluster={cluster_shape_mn}"
        )

    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    tensors = allocate_tensors(
        mnkl=mnkl,
        a_dtype=a_dtype,
        b_dtype=b_dtype,
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
        c_dtype=c_dtype,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
        num_workspace=1,
        slot_init_mode="test",
        device=device,
        global_rank=global_rank,
        world_size=world_size,
    )

    compiled_gemm = scaled_mm_ar(
        gemm,
        a_dtype,
        b_dtype,
        c_dtype,
        sf_dtype,
        a_major,
        b_major,
        c_major,
        max_active_clusters,
        stream,
        tensors["cute_tensor_comm_in_mc"],
        tensors["cute_tensor_comm_out_mc"],
        tensors["cute_tensor_flag_unicast"],
        tensors["cute_tensor_flag_multicast"],
    )

    compiled_gemm(
        tensors["a_ptr_list"][0],
        tensors["b_ptr_list"][0],
        tensors["sfa_ptr_list"][0],
        tensors["sfb_ptr_list"][0],
        tensors["cute_tensor_c"],
        (m, n, k, l),
        stream,
        lambda x: x,
        tensors["cute_tensor_comm_in_mc"],
        tensors["cute_tensor_comm_out_mc"],
        tensors["cute_tensor_flag_unicast"],
        tensors["cute_tensor_flag_multicast"],
    )
    torch.cuda.synchronize()

    emulated = tensors["emulated"]
    a_raw = tensors["a_raw"]
    b_raw = tensors["b_raw"]
    sfa_raw = tensors["sfa_raw"]
    sfb_raw = tensors["sfb_raw"]
    torch_tensor_c = tensors["torch_tensor_c_gpu"]
    torch_tensor_comm_out = tensors["torch_tensor_comm_out_gpu"]
    torch_tensor_flag_unicast = tensors["torch_tensor_flag_unicast"]

    # FP8 nan to saturate helper
    def _fp8_nan_to_saturate(tensor_fp8: torch.Tensor) -> torch.Tensor:
        if tensor_fp8.dtype == torch.float8_e4m3fn:
            tensor_u8 = tensor_fp8.view(torch.uint8)
            is_pos_nan = tensor_u8 == 0x7F
            is_neg_nan = tensor_u8 == 0xFF
            tensor_f32 = tensor_fp8.to(dtype=torch.float32)
            tensor_f32[is_pos_nan] = 448
            tensor_f32[is_neg_nan] = -448
            tensor_f8_out = tensor_f32.to(dtype=tensor_fp8.dtype)
        elif tensor_fp8.dtype == torch.float8_e5m2:
            tensor_u8 = tensor_fp8.view(torch.uint8)
            is_pos_nan = tensor_u8 == 0x7F
            is_neg_nan = tensor_u8 == 0xFF
            tensor_f32 = tensor_fp8.to(dtype=torch.float32)
            tensor_f32[is_pos_nan] = 57344
            tensor_f32[is_neg_nan] = -57344
            tensor_f8_out = tensor_f32.to(dtype=tensor_fp8.dtype)
        else:
            tensor_f8_out = tensor_fp8
        return tensor_f8_out

    # Compare GEMM output (blockscaled reference)
    def _compare_gemm_bs(
        a_raw, b_raw, sfa_raw, sfb_raw, torch_tensor_c, c_dtype, atol, rtol
    ):
        if emulated:
            c_ref = reference_scaled_mm_emulated(
                a_raw,
                b_raw,
                sfa_raw,
                sfb_raw,
                torch_tensor_c,
                mnkl,
                sf_vec_size,
                c_dtype,
            )
        else:
            c_ref = reference_scaled_mm(
                a_raw, b_raw, sfa_raw, sfb_raw, torch_tensor_c, mnkl, c_dtype
            )
        c_out_f32 = torch_tensor_c.cpu().to(dtype=torch.float32)
        c_ref_f32 = c_ref.cpu().to(dtype=torch.float32)
        torch.testing.assert_close(c_out_f32, c_ref_f32, atol=atol, rtol=rtol)

    def _compare_comm(torch_tensor_comm_in, torch_tensor_comm_out, c_dtype, atol, rtol):
        dist.barrier()
        if c_dtype in [cutlass.Float32, cutlass.BFloat16, cutlass.Float16]:
            # Use Float32 accumulation for an accurate reference (avoids Float16 overflow
            # discrepancy between symm_mem contiguous path vs regular tensor path in NCCL).
            comm_ref_f32_acc = torch_tensor_comm_in.to(dtype=torch.float32).contiguous()
            dist.all_reduce(comm_ref_f32_acc, op=torch.distributed.ReduceOp.SUM)
            comm_ref_f32 = comm_ref_f32_acc.cpu()
            comm_out_f32 = torch_tensor_comm_out.cpu().to(dtype=torch.float32)
            # multimem.ld_reduce reduces in Float16 and may overflow to ±inf for large values.
            # Clamp both reference and output to the dtype's representable range so that
            # hardware overflow (→ ±inf) compares equal to the clamped reference.
            if c_dtype == cutlass.Float16:
                float16_max = 65504.0
                comm_ref_f32 = comm_ref_f32.clamp(-float16_max, float16_max)
                comm_out_f32 = comm_out_f32.nan_to_num(
                    nan=0.0, posinf=float16_max, neginf=-float16_max
                )
        elif c_dtype in [cutlass.Float8E4M3FN, cutlass.Float8E5M2]:
            comm_ref_fp32_acc = torch_tensor_comm_in.to(
                dtype=torch.float32
            ).contiguous()
            dist.all_reduce(comm_ref_fp32_acc, op=torch.distributed.ReduceOp.SUM)
            epsilon = 1e-2
            comm_ref_f32_acc_epsilon = comm_ref_fp32_acc + epsilon
            comm_ref_c = comm_ref_f32_acc_epsilon.to(dtype=cutlass_torch.dtype(c_dtype))
            comm_ref_nan2sat = _fp8_nan_to_saturate(comm_ref_c)
            comm_ref_f32 = comm_ref_nan2sat.to(dtype=torch.float32).cpu()
            comm_out = torch_tensor_comm_out.cpu()
            comm_out_nan2sat = _fp8_nan_to_saturate(comm_out)
            comm_out_f32 = comm_out_nan2sat.to(dtype=torch.float32)
        torch.testing.assert_close(comm_ref_f32, comm_out_f32, atol=atol, rtol=rtol)

    tol = 0.0 if c_dtype in (cutlass.Float8E5M2, cutlass.Float8E4M3FN) else 1e-1
    _compare_gemm_bs(
        a_raw, b_raw, sfa_raw, sfb_raw, torch_tensor_c, c_dtype, atol=tol, rtol=tol
    )

    # Compare AllReduce output
    comm_atol = 5
    comm_rtol = 1e-1
    if c_dtype in [cutlass.Float8E4M3FN, cutlass.Float8E5M2]:
        comm_rtol = 1e-1
        comm_atol = 0.0
    _compare_comm(
        torch_tensor_comm_in=torch_tensor_c,
        torch_tensor_comm_out=torch_tensor_comm_out,
        c_dtype=c_dtype,
        atol=comm_atol,
        rtol=comm_rtol,
    )

    # Check that flags were reset to zero
    torch.cuda.synchronize()
    flag_after = torch_tensor_flag_unicast.cpu()
    nonzero_count = int(torch.count_nonzero(flag_after).item())
    assert nonzero_count == 0, (
        f"Kernel did not reset all barrier flags to zero: "
        f"{nonzero_count}/{flag_after.numel()} entries non-zero "
        f"(first 16 values: {flag_after[:16].tolist()})"
    )


def compile_and_benchmark(
    *,
    mnkl,
    a_dtype,
    b_dtype,
    sf_dtype,
    sf_vec_size,
    c_dtype,
    a_major,
    b_major,
    c_major,
    mma_tiler_mn,
    cluster_shape_mn,
    swizzle_size: int = 1,
    raster_order: Literal["m", "n"] = "m",
    global_rank,
    world_size,
    device,
    num_workspace,
    tensors,
    torch_stream,
    stream,
    warmup_iterations,
    iterations,
    use_cuda_graph,
):
    """Compile one blockscaled-GEMM + AR candidate and time it. Returns avg_us."""
    m, n, k, l = mnkl

    gemm = Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel(
        sf_vec_size,
        mma_tiler_mn,
        cluster_shape_mn,
        c_dtype=c_dtype,
        rank_id=global_rank,
        num_ranks=world_size,
        swizzle_size=swizzle_size,
        raster_order=raster_order,
    )
    try:
        import hashlib

        param_str = (
            f"a{a_dtype}_b{b_dtype}_sf{sf_dtype}_sfv{sf_vec_size}_c{c_dtype}"
            f"_{a_major}{b_major}{c_major}"
            f"_tile{mma_tiler_mn[0]}x{mma_tiler_mn[1]}"
            f"_cluster{cluster_shape_mn[0]}x{cluster_shape_mn[1]}"
        )
        param_hash = hashlib.md5(param_str.encode()).hexdigest()[:8]
        unique_name = (
            f"sm100_blockscale_dense_gemm_ar_{param_hash}_r{global_rank}_w{world_size}"
        )
    except Exception:
        unique_name = f"sm100_blockscale_dense_gemm_ar_r{global_rank}_w{world_size}"
    gemm.__call__.set_name_prefix(unique_name)

    if not Sm100PersistentBlockScaleDenseGemmAllReduceLDMCxSTMCKernel.can_implement(
        mnkl,
        a_dtype,
        b_dtype,
        sf_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        sf_vec_size,
        mma_tiler_mn,
        cluster_shape_mn,
        num_ranks=world_size,
        swizzle_size=swizzle_size,
        raster_order=raster_order,
    ):
        raise testing.CantImplementError(
            f"Unsupported config: a={a_dtype} b={b_dtype} sf={sf_dtype} sfv={sf_vec_size} "
            f"c={c_dtype} tile={mma_tiler_mn} cluster={cluster_shape_mn}"
        )

    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    compiled_gemm = scaled_mm_ar(
        gemm,
        a_dtype,
        b_dtype,
        c_dtype,
        sf_dtype,
        a_major,
        b_major,
        c_major,
        max_active_clusters,
        stream,
        tensors["cute_tensor_comm_in_mc"],
        tensors["cute_tensor_comm_out_mc"],
        tensors["cute_tensor_flag_unicast"],
        tensors["cute_tensor_flag_multicast"],
    )

    a_ptr_list = tensors["a_ptr_list"]
    b_ptr_list = tensors["b_ptr_list"]
    sfa_ptr_list = tensors["sfa_ptr_list"]
    sfb_ptr_list = tensors["sfb_ptr_list"]
    cute_c = tensors["cute_tensor_c"]
    comm_in_mc = tensors["cute_tensor_comm_in_mc"]
    comm_out_mc = tensors["cute_tensor_comm_out_mc"]
    flag_uc = tensors["cute_tensor_flag_unicast"]
    flag_mc = tensors["cute_tensor_flag_multicast"]

    def make_kernel_args(ws):
        return (
            a_ptr_list[ws],
            b_ptr_list[ws],
            sfa_ptr_list[ws],
            sfb_ptr_list[ws],
            cute_c,
            (m, n, k, l),
            stream,
            lambda x: x,
            comm_in_mc,
            comm_out_mc,
            flag_uc,
            flag_mc,
        )

    kernel_args_list = [make_kernel_args(i) for i in range(num_workspace)]

    if use_cuda_graph:
        graphs = []
        for ws in range(num_workspace):
            g = torch.cuda.CUDAGraph()
            with torch.cuda.graph(g, stream=torch_stream):
                compiled_gemm(*kernel_args_list[ws])
            graphs.append(g)

        def run_one_iter(i):
            graphs[i % num_workspace].replay()
    else:

        def run_one_iter(i):
            compiled_gemm(*kernel_args_list[i % num_workspace])

    torch.cuda.synchronize()
    dist.barrier()

    total_iters = warmup_iterations + iterations
    start_events = [torch.cuda.Event(enable_timing=True) for _ in range(total_iters)]
    end_events = [torch.cuda.Event(enable_timing=True) for _ in range(total_iters)]
    with torch.cuda.stream(torch_stream):
        for i in range(total_iters):
            start_events[i].record()
            run_one_iter(i)
            end_events[i].record()
    end_events[-1].synchronize()

    per_iter_us = [s.elapsed_time(e) * 1000.0 for s, e in zip(start_events, end_events)]
    avg_us = sum(per_iter_us[warmup_iterations:]) / iterations
    print(
        f"Rank {global_rank} Execution time: {avg_us} us "
        f"(avg of {iterations} iters, after {warmup_iterations} warmup)\n",
        flush=True,
    )
    return avg_us


def run_distributed_benchmark(
    global_rank: int,
    world_size: int,
    device: int,
    mnkl: Tuple[int, int, int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: Literal["k", "m"],
    b_major: Literal["k", "n"],
    c_major: Literal["n", "m"],
    mma_tiler_mn: Tuple[int, int] = (256, 256),
    cluster_shape_mn: Tuple[int, int] = (2, 1),
    swizzle_size: int = 1,
    raster_order: Literal["m", "n"] = "m",
    warmup_iterations: int = 0,
    iterations: int = 1,
    use_cuda_graph: bool = False,
    benchmark_all: bool = False,
    csv_report: str = "./csv_report.csv",
):
    num_workspace = 10
    tensors = allocate_tensors(
        mnkl=mnkl,
        a_dtype=a_dtype,
        b_dtype=b_dtype,
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
        c_dtype=c_dtype,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
        num_workspace=num_workspace,
        slot_init_mode="benchmark",
        device=device,
        global_rank=global_rank,
        world_size=world_size,
    )

    torch_stream = torch.cuda.Stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)

    base_kwargs = dict(
        mnkl=mnkl,
        a_dtype=a_dtype,
        b_dtype=b_dtype,
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
        c_dtype=c_dtype,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
        global_rank=global_rank,
        world_size=world_size,
        device=device,
        num_workspace=num_workspace,
        tensors=tensors,
        torch_stream=torch_stream,
        stream=stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        use_cuda_graph=use_cuda_graph,
    )

    if benchmark_all:
        raster_candidates = ["m", "n"]
        swizzle_candidates = [1, 2, 4, 8]
        # use_2cta_instrs is implied by mma_tiler_mn[0] == 256.
        # 2CTA requires cluster_m in {2,4,8}; 1CTA accepts any cluster.
        two_cta_options = [
            {
                "clusters": [(2, 1), (2, 2)],
                "mma_tilers": [(256, 64), (256, 128), (256, 192), (256, 256)],
            },
            {
                "clusters": [(1, 1), (1, 2), (2, 1), (2, 2)],
                "mma_tilers": [(128, 64), (128, 128), (128, 192), (128, 256)],
            },
        ]
        candidates = []
        for opt in two_cta_options:
            for cluster in opt["clusters"]:
                for tile in opt["mma_tilers"]:
                    for r in raster_candidates:
                        for s in swizzle_candidates:
                            candidates.append(
                                {
                                    **base_kwargs,
                                    "mma_tiler_mn": tile,
                                    "cluster_shape_mn": cluster,
                                    "raster_order": r,
                                    "swizzle_size": s,
                                }
                            )
    else:
        candidates = [
            {
                **base_kwargs,
                "mma_tiler_mn": mma_tiler_mn,
                "cluster_shape_mn": cluster_shape_mn,
                "raster_order": raster_order,
                "swizzle_size": swizzle_size,
            }
        ]

    if global_rank == 0:
        print(f"Total number of candidate configs: {len(candidates)}", flush=True)

    results = []
    for i, cand in enumerate(candidates):
        if i > 0:
            time.sleep(2)
        try:
            avg_us = compile_and_benchmark(**cand)
        except testing.CantImplementError:
            continue
        results.append((cand, avg_us))

    m, n, k, l = mnkl
    fieldnames = [
        "gemm_m",
        "gemm_n",
        "gemm_k",
        "gemm_l",
        "a_dtype",
        "b_dtype",
        "sf_dtype",
        "sf_vec_size",
        "c_dtype",
        "a_major",
        "b_major",
        "c_major",
        "mma_tiler_m",
        "mma_tiler_n",
        "cluster_m",
        "cluster_n",
        "use_cuda_graph",
        "swizzle_size",
        "raster_order",
        "num_workspace",
        "warmup_iterations",
        "iterations",
        "world_size",
        "global_rank",
        "benchmark_time_us",
    ]
    csv_path = Path(csv_report)
    csv_path = csv_path.with_name(
        f"{csv_path.stem}_rank{global_rank}_world{world_size}{csv_path.suffix}"
    )
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    with open(csv_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for cand, avg_us in results:
            writer.writerow(
                {
                    "gemm_m": m,
                    "gemm_n": n,
                    "gemm_k": k,
                    "gemm_l": l,
                    "a_dtype": str(a_dtype),
                    "b_dtype": str(b_dtype),
                    "sf_dtype": str(sf_dtype),
                    "sf_vec_size": sf_vec_size,
                    "c_dtype": str(c_dtype),
                    "a_major": a_major,
                    "b_major": b_major,
                    "c_major": c_major,
                    "mma_tiler_m": cand["mma_tiler_mn"][0],
                    "mma_tiler_n": cand["mma_tiler_mn"][1],
                    "cluster_m": cand["cluster_shape_mn"][0],
                    "cluster_n": cand["cluster_shape_mn"][1],
                    "use_cuda_graph": use_cuda_graph,
                    "swizzle_size": cand["swizzle_size"],
                    "raster_order": cand["raster_order"],
                    "num_workspace": num_workspace,
                    "warmup_iterations": warmup_iterations,
                    "iterations": iterations,
                    "world_size": world_size,
                    "global_rank": global_rank,
                    "benchmark_time_us": avg_us,
                }
            )

    return results[0][1] if len(results) == 1 else results


def prepare_parser():
    parser = argparse.ArgumentParser(
        description="SM100 BlockScale GEMM + AllReduce (LDMCxSTMC) Fusion Kernel."
    )

    def _parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser.add_argument(
        "--mnkl", type=_parse_comma_separated_ints, default=(512, 512, 256, 1)
    )
    parser.add_argument(
        "--mma_tiler_mn", type=_parse_comma_separated_ints, default=(128, 128)
    )
    parser.add_argument(
        "--cluster_shape_mn", type=_parse_comma_separated_ints, default=(1, 1)
    )
    parser.add_argument("--a_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--b_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--sf_dtype", type=cutlass.dtype, default=cutlass.Float8E4M3FN)
    parser.add_argument("--sf_vec_size", type=int, default=16)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--a_major", choices=["k", "m"], default="k")
    parser.add_argument("--b_major", choices=["k", "n"], default="k")
    parser.add_argument("--c_major", choices=["n", "m"], default="n")
    parser.add_argument(
        "--benchmark_or_test",
        type=str,
        choices=["test", "benchmark", "benchmark_all"],
        default="test",
        help="Select run mode: 'test' for correctness, 'benchmark' for timing, 'benchmark_all' for a sweep.",
    )
    parser.add_argument("--warmup_iterations", type=int, default=0)
    parser.add_argument("--iterations", type=int, default=1)
    parser.add_argument(
        "--use_cuda_graph",
        action="store_true",
        default=False,
        help="Capture one iteration into a CUDA graph and replay per iteration",
    )
    parser.add_argument(
        "--swizzle_size",
        type=int,
        default=1,
        help="Swizzling size in the unit of cluster for improving L2 cache hit rate",
    )
    parser.add_argument(
        "--raster_order",
        type=str,
        choices=["m", "n"],
        default="m",
        help="Rasterization order of clusters",
    )
    parser.add_argument(
        "--csv_report",
        type=str,
        default="./csv_report.csv",
        help="Path for the per-rank benchmark CSV. Each rank appends _rank{R}_world{W} before the extension.",
    )
    parser.add_argument(
        "--all_reduce",
        type=str,
        default="LDMCxSTMC",
        help="AllReduce algorithm (currently only LDMCxSTMC is supported).",
    )
    return parser


if __name__ == "__main__":
    parser = prepare_parser()
    args = parser.parse_args()

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")
    if len(args.mma_tiler_mn) != 2:
        parser.error("--mma_tiler_mn must contain exactly 2 values")
    if len(args.cluster_shape_mn) != 2:
        parser.error("--cluster_shape_mn must contain exactly 2 values")

    run(
        mnkl=args.mnkl,
        a_dtype=args.a_dtype,
        b_dtype=args.b_dtype,
        sf_dtype=args.sf_dtype,
        sf_vec_size=args.sf_vec_size,
        c_dtype=args.c_dtype,
        a_major=args.a_major,
        b_major=args.b_major,
        c_major=args.c_major,
        mma_tiler_mn=args.mma_tiler_mn,
        cluster_shape_mn=args.cluster_shape_mn,
        swizzle_size=args.swizzle_size,
        raster_order=args.raster_order,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
        benchmark_or_test=args.benchmark_or_test,
        use_cuda_graph=args.use_cuda_graph,
        csv_report=args.csv_report,
    )
    rank = int(os.environ["RANK"])
    local_rank = int(os.environ["LOCAL_RANK"])
    print(
        f"PASS (hostname={socket.gethostname()}, global_rank={rank}, local_rank={local_rank})",
        flush=True,
    )
