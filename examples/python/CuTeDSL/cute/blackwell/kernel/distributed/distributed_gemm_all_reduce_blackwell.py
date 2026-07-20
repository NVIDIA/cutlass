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
import glob
import json
import socket
import time
from pathlib import Path

from math import gcd
from typing import Optional, Tuple, Type, Union, Literal

import cuda.bindings.driver as cuda

import torch
import torch.distributed as dist
import torch.distributed._symmetric_memory as symm_mem

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
import cutlass.torch as cutlass_torch
from cutlass.torch import dtype as torch_dtype
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
from cutlass.cutlass_dsl import BaseDSL
from cutlass.cute.nvgpu import cpasync, tcgen05
from cutlass.cute.runtime import from_dlpack

"""
SM100 GEMM + AllReduce (LDMCxSTMC) Fusion Kernel

* Test (correctness only — single launch, no warmup/iteration loop)
python3 -m torch.distributed.run --nproc-per-node=auto examples/python/CuTeDSL/cute/blackwell/kernel/distributed/distributed_gemm_all_reduce_blackwell.py  \
    --ab_dtype Float16 --c_dtype Float16 --acc_dtype Float32                                        \
    --a_major k --b_major k --c_major n                                                             \
    --mma_tiler_mn 256,256 --cluster_shape_mn 2,1                                                   \
    --mnkl 8192,8192,8192,1                                                                         \
    --use_tma_store --use_2cta_instrs --all_reduce LDMCxSTMC                                        \
    --benchmark_or_test test

* Benchmark One
python3 -m torch.distributed.run --nproc-per-node=auto examples/python/CuTeDSL/cute/blackwell/kernel/distributed/distributed_gemm_all_reduce_blackwell.py  \
    --ab_dtype Float16 --c_dtype Float16 --acc_dtype Float32                                        \
    --a_major k --b_major k --c_major n                                                             \
    --mma_tiler_mn 256,256 --cluster_shape_mn 2,1                                                   \
    --mnkl 8192,8192,8192,1 --warmup_iterations 10 --iterations 20                                  \
    --use_tma_store --use_2cta_instrs --all_reduce LDMCxSTMC                                        \
    --benchmark_or_test benchmark --use_cuda_graph --csv_report ./csv_report.csv

* Benchmark All
python3 -m torch.distributed.run --nproc-per-node=auto examples/python/CuTeDSL/cute/blackwell/kernel/distributed/distributed_gemm_all_reduce_blackwell.py  \
    --ab_dtype Float16 --c_dtype Float16 --acc_dtype Float32                                        \
    --a_major k --b_major k --c_major n                                                             \
    --mnkl 8192,8192,8192,1 --warmup_iterations 10 --iterations 20                                  \
    --use_tma_store --all_reduce LDMCxSTMC                                                          \
    --benchmark_or_test benchmark_all --use_cuda_graph --csv_report ./csv_report.csv

NOTE:
* multimem.ld_reduce does NOT handle NaN issue for f8.

ALGO:
-> Producer
for each output tile
    * store gemm output [data] (UC) to local rank global memory with .weak semantics (tma is default .weak semantic)
    * [flag] (MC) update with .release semantics and .gpu scope (prior store is to local rank global memory thus .gpu scope) on multicast flag ptr (thus flag update broadcast to all rank)

-> Consumer
for each output tile
    * spin lock wait [flag] (UC) with .relaxed / .acquire and .gpu scope (all rank have write their data to local rank gmem)
    * multimem.ld_reduce send [data] (MC) reduce request to switch, switch send request to all rank's gmem, reduce on switch, return to requester rank
    * multimem.st broadcast reduced [data] (MC) to all rank as each output tile is handled collectively by P rank
before kernel exit
    * [flag] (MC) update with .release semantics and .sys scope (prior store broadcast data to all rank in sys)
    * spin lock wait [flag] (UC) with .relaxed / .acquire and .sys scope
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


class Sm100PersistentDenseGemmAllReduceLDMCxSTMCKernel:
    """
    **Example:**
        gemm = Sm100PersistentDenseGemmAllReduceLDMCxSTMCKernel(
            acc_dtype=cutlass.Float32,
            c_dtype=cutlass.BFloat16,
            use_2cta_instrs=True,
            mma_tiler_mn=(256, 256),
            cluster_shape_mn=(2, 1),
            use_tma_store=True,
            rank_id=rank_id,
            num_ranks=num_ranks,
            all_reduce="LDMCxSTMC",
            swizzle_size=1,
            raster_order="m",
        )
        compiled_gemm = cute.compile(
            gemm,
            a=a, b=b, c=c,
            comm_in_multicast_tensor=comm_in_mc,
            comm_out_multicast_tensor=comm_out_mc,
            barrier_flag_unicast=flag_unicast,
            barrier_flag_multicast=flag_multicast,
            stream=stream,
            max_active_clusters=max_active_clusters,
        )
        compiled_gemm(
            a=a, b=b, c=c,
            comm_in_multicast_tensor=comm_in_mc,
            comm_out_multicast_tensor=comm_out_mc,
            barrier_flag_unicast=flag_unicast,
            barrier_flag_multicast=flag_multicast,
            stream=stream,
        )
    """

    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        use_tma_store: bool,
        rank_id: int,
        num_ranks: int,
        all_reduce: str = "LDMCxSTMC",
        swizzle_size: int = 1,
        raster_order: Literal["m", "n"] = "m",
    ):
        self.acc_dtype: Type[cutlass.Numeric] = acc_dtype
        self.c_dtype: Type[cutlass.Numeric] = c_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.cluster_shape_mn = cluster_shape_mn
        self.swizzle_size = swizzle_size
        self.raster_order = raster_order
        # K dimension is deferred in _setup_attributes
        self.mma_tiler_mn = mma_tiler_mn
        self.mma_tiler = (*mma_tiler_mn, 1)
        self.use_tma_store = use_tma_store
        # Capture the JIT target arch so SMEM/TMEM sizing tracks the actual
        # hardware (sm_100 / sm_103 / sm_107 / ...). Matches the FMHA pattern.
        arch_enum = BaseDSL._get_dsl().get_arch_enum()
        self.arch = f"sm_{arch_enum.major}{arch_enum.minor}"

        self.cta_group = (
            tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE
        )

        self.occupancy = 1
        # Set specialized warp ids
        self.epilogue_warp_id = (0, 1, 2, 3)
        self.mma_warp_id = 4
        self.tma_warp_id = 5
        self.all_reduce = all_reduce
        if all_reduce == "LDMCxSTMC":
            self.rank_id = rank_id
            self.num_ranks = num_ranks
            num_comm_warps = self._pick_num_comm_warp_for_128b(c_dtype)
            self.comm_warp_id = tuple(range(6, 6 + num_comm_warps))
            # Determine inflight depth: use inflight2 for special case (128x256 P=8), else inflight4
            # For 2SM kernel: cta_tile_m = mma_tile_m / 2, for 1SM: cta_tile_m = mma_tile_m
            mma_tile_m, mma_tile_n = mma_tiler_mn
            cta_tile_m = mma_tile_m // 2 if use_2cta_instrs else mma_tile_m
            cta_tile_n = mma_tile_n
            if cta_tile_m == 128 and cta_tile_n == 256 and num_ranks == 8:
                # Special case for largest tile + rank = 8 prefer in-flight = 2
                self.ldmcxstmc_default_inflight_depth = 2
            else:
                # For most cases, in-flight depth = 4 is best as it fully utilize overlapping ability
                self.ldmcxstmc_default_inflight_depth = 4
        else:
            # No AR mode — no comm warps.
            self.comm_warp_id = ()
            self.rank_id = 0
            self.num_ranks = 1

        self.threads_per_cta = 32 * len(
            (
                self.mma_warp_id,
                self.tma_warp_id,
                *self.epilogue_warp_id,
                *self.comm_warp_id,
            )
        )
        # Set barrier id for cta sync, epilogue sync and tmem ptr sync
        self.epilog_sync_bar_id = 1
        self.tmem_alloc_sync_bar_id = 2
        self.tmem_dealloc_sync_bar_id = 3
        self.comm_sync_bar_id = 4

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
        tiled_mma = utils.sm100.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
        )

        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        self.mma_tiler = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )

        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )

        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1

        if cutlass.const_expr(self.use_tma_store):
            self.epi_tile = utils.sm100.compute_epilogue_tile_shape(
                self.cta_tile_shape_mnk,
                self.use_2cta_instrs,
                self.c_layout,
                self.c_dtype,
            )
        else:
            self.epi_tile = self.cta_tile_shape_mnk[:2]

        c_smem_layout = None
        if cutlass.const_expr(self.use_tma_store):
            c_smem_layout = utils.sm100.make_smem_layout_epi(
                self.c_dtype, self.c_layout, self.epi_tile, 1
            )

        self.smem_capacity = utils.get_smem_capacity_in_bytes(self.arch)

        self.num_acc_stage, self.num_ab_stage, self.num_c_stage = self._compute_stages(
            tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.c_dtype,
            self.smem_capacity,
            self.occupancy,
            self.use_tma_store,
            c_smem_layout,
        )

        self.a_smem_layout_staged = utils.sm100.make_smem_layout_a(
            tiled_mma, self.mma_tiler, self.a_dtype, self.num_ab_stage
        )
        self.b_smem_layout_staged = utils.sm100.make_smem_layout_b(
            tiled_mma, self.mma_tiler, self.b_dtype, self.num_ab_stage
        )

        self.c_smem_layout_staged = None
        if self.use_tma_store:
            self.c_smem_layout_staged = utils.sm100.make_smem_layout_epi(
                self.c_dtype, self.c_layout, self.epi_tile, self.num_c_stage
            )

        self.num_tmem_alloc_cols = self._compute_num_tmem_alloc_cols(
            tiled_mma, self.mma_tiler, self.num_acc_stage, self.arch
        )

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        c: cute.Tensor,
        comm_in_multicast_tensor: cute.Tensor,
        comm_out_multicast_tensor: cute.Tensor,
        barrier_flag_unicast: cute.Tensor,
        barrier_flag_multicast: cute.Tensor,
        stream: cuda.CUstream,
        max_active_clusters: cutlass.Constexpr,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        # Setup static attributes before smem/grid/tma computation.
        # NOTE: self.c_dtype was set in __init__ from the explicit c_dtype
        # arg. We only sanity-check here that the C tensor matches that hint.
        self.a_dtype: Type[cutlass.Numeric] = a.element_type
        self.b_dtype: Type[cutlass.Numeric] = b.element_type
        if cutlass.const_expr(c.element_type != self.c_dtype):
            raise TypeError(
                f"C tensor element_type ({c.element_type}) does not match "
                f"the c_dtype declared at __init__ ({self.c_dtype})"
            )
        self.a_major_mode = utils.LayoutEnum.from_tensor(a).mma_major_mode()
        self.b_major_mode = utils.LayoutEnum.from_tensor(b).mma_major_mode()
        self.c_layout = utils.LayoutEnum.from_tensor(c)

        # Check if input data types are compatible with MMA instruction
        if cutlass.const_expr(self.a_dtype != self.b_dtype):
            raise TypeError(f"Type must match: {self.a_dtype} != {self.b_dtype}")

        tiled_mma = utils.sm100.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
        )

        # Setup attributes that dependent on gemm inputs
        self._setup_attributes()

        atom_thr_size = cute.size(tiled_mma.thr_id.shape)

        # Setup TMA load for A
        a_op = utils.sm100.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, None, 0))
        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            a_op,
            a,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if a.element_type is cutlass.Float32 else None
            ),
        )

        # Setup TMA load for B
        b_op = utils.sm100.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        b_smem_layout = cute.slice_(self.b_smem_layout_staged, (None, None, None, 0))
        tma_atom_b, tma_tensor_b = cute.nvgpu.make_tiled_tma_atom_B(
            b_op,
            b,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if b.element_type is cutlass.Float32 else None
            ),
        )

        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        self.num_tma_load_bytes = (a_copy_size + b_copy_size) * atom_thr_size

        # Setup TMA store for C
        tma_atom_c = None
        tma_tensor_c = None
        if cutlass.const_expr(self.use_tma_store):
            epi_smem_layout = cute.select(self.c_smem_layout_staged, mode=[0, 1])
            tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
                cpasync.CopyBulkTensorTileS2GOp(), c, epi_smem_layout, self.epi_tile
            )

        # Compute grid size
        self.tile_sched_params, grid = self._compute_grid(
            c,
            self.cta_tile_shape_mnk,
            self.cluster_shape_mn,
            self.swizzle_size,
            self.raster_order,
            max_active_clusters,
        )

        # Define shared storage for kernel
        @cute.struct
        class SharedStorage:
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage * 2]
            acc_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_acc_stage * 2
            ]
            tmem_dealloc_mbar: cutlass.Int64
            tmem_holding_buf: cutlass.Int32

        self.shared_storage = SharedStorage

        # Launch the kernel synchronously
        self.kernel(
            tiled_mma=tiled_mma,
            tma_atom_a=tma_atom_a,
            mA_mkl=tma_tensor_a,
            tma_atom_b=tma_atom_b,
            mB_nkl=tma_tensor_b,
            tma_atom_c=tma_atom_c,
            mC_mnl=(tma_tensor_c if self.use_tma_store else c),
            mCommInMC_mnl=comm_in_multicast_tensor,
            mCommOutMC_mnl=comm_out_multicast_tensor,
            barrier_flag_unicast=barrier_flag_unicast,
            barrier_flag_multicast=barrier_flag_multicast,
            cluster_layout_vmnk=self.cluster_layout_vmnk,
            a_smem_layout_staged=self.a_smem_layout_staged,
            b_smem_layout_staged=self.b_smem_layout_staged,
            c_smem_layout_staged=self.c_smem_layout_staged,
            epi_tile=self.epi_tile,
            tile_sched_params=self.tile_sched_params,
            epilogue_op=epilogue_op,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            stream=stream,
        )
        return

    # GPU device kernel
    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_c: Optional[cute.CopyAtom],
        mC_mnl: cute.Tensor,
        mCommInMC_mnl: cute.Tensor,
        mCommOutMC_mnl: cute.Tensor,
        barrier_flag_unicast: cute.Tensor,
        barrier_flag_multicast: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout, None],
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        epilogue_op: cutlass.Constexpr,
    ):
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        #
        # Prefetch tma desc
        #
        if warp_idx == self.tma_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            if cutlass.const_expr(self.use_tma_store):
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
        ab_producer, ab_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_pipeline_producer_group,
            consumer_group=ab_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
            cta_layout_vmnk=cluster_layout_vmnk,
            enable_multicast_signaling=True,
            defer_sync=True,
        ).make_participants()

        # Initialize acc_pipeline (barrier) and states
        acc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_acc_consumer_threads = len(self.epilogue_warp_id) * (
            2 if use_2cta_instrs else 1
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

        tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=self.tmem_alloc_sync_bar_id,
            num_threads=32 * len((self.mma_warp_id, *self.epilogue_warp_id)),
        )
        tmem_dealloc_barrier = None
        if cutlass.const_expr(not self.use_tma_store):
            tmem_dealloc_barrier = pipeline.NamedBarrier(
                barrier_id=self.tmem_dealloc_sync_bar_id,
                num_threads=32 * len(self.epilogue_warp_id),
            )
        # Tensor memory dealloc barrier init
        tmem = utils.TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=tmem_alloc_barrier,
            allocator_warp_id=self.epilogue_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar.ptr,
        )

        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=self.cluster_shape_mn, is_relaxed=True)

        #
        # Setup smem tensor A/B/C
        #
        # (MMA, MMA_M, MMA_K, STAGE)
        sA = smem.allocate_tensor(
            element_type=self.a_dtype,
            layout=a_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=a_smem_layout_staged.inner,
        )
        # (MMA, MMA_N, MMA_K, STAGE)
        sB = smem.allocate_tensor(
            element_type=self.b_dtype,
            layout=b_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=b_smem_layout_staged.inner,
        )

        #
        # Compute multicast mask for A/B buffer full
        #
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        if cutlass.const_expr(self.is_a_mcast or self.is_b_mcast or use_2cta_instrs):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
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
        # (bM, bN, RestM, RestN, RestL)
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )
        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        #
        # Partition global tensor for TiledMMA_A/B/C
        #
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        # (MMA, MMA_M, MMA_K, RestM, RestK, RestL)
        tCgA = thr_mma.partition_A(gA_mkl)
        # (MMA, MMA_N, MMA_K, RestN, RestK, RestL)
        tCgB = thr_mma.partition_B(gB_nkl)
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
        # ((atom_v, rest_v), RestM, RestK, RestL)
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB, 0, 3),
            cute.group_modes(tCgB, 0, 3),
        )

        #
        # Partition shared/tensor memory tensor for TiledMMA_A/B/C
        #
        # (MMA, MMA_M, MMA_K, STAGE)
        tCrA = tiled_mma.make_fragment_A(sA)
        # (MMA, MMA_N, MMA_K, STAGE)
        tCrB = tiled_mma.make_fragment_B(sB)
        # (MMA, MMA_M, MMA_N)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        # (MMA, MMA_M, MMA_N, STAGE)
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )

        #
        # Cluster wait before tensor memory alloc
        #
        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        #
        # Construct the scheduler
        #
        tile_sched = utils.StaticPersistentTileScheduler.create(
            tile_sched_params,
            cute.arch.block_idx(),
            cute.arch.grid_dim(),
        )
        work_tile = tile_sched.initial_work_tile_info()

        #
        # Specialized TMA load warp
        #

        if warp_idx == self.tma_warp_id:
            #
            # Persistent tile scheduling loop
            #
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

                # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt
                ab_producer.reset()
                peek_ab_empty_status = ab_producer.try_acquire()

                #
                # Tma load loop
                #
                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    # Conditionally wait for AB buffer empty
                    handle = ab_producer.acquire_and_advance(peek_ab_empty_status)

                    # TMA load A/B
                    cute.copy(
                        tma_atom_a,
                        tAgA_slice[(None, handle.count)],
                        tAsA[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        mcast_mask=a_full_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_slice[(None, handle.count)],
                        tBsB[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        mcast_mask=b_full_mcast_mask,
                    )

                    # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt + k_tile + 1
                    peek_ab_empty_status = cutlass.Boolean(1)
                    if handle.count + 1 < k_tile_cnt:
                        peek_ab_empty_status = ab_producer.try_acquire()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Wait A/B buffer empty
            #
            ab_producer.tail()

        #
        # Specialized MMA warp
        #
        if warp_idx == self.mma_warp_id:
            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

            #
            # Persistent tile scheduling loop
            #
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

                # Set tensor memory buffer for current tile
                # (MMA, MMA_M, MMA_N)
                tCtAcc = tCtAcc_base[(None, None, None, acc_producer_state.index)]

                # Peek (try_wait) AB buffer full for k_tile = 0
                ab_consumer.reset()
                peek_ab_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    peek_ab_full_status = ab_consumer.try_wait()

                #
                # Wait for accumulator buffer empty
                #
                if is_leader_cta:
                    acc_pipeline.producer_acquire(acc_producer_state)

                #
                # Mma mainloop
                #
                for k_tile in range(k_tile_cnt):
                    if is_leader_cta:
                        # Conditionally wait for AB buffer full
                        handle = ab_consumer.wait_and_advance(peek_ab_full_status)

                        # tCtAcc += tCrA * tCrB
                        tiled_mma.set(tcgen05.Field.ACCUMULATE, k_tile != 0)
                        tile_crd = (None, None, None, handle.index)
                        cute.gemm(
                            tiled_mma, tCtAcc, tCrA[tile_crd], tCrB[tile_crd], tCtAcc
                        )

                        # Async arrive AB buffer empty
                        handle.release()

                        # Peek (try_wait) AB buffer full for k_tile = k_tile + 1
                        peek_ab_full_status = cutlass.Boolean(1)
                        if handle.count + 1 < k_tile_cnt:
                            peek_ab_full_status = ab_consumer.try_wait()

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

        sC = None
        if cutlass.const_expr(self.use_tma_store):
            # (EPI_TILE_M, EPI_TILE_N, STAGE)
            sC = smem.allocate_tensor(
                element_type=self.c_dtype,
                layout=c_smem_layout_staged.outer,
                byte_alignment=128,
                swizzle=c_smem_layout_staged.inner,
            )

        #
        # Specialized epilogue warps
        #
        if warp_idx < self.mma_warp_id:
            #
            # Alloc tensor memory buffer
            #
            tmem.allocate(self.num_tmem_alloc_cols)

            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

            m_cta_tiles_in_total = gC_mnl.shape[2] * cute.size(tiled_mma.thr_id.shape)
            n_cta_tiles_in_total = gC_mnl.shape[3]

            #
            # Persistent tile scheduling loop for epilogue
            #
            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )
            if cutlass.const_expr(self.use_tma_store):
                assert tma_atom_c is not None and sC is not None
                c_producer_group = pipeline.CooperativeGroup(
                    pipeline.Agent.Thread,
                    32 * len(self.epilogue_warp_id),
                )
                c_pipeline = pipeline.PipelineTmaStore.create(
                    num_stages=self.num_c_stage, producer_group=c_producer_group
                )

            epilogue_sync_barrier = pipeline.NamedBarrier(
                barrier_id=self.epilog_sync_bar_id,
                num_threads=32 * len(self.epilogue_warp_id),
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
                # Pre-advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

                num_tiles_executed = tile_sched.num_tiles_executed
                if cutlass.const_expr(self.use_tma_store):
                    acc_consumer_state = utils.gemm.sm100.epilogue_tma_store(
                        self,
                        tidx,
                        warp_idx,
                        tma_atom_c,
                        tCtAcc_base,
                        sC,
                        tCgC,
                        epi_tile,
                        num_tiles_executed,
                        epilogue_op,
                        mma_tile_coord_mnl,
                        acc_consumer_state,
                        acc_pipeline,
                        c_pipeline,
                    )

                    # Post-epilogue: arrive flag for distributed communication
                    if cutlass.const_expr(self.all_reduce == "LDMCxSTMC"):
                        # 1D linear index of current output tile
                        cta_tile_id_linear = cute.Int32(
                            cur_tile_coord[0] + cur_tile_coord[1] * m_cta_tiles_in_total
                        )

                        # Wait for C store complete
                        # Unlike regular epilogue where we only wait C store complete once at end of each kernel.
                        # Here we need to wait for C store complete for each output tile before we set the release flag.
                        c_pipeline.producer_tail()

                        # Update flag with release semantic with GPU scope
                        if warp_idx == self.epilogue_warp_id[0]:
                            with cute.arch.elect_one():
                                flag_curr_tile = (
                                    barrier_flag_multicast.iterator + cta_tile_id_linear
                                )
                                # Release flag MUST be `release` semantic
                                # Refer to CUDA PTX doc Memory Consistency Model for more detail
                                utils.distributed.multimem_red_add1(
                                    lock_ptr=flag_curr_tile,
                                    order="release",
                                    scope="gpu",
                                )
                else:
                    acc_consumer_state = utils.gemm.sm100.epilogue(
                        self,
                        tidx,
                        tCtAcc_base,
                        tCgC,
                        epi_tile,
                        epilogue_op,
                        mma_tile_coord_mnl,
                        acc_consumer_state,
                        acc_pipeline,
                    )

                    # Post-epilogue: arrive flag for distributed communication
                    if cutlass.const_expr(self.all_reduce == "LDMCxSTMC"):
                        # 1D linear index of current output tile
                        cta_tile_id_linear = cute.Int32(
                            cur_tile_coord[0] + cur_tile_coord[1] * m_cta_tiles_in_total
                        )

                        # Sync all thread in epilogue warp
                        # Ensure all thread in epilogue warp have issue store operation
                        epilogue_sync_barrier.arrive_and_wait()

                        # Update flag with release semantic with GPU scope
                        if warp_idx == self.epilogue_warp_id[0]:
                            with cute.arch.elect_one():
                                flag_curr_tile = (
                                    barrier_flag_multicast.iterator + cta_tile_id_linear
                                )
                                # Release flag MUST be `release` semantic
                                # Refer to CUDA PTX doc Memory Consistency Model for more detail
                                utils.distributed.multimem_red_add1(
                                    lock_ptr=flag_curr_tile,
                                    order="release",
                                    scope="gpu",
                                )

            if cutlass.const_expr(self.use_tma_store):
                # Wait for C store complete (only if not using LDMCxSTMC which does per-tile tail)
                if cutlass.const_expr(self.all_reduce != "LDMCxSTMC"):
                    c_pipeline.producer_tail()
            else:
                # Synchronize before TMEM dealloc
                if cutlass.const_expr(self.all_reduce != "LDMCxSTMC"):
                    tmem_dealloc_barrier.arrive_and_wait()

            #
            # Dealloc the tensor memory buffer
            #
            tmem.relinquish_alloc_permit()
            tmem.free(tmem_ptr)

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

                m_cta_tiles_in_total = gCommInMC_mnl.shape[2] * cute.size(
                    tiled_mma.thr_id.shape
                )
                n_cta_tiles_in_total = gCommInMC_mnl.shape[3]

                #
                # Persistent tile scheduling loop for all reduce
                #
                comm_sync_barrier = pipeline.NamedBarrier(
                    barrier_id=self.comm_sync_bar_id,
                    num_threads=32 * len(self.comm_warp_id),
                )

                # AllReduce communication pattern (w/ rank4 as example):
                #
                # [rank0 A] [rank1 A] [rank2 A] [rank3 A] -> RS -> [rank0+1+2+3 A] [rank0+1+2+3 A] [rank0+1+2+3 A] [rank0+1+2+3 A]
                # [rank0 B] [rank1 B] [rank2 B] [rank3 B] -> RS -> [rank0+1+2+3 B] [rank0+1+2+3 B] [rank0+1+2+3 B] [rank0+1+2+3 B]
                # [rank0 C] [rank1 C] [rank2 C] [rank3 C] -> RS -> [rank0+1+2+3 C] [rank0+1+2+3 C] [rank0+1+2+3 C] [rank0+1+2+3 C]
                # [rank0 D] [rank1 D] [rank2 D] [rank3 D] -> RS -> [rank0+1+2+3 D] [rank0+1+2+3 D] [rank0+1+2+3 D] [rank0+1+2+3 D]
                # rank0     rank1     rank2     rank3     -> RS -> rank0           rank1            rank2          rank3
                #
                # Each rank's AR warp only handle 1/P of overall output tiles, and relies on other rank to broadcast data to it
                #   rank0: compute each tile's [0:1/4] and broadcast it to all rank
                #   rank1: compute each tile's [1/4:2:4] and broadcast it to all rank

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
                # This ensure
                # 1. no rank early exit while other ranks are still issuing multimem.ld_reduce
                # 2. each rank's prior multimem.st have become visible to all other ranks in the system (w/ .SYS scope)
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

    @staticmethod
    def _compute_stages(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: Tuple[int, int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        smem_capacity: int,
        occupancy: int,
        use_tma_store: bool,
        c_smem_layout: Union[cute.Layout, None],
    ) -> Tuple[int, int, int]:
        # Default ACC stages
        num_acc_stage = 2

        # Default C stages
        num_c_stage = 2 if use_tma_store else 0

        # Calculate smem layout and size for one stage of A, B, and C with 1-stage
        a_smem_layout_stage_one = utils.sm100.make_smem_layout_a(
            tiled_mma, mma_tiler_mnk, a_dtype, 1
        )
        b_smem_layout_staged_one = utils.sm100.make_smem_layout_b(
            tiled_mma, mma_tiler_mnk, b_dtype, 1
        )

        ab_bytes_per_stage = cute.size_in_bytes(
            a_dtype, a_smem_layout_stage_one
        ) + cute.size_in_bytes(b_dtype, b_smem_layout_staged_one)
        mbar_helpers_bytes = 1024

        c_bytes_per_stage = cute.size_in_bytes(c_dtype, c_smem_layout)
        c_bytes = c_bytes_per_stage * num_c_stage

        # Calculate A/B stages:
        # Start with total smem per CTA (capacity / occupancy)
        # Subtract reserved bytes and initial C stages bytes
        # Divide remaining by bytes needed per A/B stage
        num_ab_stage = (
            smem_capacity // occupancy - (mbar_helpers_bytes + c_bytes)
        ) // ab_bytes_per_stage

        # Refine epilogue stages:
        # Calculate remaining smem after allocating for A/B stages and reserved bytes
        # Add remaining unused smem to epilogue
        if use_tma_store:
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
    def _compute_num_tmem_alloc_cols(
        tiled_mma: cute.TiledMma,
        mma_tiler: Tuple[int, int, int],
        num_acc_stage: int,
        arch: str,
    ) -> int:
        acc_shape = tiled_mma.partition_shape_C(mma_tiler[:2])
        tCtAcc_fake = tiled_mma.make_fragment_C(cute.append(acc_shape, num_acc_stage))
        num_tmem_alloc_cols = utils.get_num_tmem_alloc_cols(tCtAcc_fake, arch=arch)

        return num_tmem_alloc_cols

    def check_supported_dtypes(
        self, ab_dtype: Type[cutlass.Numeric], c_dtype: Type[cutlass.Numeric]
    ) -> bool:
        valid_ab_dtypes = {
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.TFloat32,
            cutlass.Uint8,
            cutlass.Int8,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        }
        if ab_dtype not in valid_ab_dtypes:
            raise testing.CantImplementError(
                f"[dtype] Unsupported AB dtype: {ab_dtype}"
            )

        valid_acc_dtypes = {cutlass.Float32, cutlass.Float16, cutlass.Int32}
        if self.acc_dtype not in valid_acc_dtypes:
            raise testing.CantImplementError(
                f"[dtype] Unsupported accumulator dtype: {self.acc_dtype}"
            )

        # Define compatibility mapping between accumulator type and AB type
        acc_ab_compatibility = {
            cutlass.Float32: {
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.TFloat32,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },  # Float32 accumulator supports floating point AB types only
            cutlass.Float16: {
                cutlass.Float16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },
            cutlass.Int32: {cutlass.Uint8, cutlass.Int8},
        }
        # Check compatibility between accumulator type and AB type
        if ab_dtype not in acc_ab_compatibility[self.acc_dtype]:
            raise testing.CantImplementError(
                f"[dtype] Unsupported AB dtype {ab_dtype} for accumulator {self.acc_dtype}"
            )

        # Define compatibility mapping between accumulator type and C type
        acc_c_compatibility = {
            cutlass.Float32: {
                cutlass.Float32,
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
                cutlass.Int32,
                cutlass.Int8,
                cutlass.Uint8,
            },
            cutlass.Float16: {
                cutlass.BFloat16,
                cutlass.Float16,
            },
            cutlass.Int32: {
                cutlass.BFloat16,
                cutlass.Float16,
                cutlass.Float32,
                cutlass.Int32,
                cutlass.Int8,
                cutlass.Uint8,
            },
        }
        # Check compatibility between accumulator type and C type
        if c_dtype not in acc_c_compatibility[self.acc_dtype]:
            raise testing.CantImplementError(
                f"[dtype] Unsupported C dtype {c_dtype} for accumulator {self.acc_dtype}"
            )

        # check if c_dtype is supported by multimem all-reduce
        if cutlass.const_expr(
            c_dtype
            not in {
                cutlass.Float16,
                cutlass.Float32,
                cutlass.BFloat16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            }
        ):
            raise testing.CantImplementError(
                f"[dtype] Unsupported C dtype {c_dtype} for multimem all-reduce"
            )

        return True

    def check_mma_tiler_and_cluster_shape(self) -> bool:
        # Skip invalid mma tile shape
        # 1SM: MMA tile {64, 128} x {64, 128, 192, 256}
        # 2SM: MMA tile {128, 256} x {64, 128, 192, 256}
        valid_mma_m = [64, 128] if not self.use_2cta_instrs else [128, 256]
        valid_mma_n = [64, 128, 192, 256]
        if self.mma_tiler_mn[0] not in valid_mma_m:
            raise testing.CantImplementError(
                f"[mma_tile] Invalid mma tiler M: {self.mma_tiler_mn[0]}, expected {valid_mma_m} for {'1SM' if not self.use_2cta_instrs else '2SM'}"
            )
        if self.mma_tiler_mn[1] not in valid_mma_n:
            raise testing.CantImplementError(
                f"[mma_tile] Invalid mma tiler N: {self.mma_tiler_mn[1]}, expected {valid_mma_n}"
            )
        # Skip illegal cluster shape
        if self.cluster_shape_mn[0] % (2 if self.use_2cta_instrs else 1) != 0:
            raise testing.CantImplementError(
                f"[cluster] Invalid cluster shape M: {self.cluster_shape_mn[0]}, must be multiple of {2 if self.use_2cta_instrs else 1} for {'2SM' if self.use_2cta_instrs else '1SM'}"
            )
        # Skip invalid cluster shape
        is_power_of_2 = lambda x: x > 0 and (x & (x - 1)) == 0
        if (
            self.cluster_shape_mn[0] * self.cluster_shape_mn[1] > 16
            or self.cluster_shape_mn[0] <= 0
            or self.cluster_shape_mn[1] <= 0
            or not is_power_of_2(self.cluster_shape_mn[0])
            or not is_power_of_2(self.cluster_shape_mn[1])
        ):
            raise testing.CantImplementError(
                f"[cluster] Invalid cluster shape: {self.cluster_shape_mn}, must be positive power of 2 with total <= 16"
            )
        return True

    def check_tensor_alignment(
        self,
        m: int,
        n: int,
        k: int,
        l: int,
        ab_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: Literal["k", "m"],
        b_major: Literal["k", "n"],
        c_major: Literal["n", "m"],
    ) -> bool:
        def check_contiguous_16B_alignment(dtype, is_mode0_major, tensor_shape):
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            num_contiguous_elements = 16 * 8 // dtype.width
            return num_major_elements % num_contiguous_elements == 0

        if (
            not check_contiguous_16B_alignment(ab_dtype, a_major == "m", (m, k, l))
            or not check_contiguous_16B_alignment(ab_dtype, b_major == "n", (n, k, l))
            or not check_contiguous_16B_alignment(c_dtype, c_major == "m", (m, n, l))
        ):
            raise testing.CantImplementError(
                f"[alignment] Invalid tensor alignment: contiguous dimension must be 16B aligned for (M={m}, K={k}, N={n})"
            )

        if m % 128 != 0 and n % 128 != 0:
            raise testing.CantImplementError(
                f"[alignment] Invalid tensor alignment: at least one of M={m} or N={n} must be divisible by 128"
            )

        if a_major not in ["m", "k"]:
            raise testing.CantImplementError(
                f"[alignment] Invalid a_major: {a_major}, expected 'm' or 'k'"
            )
        if b_major not in ["n", "k"]:
            raise testing.CantImplementError(
                f"[alignment] Invalid b_major: {b_major}, expected 'n' or 'k'"
            )
        if c_major not in ["m", "n"]:
            raise testing.CantImplementError(
                f"[alignment] Invalid c_major: {c_major}, expected 'm' or 'n'"
            )

        return True

    def check_epilogue_store_option(self, m: int, n: int) -> bool:
        # Non TMA store version does not have predication, can not support OOB tiles
        cta_tile_shape_mn = (
            self.mma_tiler_mn[0] // (2 if self.use_2cta_instrs else 1),
            self.mma_tiler_mn[1],
        )
        if not self.use_tma_store:
            if not (m % cta_tile_shape_mn[0] == 0 and n % cta_tile_shape_mn[1] == 0):
                raise testing.CantImplementError(
                    f"[epilogue] Problem shape (M={m}, N={n}) must be divisible by cta tile shape {cta_tile_shape_mn} for non TMA store"
                )
            # CTA swizzling improves the L2 cache utilization and reduces the number of cache misses.
            # Make sure the swizzle size divides the cta/cluster count since non TMA epilogue don't support OOB tiles.
            # Swizzle only applies to the dimension orthogonal to the raster direction.
            m_per_swizzle = (m // cta_tile_shape_mn[0]) // self.cluster_shape_mn[0]
            n_per_swizzle = (n // cta_tile_shape_mn[1]) // self.cluster_shape_mn[1]
            if self.raster_order == "m":
                # Swizzle applies to N dimension only
                if n_per_swizzle % self.swizzle_size != 0:
                    raise testing.CantImplementError(
                        f"[epilogue] Problem shape n={n} must be divisible by swizzle size {self.swizzle_size} for non TMA store with raster_order_m"
                    )
            else:
                # Swizzle applies to M dimension only
                if m_per_swizzle % self.swizzle_size != 0:
                    raise testing.CantImplementError(
                        f"[epilogue] Problem shape m={m} must be divisible by swizzle size {self.swizzle_size} for non TMA store with raster_order_n"
                    )
        return True

    def check_valid_rank_config(self) -> bool:
        if self.num_ranks not in [2, 4, 8] and self.all_reduce != "none":
            raise testing.CantImplementError(
                f"[rank_config] Invalid rank config: num_ranks={self.num_ranks}, must be 2, 4, or 8 for all-reduce"
            )
        return True

    def check_valid_all_reduce_mode(self) -> bool:
        if self.all_reduce not in ["LDMCxSTMC", "none"]:
            raise testing.CantImplementError(
                f"[all_reduce_mode] Invalid all-reduce mode: {self.all_reduce}, expected 'LDMCxSTMC' or 'none'"
            )
        return True

    def check_even_divisiable_by_cluster_tilesize(
        self, m: int, n: int, k: int, l: int
    ) -> bool:
        cta_tile_m = self.mma_tiler_mn[0] // (2 if self.use_2cta_instrs else 1)
        cta_tile_n = self.mma_tiler_mn[1]

        cluster_shape_m = self.cluster_shape_mn[0]
        cluster_shape_n = self.cluster_shape_mn[1]

        cluster_tile_m = cta_tile_m * cluster_shape_m
        cluster_tile_n = cta_tile_n * cluster_shape_n

        if m % cluster_tile_m != 0 or n % cluster_tile_n != 0:
            raise testing.CantImplementError(
                f"[problem_size_divisible_cluster_tile_size] Problem shape (M={m}, N={n}) not divisible by cluster tile size ({cluster_tile_m}, {cluster_tile_n})"
            )
        return True

    def check_even_divisible_by_swizzle(self, m: int, n: int) -> bool:
        # Only check for LDMCxSTMC mode which uses multimem operations
        if self.all_reduce != "LDMCxSTMC":
            return True

        cta_tile_m = self.mma_tiler_mn[0] // (2 if self.use_2cta_instrs else 1)
        cta_tile_n = self.mma_tiler_mn[1]

        # Number of clusters in each dimension
        num_clusters_m = m // (cta_tile_m * self.cluster_shape_mn[0])
        num_clusters_n = n // (cta_tile_n * self.cluster_shape_mn[1])

        if self.raster_order == "m":
            # Swizzle applies to N dimension only
            if num_clusters_n % self.swizzle_size != 0:
                raise testing.CantImplementError(
                    f"[problem_size_divisible_swizzle_size] Number of clusters in N dimension ({num_clusters_n}) "
                    f"must be divisible by swizzle_size={self.swizzle_size} for LDMCxSTMC with raster_order_m"
                )
        else:
            # Swizzle applies to M dimension only
            if num_clusters_m % self.swizzle_size != 0:
                raise testing.CantImplementError(
                    f"[problem_size_divisible_swizzle_size] Number of clusters in M dimension ({num_clusters_m}) "
                    f"must be divisible by swizzle_size={self.swizzle_size} for LDMCxSTMC with raster_order_n"
                )

        return True

    def can_implement(
        self,
        mnkl: Tuple[int, int, int, int],
        ab_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: Literal["k", "m"],
        b_major: Literal["k", "n"],
        c_major: Literal["n", "m"],
    ) -> bool:
        # Skip unsupported types
        self.check_supported_dtypes(ab_dtype, c_dtype)

        # Skip invalid mma tile shape and cluster shape
        self.check_mma_tiler_and_cluster_shape()

        # Unpack mnkl for clarity in calling the epilog check
        m, n, k, l = mnkl

        # Skip if GEMM not even divisiable by tilesize
        # Right now, AR Fusion **ONLY** support even divisiable by tilesize
        self.check_even_divisiable_by_cluster_tilesize(m, n, k, l)

        # Skip if swizzle doesn't evenly divide the problem (for LDMCxSTMC communication)
        self.check_even_divisible_by_swizzle(m, n)

        # Skip illegal problem shape for load/store alignment
        self.check_tensor_alignment(
            m, n, k, l, ab_dtype, c_dtype, a_major, b_major, c_major
        )

        # Skip invalid epilogue store option
        self.check_epilogue_store_option(m, n)

        # Skip invalid all-reduce rank config
        self.check_valid_rank_config()

        # Skip invalid all-reduce mode
        self.check_valid_all_reduce_mode()

        return True


#####################################################################
#### KERNEL IMPLEMENTATION END HERE ####
#####################################################################

_DISTRIBUTED_INITIALIZED = False


# Check for device p2p access
def check_cuda_p2p_access():
    num_devices = torch.cuda.device_count()
    for i in range(num_devices - 1):
        for j in range(i + 1, num_devices):
            if not torch.cuda.can_device_access_peer(i, j):
                return False
    return True


# Check for multicast support
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
        # * Check before running *
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

        # LOCAL_RANK = which of this host's GPUs we bind to.
        # RANK       = global identity across all hosts; used for NCCL init
        #              and for kernel rank_id (slab ownership in the AR).
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

    # Return the GLOBAL rank — callers feed this into kernel rank_id.
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


# ---------------------------------------------------------------------------
# Dump / Load helpers for determinism verification
# ---------------------------------------------------------------------------


def _make_tensor_filename(
    local_rank, global_rank, world_size, hostname, name, tensor
) -> str:
    dtype_str = str(tensor.dtype).replace("torch.", "")
    shape_str = "x".join(str(d) for d in tensor.shape)
    return (
        f"rank{local_rank}_global{global_rank}_world{world_size}"
        f"_{hostname}_{name}_{dtype_str}_{shape_str}.pt"
    )


def _dump_tensors(
    dump_dir, local_rank, global_rank, world_size, hostname, named_tensors: dict
):
    os.makedirs(dump_dir, exist_ok=True)
    for name, tensor in named_tensors.items():
        fname = _make_tensor_filename(
            local_rank, global_rank, world_size, hostname, name, tensor
        )
        torch.save(tensor, os.path.join(dump_dir, fname))


def _write_metadata_json(
    dump_dir,
    global_rank,
    world_size,
    mnkl,
    ab_dtype,
    c_dtype,
    acc_dtype,
    a_major,
    b_major,
    c_major,
):
    """ALL ranks call this (for all_gather_object). Only rank 0 writes the file."""
    hostnames = [None] * world_size
    dist.all_gather_object(hostnames, socket.gethostname())
    if global_rank == 0:
        os.makedirs(dump_dir, exist_ok=True)
        meta = {
            "mnkl": list(mnkl),
            "world_size": world_size,
            "ab_dtype": ab_dtype.__name__,
            "c_dtype": c_dtype.__name__,
            "acc_dtype": acc_dtype.__name__,
            "a_major": a_major,
            "b_major": b_major,
            "c_major": c_major,
            "hostnames": hostnames,
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
        }
        with open(os.path.join(dump_dir, "metadata.json"), "w") as f:
            json.dump(meta, f, indent=2)


def _load_input_tensors(
    load_dir,
    local_rank,
    global_rank,
    world_size,
    ab_dtype,
    expected_shape_a,
    expected_shape_b,
):
    """Load A and B for this rank from dump dir. Validates dtype and shape."""
    expected_torch_dtype = torch_dtype(ab_dtype)

    def _load_one(name, expected_shape):
        pattern = os.path.join(
            load_dir,
            f"rank*_global{global_rank}_world{world_size}_*_{name}_*.pt",
        )
        matches = glob.glob(pattern)
        if len(matches) == 0:
            raise FileNotFoundError(f"[load_input] No file for {name}: {pattern}")
        if len(matches) > 1:
            raise RuntimeError(
                f"[load_input] Multiple files matched for {name}: {matches}"
            )
        tensor = torch.load(matches[0], weights_only=True)
        if tensor.dtype != expected_torch_dtype:
            raise ValueError(
                f"[load_input] dtype mismatch for {name}: got {tensor.dtype}, "
                f"expected {expected_torch_dtype}"
            )
        if tuple(tensor.shape) != tuple(expected_shape):
            raise ValueError(
                f"[load_input] shape mismatch for {name}: got {tuple(tensor.shape)}, "
                f"expected {tuple(expected_shape)}"
            )
        return tensor

    torch_tensor_a_cpu = _load_one("a", expected_shape_a)
    torch_tensor_b_cpu = _load_one("b", expected_shape_b)
    return torch_tensor_a_cpu, torch_tensor_b_cpu


def allocate_tensors(
    *,
    mnkl: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    a_major: Literal["k", "m"],
    b_major: Literal["k", "n"],
    c_major: Literal["n", "m"],
    num_workspace: int,
    device: int,
    slot_init_mode: Literal["test", "benchmark"],
    global_rank: int = 0,
    local_rank: int = 0,
    world_size: int = 1,
    load_input_dir: Optional[str] = None,
):
    _init_lo, _init_hi = (-5, 5) if slot_init_mode == "test" else (-20, 20)

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

    m, n, k, l = mnkl

    if load_input_dir is not None:
        # k-major A stored as (m,k,l); m-major A stored as (l,m,k) — same as cutlass_torch.matrix permute
        expected_shape_a = (m, k, l) if a_major == "k" else (l, m, k)
        expected_shape_b = (n, k, l) if b_major == "k" else (l, n, k)
        torch_tensor_a_cpu, torch_tensor_b_cpu = _load_input_tensors(
            load_dir=load_input_dir,
            local_rank=local_rank,
            global_rank=global_rank,
            world_size=world_size,
            ab_dtype=ab_dtype,
            expected_shape_a=expected_shape_a,
            expected_shape_b=expected_shape_b,
        )
    else:
        torch.manual_seed(42 + global_rank)
        torch_tensor_a_int_cpu = cutlass_torch.matrix(
            l,
            m,
            k,
            a_major == "m",
            cutlass.Int32,
            init_type=cutlass_torch.TensorInitType.RANDOM,
            init_config=cutlass_torch.RandomInitConfig(
                min_val=_init_lo, max_val=_init_hi
            ),
        )
        torch_tensor_b_int_cpu = cutlass_torch.matrix(
            l,
            n,
            k,
            b_major == "n",
            cutlass.Int32,
            init_type=cutlass_torch.TensorInitType.RANDOM,
            init_config=cutlass_torch.RandomInitConfig(
                min_val=_init_lo, max_val=_init_hi
            ),
        )
        torch_tensor_a_cpu = torch_tensor_a_int_cpu.to(dtype=torch_dtype(ab_dtype))
        torch_tensor_b_cpu = torch_tensor_b_int_cpu.to(dtype=torch_dtype(ab_dtype))

    torch_tensor_c_int_cpu = cutlass_torch.matrix(
        l,
        m,
        n,
        c_major == "m",
        cutlass.Int32,
        init_type=cutlass_torch.TensorInitType.RANDOM,
        init_config=cutlass_torch.RandomInitConfig(min_val=_init_lo, max_val=_init_hi),
    )
    torch_tensor_comm_out_c_int_cpu = cutlass_torch.matrix(
        l,
        m,
        n,
        c_major == "m",
        cutlass.Int32,
        init_type=cutlass_torch.TensorInitType.RANDOM,
        init_config=cutlass_torch.RandomInitConfig(min_val=_init_lo, max_val=_init_hi),
    )

    torch_tensor_c_cpu = torch_tensor_c_int_cpu.to(dtype=torch_dtype(c_dtype))
    torch_tensor_comm_out_c_cpu = torch_tensor_comm_out_c_int_cpu.to(
        dtype=torch_dtype(c_dtype)
    )

    cute_tensor_a_list = []
    cute_tensor_b_list = []
    torch_tensor_a_gpu_list = []
    torch_tensor_b_gpu_list = []
    for _ in range(num_workspace):
        cute_tensor_a_i, torch_tensor_a_gpu_i = cutlass_torch.cute_tensor_like(
            torch_tensor_a_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        cute_tensor_b_i, torch_tensor_b_gpu_i = cutlass_torch.cute_tensor_like(
            torch_tensor_b_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        cute_tensor_a_list.append(cute_tensor_a_i)
        cute_tensor_b_list.append(cute_tensor_b_i)
        torch_tensor_a_gpu_list.append(torch_tensor_a_gpu_i)
        torch_tensor_b_gpu_list.append(torch_tensor_b_gpu_i)

    assert not torch.isnan(torch_tensor_a_gpu_list[0]).any()
    assert not torch.isnan(torch_tensor_b_gpu_list[0]).any()

    (
        cute_tensor_c,
        cute_tensor_comm_in_mc,
        torch_tensor_c_gpu,
    ) = _create_multicast_tensor(
        torch_tensor_ref=torch_tensor_c_cpu,
        dtype=c_dtype,
        leading_dim=(1 if c_major == "n" else 0),
    )
    (
        _cute_tensor_comm_out_uc,
        cute_tensor_comm_out_mc,
        torch_tensor_comm_out_gpu,
    ) = _create_multicast_tensor(
        torch_tensor_ref=torch_tensor_comm_out_c_cpu,
        dtype=c_dtype,
        leading_dim=(1 if c_major == "n" else 0),
    )

    # Flag tensor sized for the worst-case kernel config: smallest cta_tile is
    # 64x64, so max #tiles = (m/64) * (n/64). Pad by 160 for per-SM slots
    # (B200 has 148; 160 is a safe upper bound). The kernel resets these flags
    # internally on each launch, so a single allocation can be reused across
    # (mma_tiler, use_2cta) candidates in a benchmark sweep.
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
        "cute_tensor_a_list": cute_tensor_a_list,
        "cute_tensor_b_list": cute_tensor_b_list,
        "cute_tensor_c": cute_tensor_c,
        "cute_tensor_comm_in_mc": cute_tensor_comm_in_mc,
        "cute_tensor_comm_out_mc": cute_tensor_comm_out_mc,
        "cute_tensor_flag_unicast": cute_tensor_flag_unicast,
        "cute_tensor_flag_multicast": cute_tensor_flag_multicast,
        "torch_tensor_a_cpu": torch_tensor_a_cpu,
        "torch_tensor_b_cpu": torch_tensor_b_cpu,
        "torch_tensor_c_cpu": torch_tensor_c_cpu,
        "torch_tensor_c_gpu": torch_tensor_c_gpu,
        "torch_tensor_comm_out_gpu": torch_tensor_comm_out_gpu,
        "torch_tensor_flag_unicast": torch_tensor_flag_unicast,
        "_anchors": (
            torch_tensor_a_gpu_list,
            torch_tensor_b_gpu_list,
            torch_tensor_c_gpu,
            torch_tensor_comm_out_gpu,
            torch_tensor_flag_unicast,
            torch_tensor_flag_multicast,
            torch_flag_hdl,
        ),
    }


def run(
    mnkl: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: Literal["k", "m"],
    b_major: Literal["k", "n"],
    c_major: Literal["n", "m"],
    mma_tiler_mn: Tuple[int, int] = (256, 256),
    cluster_shape_mn: Tuple[int, int] = (2, 1),
    swizzle_size: int = 1,
    raster_order: Literal["m", "n"] = "m",
    use_2cta_instrs: bool = True,
    use_tma_store: bool = True,
    warmup_iterations: int = 0,
    iterations: int = 1,
    all_reduce: str = "LDMCxSTMC",
    benchmark_or_test: str = "test",
    use_cuda_graph: bool = False,
    csv_report: str = "./csv_report.csv",
    dump_input: Optional[str] = None,
    dump_output: Optional[str] = None,
    load_input: Optional[str] = None,
):
    # * Init Distributed *
    global_rank, world_size, device = init_distributed()

    # * Validate dump/load flags *
    if (dump_input or dump_output or load_input) and benchmark_or_test != "test":
        raise ValueError(
            "--dump_input / --dump_output / --load_input are only valid in test mode"
        )

    # * Check based on AR mode *
    if all_reduce == "LDMCxSTMC":
        if not check_cuda_p2p_access():
            print("CUDA P2P access not available")
            exit(-1)
        if not check_multicast_support():
            print("Multicast support not available")
            exit(-1)
        if not test_simple_torch_allreduce(device):
            print("Simple torch allreduce test failed")
            exit(-1)

    # * Verbose *
    def _verbose():
        print("Running Blackwell SM100 Persistent Dense GEMM AR test with:")
        print(f"mnkl: {mnkl}")
        print(f"global_rank: {global_rank}, world_size: {world_size}, device: {device}")
        print(f"AB dtype: {ab_dtype}, C dtype: {c_dtype}, Acc dtype: {acc_dtype}")
        print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
        print(f"Mma Tiler (M, N): {mma_tiler_mn}")
        print(f"Cluster Shape (M, N): {cluster_shape_mn}")
        print(f"2CTA MMA instructions: {'True' if use_2cta_instrs else 'False'}")
        print(f"Use TMA Store: {'True' if use_tma_store else 'False'}")
        print(f"Swizzle Size: {swizzle_size}")
        print(f"Raster Order: {raster_order}")
        print(f"Warmup iterations: {warmup_iterations}")
        print(f"Iterations: {iterations}")
        print(f"Use CUDA Graph: {'True' if use_cuda_graph else 'False'}")
        print(f"Mode: {benchmark_or_test}")
        print(f"Fused AllReduce Op: {all_reduce}")

    if global_rank == 0:
        _verbose()

    # * Run Distributed *
    if benchmark_or_test in ("benchmark", "benchmark_all"):
        run_distributed_benchmark(
            global_rank=global_rank,
            world_size=world_size,
            device=device,
            mnkl=mnkl,
            ab_dtype=ab_dtype,
            c_dtype=c_dtype,
            acc_dtype=acc_dtype,
            a_major=a_major,
            b_major=b_major,
            c_major=c_major,
            mma_tiler_mn=mma_tiler_mn,
            cluster_shape_mn=cluster_shape_mn,
            swizzle_size=swizzle_size,
            raster_order=raster_order,
            use_2cta_instrs=use_2cta_instrs,
            use_tma_store=use_tma_store,
            warmup_iterations=warmup_iterations,
            iterations=iterations,
            all_reduce=all_reduce,
            use_cuda_graph=use_cuda_graph,
            benchmark_all=(benchmark_or_test == "benchmark_all"),
            csv_report=csv_report,
        )
    else:
        run_distributed_test(
            global_rank=global_rank,
            world_size=world_size,
            device=device,
            mnkl=mnkl,
            ab_dtype=ab_dtype,
            c_dtype=c_dtype,
            acc_dtype=acc_dtype,
            a_major=a_major,
            b_major=b_major,
            c_major=c_major,
            mma_tiler_mn=mma_tiler_mn,
            cluster_shape_mn=cluster_shape_mn,
            swizzle_size=swizzle_size,
            raster_order=raster_order,
            use_2cta_instrs=use_2cta_instrs,
            use_tma_store=use_tma_store,
            all_reduce=all_reduce,
            dump_input=dump_input,
            dump_output=dump_output,
            load_input=load_input,
        )

    clean_distributed()


def run_distributed_test(
    global_rank: int,
    world_size: int,
    device: int,
    mnkl: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: Literal["k", "m"],
    b_major: Literal["k", "n"],
    c_major: Literal["n", "m"],
    mma_tiler_mn: Tuple[int, int] = (256, 256),
    cluster_shape_mn: Tuple[int, int] = (2, 1),
    swizzle_size: int = 1,
    raster_order: Literal["m", "n"] = "m",
    use_2cta_instrs: bool = True,
    use_tma_store: bool = True,
    all_reduce: str = "LDMCxSTMC",
    dump_input: Optional[str] = None,
    dump_output: Optional[str] = None,
    load_input: Optional[str] = None,
):
    # * CUDA *
    # Non-default stream as we'll use CUDA graphs
    torch_stream = torch.cuda.Stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)

    local_rank = int(os.environ.get("LOCAL_RANK", global_rank))
    hostname = socket.gethostname()

    # * Build GEMM AllReduce Object *
    gemm_all_reduce = Sm100PersistentDenseGemmAllReduceLDMCxSTMCKernel(
        acc_dtype,
        c_dtype,
        use_2cta_instrs,
        mma_tiler_mn,
        cluster_shape_mn,
        use_tma_store,
        rank_id=global_rank,
        num_ranks=world_size,
        all_reduce=all_reduce,
        swizzle_size=swizzle_size,
        raster_order=raster_order,
    )

    # * Set Filename & Funcname for different rank *
    # Use hash to keep filename short and avoid "File name too long" error
    try:
        import hashlib

        param_str = f"ab{ab_dtype}_acc{acc_dtype}_c{c_dtype}_{a_major}{b_major}{c_major}_tile{mma_tiler_mn[0]}x{mma_tiler_mn[1]}_cluster{cluster_shape_mn[0]}x{cluster_shape_mn[1]}_{'2Sm' if use_2cta_instrs else '1Sm'}_{'EpiTma' if use_tma_store else 'EpiStg'}"
        param_hash = hashlib.md5(param_str.encode()).hexdigest()[:8]
        unique_name = (
            f"sm100_gemm_ar_{param_hash}_{all_reduce}_r{global_rank}_w{world_size}"
        )
    except Exception:
        unique_name = f"sm100_gemm_ar_{all_reduce}_r{global_rank}_w{world_size}"
    gemm_all_reduce.__call__.set_name_prefix(unique_name)

    # * can_implement *
    can_implement = gemm_all_reduce.can_implement(
        mnkl, ab_dtype, c_dtype, a_major, b_major, c_major
    )
    if not can_implement:
        raise testing.CantImplementError(
            f"[general] The current config is invalid/unsupported: use_2cta_instrs={use_2cta_instrs}, "
            f"mma_tiler_mn={mma_tiler_mn}, cluster_shape_mn={cluster_shape_mn}, "
            f"use_tma_store={use_tma_store}, all_reduce={all_reduce}, world_size={world_size}, "
            f"ab_dtype={ab_dtype}, c_dtype={c_dtype}, acc_dtype={acc_dtype}"
        )

    # * Allocate tensors *
    tensors = allocate_tensors(
        mnkl=mnkl,
        ab_dtype=ab_dtype,
        c_dtype=c_dtype,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
        num_workspace=1,
        device=device,
        slot_init_mode="test",
        global_rank=global_rank,
        local_rank=local_rank,
        world_size=world_size,
        load_input_dir=load_input,
    )
    cute_tensor_a = tensors["cute_tensor_a_list"][0]
    cute_tensor_b = tensors["cute_tensor_b_list"][0]
    cute_tensor_c = tensors["cute_tensor_c"]
    cute_tensor_comm_in_mc = tensors["cute_tensor_comm_in_mc"]
    cute_tensor_comm_out_mc = tensors["cute_tensor_comm_out_mc"]
    cute_tensor_flag_unicast = tensors["cute_tensor_flag_unicast"]
    cute_tensor_flag_multicast = tensors["cute_tensor_flag_multicast"]
    torch_tensor_a_cpu = tensors["torch_tensor_a_cpu"]
    torch_tensor_b_cpu = tensors["torch_tensor_b_cpu"]
    torch_tensor_c = tensors["torch_tensor_c_gpu"]
    torch_tensor_comm_out = tensors["torch_tensor_comm_out_gpu"]
    torch_tensor_flag_unicast = tensors["torch_tensor_flag_unicast"]

    # * Dump input (before compile/run) *
    if dump_input is not None:
        _dump_tensors(
            dump_input,
            local_rank,
            global_rank,
            world_size,
            hostname,
            {"a": torch_tensor_a_cpu, "b": torch_tensor_b_cpu},
        )
        _write_metadata_json(
            dump_input,
            global_rank,
            world_size,
            mnkl,
            ab_dtype,
            c_dtype,
            acc_dtype,
            a_major,
            b_major,
            c_major,
        )

    # * Compile *
    compiled_gemm = cute.compile(
        gemm_all_reduce,
        a=cute_tensor_a,
        b=cute_tensor_b,
        c=cute_tensor_c,
        comm_in_multicast_tensor=cute_tensor_comm_in_mc,
        comm_out_multicast_tensor=cute_tensor_comm_out_mc,
        barrier_flag_unicast=cute_tensor_flag_unicast,
        barrier_flag_multicast=cute_tensor_flag_multicast,
        stream=stream,
        max_active_clusters=utils.HardwareInfo().get_max_active_clusters(
            cluster_shape_mn[0] * cluster_shape_mn[1]
        ),
    )

    # * Run *
    compiled_gemm(
        a=cute_tensor_a,
        b=cute_tensor_b,
        c=cute_tensor_c,
        comm_in_multicast_tensor=cute_tensor_comm_in_mc,
        comm_out_multicast_tensor=cute_tensor_comm_out_mc,
        barrier_flag_unicast=cute_tensor_flag_unicast,
        barrier_flag_multicast=cute_tensor_flag_multicast,
        stream=stream,
    )

    # * Dump output (before compare — _compare_comm mutates C in-place for n-major) *
    torch_stream.synchronize()
    if dump_output is not None:
        _dump_tensors(
            dump_output,
            local_rank,
            global_rank,
            world_size,
            hostname,
            {"c": torch_tensor_c.cpu(), "comm_out": torch_tensor_comm_out.cpu()},
        )
        _write_metadata_json(
            dump_output,
            global_rank,
            world_size,
            mnkl,
            ab_dtype,
            c_dtype,
            acc_dtype,
            a_major,
            b_major,
            c_major,
        )

    # * Compare *
    # FP8 nan to saturate
    def _fp8_nan_to_saturate(tensor_fp8: torch.Tensor) -> torch.Tensor:
        if tensor_fp8.dtype == torch.float8_e4m3fn:
            # Map to u8 raw tensor for easier byte handle
            tensor_u8 = tensor_fp8.view(torch.uint8)
            # pos & neg nan
            is_pos_nan = tensor_u8 == 0x7F
            is_neg_nan = tensor_u8 == 0xFF
            # Map pos nan to max, neg nan to min
            tensor_f32 = tensor_fp8.to(dtype=torch.float32)
            tensor_f32[is_pos_nan] = 448
            tensor_f32[is_neg_nan] = -448
            # Cast back to f8
            tensor_f8_out = tensor_f32.to(dtype=tensor_fp8.dtype)
        elif tensor_fp8.dtype == torch.float8_e5m2:
            # Map to u8 raw tensor for easier byte handle
            tensor_u8 = tensor_fp8.view(torch.uint8)
            # pos & neg nan
            is_pos_nan = tensor_u8 == 0x7F
            is_neg_nan = tensor_u8 == 0xFF
            # Map pos nan to max, neg nan to min
            tensor_f32 = tensor_fp8.to(dtype=torch.float32)
            tensor_f32[is_pos_nan] = 57344
            tensor_f32[is_neg_nan] = -57344
            # Cast back to f8
            tensor_f8_out = tensor_f32.to(dtype=tensor_fp8.dtype)
        else:
            # Not supported dtype
            tensor_f8_out = tensor_fp8
        return tensor_f8_out

    def _compare_gemm(
        torch_tensor_a_cpu: torch.Tensor,
        torch_tensor_b_cpu: torch.Tensor,
        torch_tensor_c: torch.Tensor,
        c_dtype: Type[cutlass.Numeric],
        atol: float,
        rtol: float,
    ):
        # GEMM Ref
        gemm_ref_f32 = torch.einsum(
            "mkl,nkl->mnl",
            torch_tensor_a_cpu.to(dtype=torch.float32),
            torch_tensor_b_cpu.to(dtype=torch.float32),
        )

        # For fp8_e4m3, clamp value to [-448, 448] to avoid nan and then cast to fp8_e4m3
        if c_dtype == cutlass.Float8E4M3FN:
            gemm_ref_f32 = torch.clamp(gemm_ref_f32, min=-448, max=448)
            gemm_ref_f32_c = gemm_ref_f32.to(dtype=torch_dtype(c_dtype))
        # For fp8_e5m2, clamp value to [-57344, 57344] to avoid nan and then cast to fp8_e5m2
        elif c_dtype == cutlass.Float8E5M2:
            gemm_ref_f32 = torch.clamp(gemm_ref_f32, min=-57344, max=57344)
            gemm_ref_f32_c = gemm_ref_f32.to(dtype=torch_dtype(c_dtype))
        else:
            gemm_ref_f32_c = gemm_ref_f32.to(dtype=torch_dtype(c_dtype))

        # Cast ref to fp32 for comparison
        gemm_ref_f32_c_f32 = gemm_ref_f32_c.to(dtype=torch.float32)

        # Cast kernel output to fp32 for comparison
        gemm_out_f32 = torch_tensor_c.cpu().to(dtype=torch.float32)

        # Compare
        torch.testing.assert_close(
            gemm_out_f32,
            gemm_ref_f32_c_f32,
            atol=atol,
            rtol=rtol,
        )

    def _compare_comm(
        torch_tensor_comm_in: torch.Tensor,
        torch_tensor_comm_out: torch.Tensor,
        c_dtype: Type[cutlass.Numeric],
        atol: float,
        rtol: float,
    ):
        comm_ref = torch_tensor_comm_in

        # Sync across all rank
        dist.barrier()

        # Reference AR — NCCL dist.all_reduce for all supported dtypes.
        if c_dtype in [cutlass.Float32, cutlass.BFloat16, cutlass.Float16]:
            comm_ref = comm_ref.contiguous()
            dist.all_reduce(comm_ref, op=torch.distributed.ReduceOp.SUM)
            comm_ref_f32 = comm_ref.to(dtype=torch.float32).cpu()
        # For fp8, cast to higher precision, do AR, then cast back to fp8 and handle nan
        elif c_dtype in [cutlass.Float8E4M3FN, cutlass.Float8E5M2]:
            comm_ref_fp32_acc = comm_ref.to(dtype=torch.float32).contiguous()
            dist.all_reduce(comm_ref_fp32_acc, op=torch.distributed.ReduceOp.SUM)
            # Add small epsilon to mimic multimem.ld_reduce round up behavior where torch cast round down
            epsilon = 1e-2
            comm_ref_f32_acc_epsilon = comm_ref_fp32_acc + epsilon
            comm_ref_c = comm_ref_f32_acc_epsilon.to(dtype=torch_dtype(c_dtype))
            comm_ref_nan2sat = _fp8_nan_to_saturate(comm_ref_c)
            comm_ref_f32 = comm_ref_nan2sat.to(dtype=torch.float32).cpu()

        # Fusion Kernel Result
        # multimem.ld_reduce on fp8 will return nan if val is out of range
        # Need to handle nan the same way as comm ref
        comm_out = torch_tensor_comm_out.cpu()
        if c_dtype in [cutlass.Float8E4M3FN, cutlass.Float8E5M2]:
            # Handle nan
            comm_out_nan2sat = _fp8_nan_to_saturate(comm_out)
            # Cast to fp32 for comparison
            comm_out_f32 = comm_out_nan2sat.to(dtype=torch.float32)
        else:
            # Cast to fp32 for comparison
            comm_out_f32 = comm_out.to(dtype=torch.float32)

        # Compare
        torch.testing.assert_close(
            comm_ref_f32,
            comm_out_f32,
            atol=atol,
            rtol=rtol,
        )

    # compare
    # Impose a strick check on GEMM as input is uniform random int
    gemm_atol = 1e-05
    gemm_rtol = 1e-05
    _compare_gemm(
        torch_tensor_a_cpu=torch_tensor_a_cpu,
        torch_tensor_b_cpu=torch_tensor_b_cpu,
        torch_tensor_c=torch_tensor_c,
        c_dtype=c_dtype,
        atol=gemm_atol,
        rtol=gemm_rtol,
    )

    if all_reduce == "LDMCxSTMC":
        # Relaxed tolerance — reference uses NCCL dist.all_reduce, which
        # reduces in a different order than the fused multimem kernel.
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

    # * Check flags are reset *
    # The kernel uses the flag tensor for cross-CTA / cross-rank synchronization
    # and is expected to leave every entry at 0 once it returns. If any entry is
    # non-zero, a tile didn't drain its slot — re-running the kernel would block
    # forever on that stale flag.
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
    ab_dtype,
    c_dtype,
    acc_dtype,
    a_major,
    b_major,
    c_major,
    mma_tiler_mn,
    cluster_shape_mn,
    swizzle_size,
    raster_order,
    use_2cta_instrs,
    use_tma_store,
    all_reduce,
    global_rank,
    world_size,
    num_workspace,
    tensors,
    torch_stream,
    stream,
    warmup_iterations,
    iterations,
    use_cuda_graph,
):
    """Instantiate one LDMCxSTMC kernel candidate, compile it, and time the
    warmup + benchmark loop.

    Reads cute views out of ``tensors`` (produced by :func:`allocate_tensors`)
    and uses the caller-supplied ``torch_stream`` / ``stream`` pair so every
    candidate in a sweep shares a single CUDA stream + event pool.
    Returns the mean per-iteration time in microseconds over the benchmark
    iterations (warmup timings are recorded but not included in the average).
    """
    cute_tensor_a_list = tensors["cute_tensor_a_list"]
    cute_tensor_b_list = tensors["cute_tensor_b_list"]
    cute_tensor_c = tensors["cute_tensor_c"]
    cute_tensor_comm_in_mc = tensors["cute_tensor_comm_in_mc"]
    cute_tensor_comm_out_mc = tensors["cute_tensor_comm_out_mc"]
    cute_tensor_flag_unicast = tensors["cute_tensor_flag_unicast"]
    cute_tensor_flag_multicast = tensors["cute_tensor_flag_multicast"]

    # Build kernel + can_implement first — before any cross-rank op, so a
    # deterministic skip keeps all ranks in lockstep for the next candidate.
    gemm_all_reduce = Sm100PersistentDenseGemmAllReduceLDMCxSTMCKernel(
        acc_dtype,
        c_dtype,
        use_2cta_instrs,
        mma_tiler_mn,
        cluster_shape_mn,
        use_tma_store,
        rank_id=global_rank,
        num_ranks=world_size,
        all_reduce=all_reduce,
        swizzle_size=swizzle_size,
        raster_order=raster_order,
    )
    try:
        import hashlib

        param_str = (
            f"ab{ab_dtype}_acc{acc_dtype}_c{c_dtype}_{a_major}{b_major}{c_major}"
            f"_tile{mma_tiler_mn[0]}x{mma_tiler_mn[1]}"
            f"_cluster{cluster_shape_mn[0]}x{cluster_shape_mn[1]}"
            f"_{'2Sm' if use_2cta_instrs else '1Sm'}"
            f"_{'EpiTma' if use_tma_store else 'EpiStg'}"
        )
        param_hash = hashlib.md5(param_str.encode()).hexdigest()[:8]
        unique_name = (
            f"sm100_gemm_ar_{param_hash}_{all_reduce}_r{global_rank}_w{world_size}"
        )
    except Exception:
        unique_name = f"sm100_gemm_ar_{all_reduce}_r{global_rank}_w{world_size}"
    gemm_all_reduce.__call__.set_name_prefix(unique_name)

    can_implement = gemm_all_reduce.can_implement(
        mnkl, ab_dtype, c_dtype, a_major, b_major, c_major
    )
    if not can_implement:
        raise testing.CantImplementError(
            f"[general] The current config is invalid/unsupported: use_2cta_instrs={use_2cta_instrs}, "
            f"mma_tiler_mn={mma_tiler_mn}, cluster_shape_mn={cluster_shape_mn}, "
            f"use_tma_store={use_tma_store}, all_reduce={all_reduce}, world_size={world_size}, "
            f"ab_dtype={ab_dtype}, c_dtype={c_dtype}, acc_dtype={acc_dtype}"
        )

    def make_kernel_kwargs(ws):
        return dict(
            a=cute_tensor_a_list[ws],
            b=cute_tensor_b_list[ws],
            c=cute_tensor_c,
            comm_in_multicast_tensor=cute_tensor_comm_in_mc,
            comm_out_multicast_tensor=cute_tensor_comm_out_mc,
            barrier_flag_unicast=cute_tensor_flag_unicast,
            barrier_flag_multicast=cute_tensor_flag_multicast,
            stream=stream,
        )

    kernel_kwargs_list = [make_kernel_kwargs(i) for i in range(num_workspace)]

    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )
    compiled_gemm = cute.compile(
        gemm_all_reduce,
        **kernel_kwargs_list[0],
        max_active_clusters=max_active_clusters,
    )

    # Per-iteration runnable. Under --use_cuda_graph we capture one graph per
    # workspace (pointers are baked in at capture time, so N_workspace graphs
    # are required to rotate A/B). Without graphs we dispatch the compiled
    # kernel directly with the appropriate kernel_kwargs entry.
    if use_cuda_graph:
        graphs = []
        for ws in range(num_workspace):
            g = torch.cuda.CUDAGraph()
            with torch.cuda.graph(g, stream=torch_stream):
                compiled_gemm(**kernel_kwargs_list[ws])
            graphs.append(g)

        def run_one_iter(i):
            graphs[i % num_workspace].replay()
    else:

        def run_one_iter(i):
            compiled_gemm(**kernel_kwargs_list[i % num_workspace])

    # One loop for warmup + benchmark. Every iteration is bracketed by its own
    # event pair; only the trailing `iterations` event pairs contribute to the
    # reported average so warmup transients don't skew the result.

    # Cross-rank sync before timing. torch.cuda.synchronize() drains any
    # pending GPU work (graph captures land on the default stream; timing
    # runs on torch_stream) so dist.barrier()'s host-side rendezvous is
    # not racing in-flight kernels from the previous candidate. Without
    # this, the slowest rank's leftover work would skew the measured
    # window of every other rank in a benchmark_all sweep.
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
    bench_times = per_iter_us[warmup_iterations:]
    avg_us = sum(bench_times) / iterations
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
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: Literal["k", "m"],
    b_major: Literal["k", "n"],
    c_major: Literal["n", "m"],
    mma_tiler_mn: Tuple[int, int] = (256, 256),
    cluster_shape_mn: Tuple[int, int] = (2, 1),
    swizzle_size: int = 1,
    raster_order: Literal["m", "n"] = "m",
    use_2cta_instrs: bool = True,
    use_tma_store: bool = True,
    warmup_iterations: int = 0,
    iterations: int = 1,
    all_reduce: str = "LDMCxSTMC",
    use_cuda_graph: bool = False,
    benchmark_all: bool = False,
    csv_report: str = "./csv_report.csv",
):
    # Allocate every kernel-side tensor (A/B/C/comm_out/flags) up front —
    # shared across all candidates in the --benchmark_all loop.
    num_workspace = 10
    tensors = allocate_tensors(
        mnkl=mnkl,
        ab_dtype=ab_dtype,
        c_dtype=c_dtype,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
        num_workspace=num_workspace,
        device=device,
        slot_init_mode="benchmark",
        global_rank=global_rank,
    )

    # One non-default stream shared across every candidate. `torch_stream` is
    # kept alive because we capture it into a CUDA graph; creating a fresh
    # stream per candidate would churn events + graph context for no reason.
    torch_stream = torch.cuda.Stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)

    # Build the candidate list of args for compile_and_benchmark. For a single
    # run the list has one entry; --benchmark_all sweeps:
    #   raster_order   ∈ {m, n}
    #   swizzle_size   ∈ {1, 2, 4, 8}
    #   use_2cta_instrs, cluster_shape_mn, mma_tiler_mn jointly, with the
    #   constraint that cluster_m ∈ {2,4,8} requires 2cta (smaller tiles and
    #   single-cta clusters are only valid without 2cta).
    base_kwargs = dict(
        mnkl=mnkl,
        ab_dtype=ab_dtype,
        c_dtype=c_dtype,
        acc_dtype=acc_dtype,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
        use_tma_store=use_tma_store,
        all_reduce=all_reduce,
        global_rank=global_rank,
        world_size=world_size,
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
        # All cluster shapes from the allowed set; each is filtered per 2cta
        # option below by the "cluster_m ∈ {2,4,8} needs 2cta" rule.
        cluster_all = [
            (1, 1),
            (1, 2),
            (2, 1),
            (2, 2),
        ]
        two_cta_options = [
            {
                "use_2cta_instrs": True,
                "clusters": [c for c in cluster_all if c[0] in (2, 4, 8)],
                "mma_tilers": [
                    (256, 256),
                    (256, 192),
                    (256, 128),
                    (256, 64),
                    (128, 256),
                    (128, 192),
                    (128, 128),
                    (128, 64),
                ],
            },
            {
                "use_2cta_instrs": False,
                "clusters": cluster_all,
                "mma_tilers": [
                    (128, 256),
                    (128, 192),
                    (128, 128),
                    (128, 64),
                    (64, 256),
                    (64, 192),
                    (64, 128),
                    (64, 64),
                ],
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
                                    "use_2cta_instrs": opt["use_2cta_instrs"],
                                    "cluster_shape_mn": cluster,
                                    "mma_tiler_mn": tile,
                                    "raster_order": r,
                                    "swizzle_size": s,
                                }
                            )
    else:
        candidates = [
            {
                **base_kwargs,
                "use_2cta_instrs": use_2cta_instrs,
                "cluster_shape_mn": cluster_shape_mn,
                "mma_tiler_mn": mma_tiler_mn,
                "raster_order": raster_order,
                "swizzle_size": swizzle_size,
            }
        ]

    if global_rank == 0:
        print(f"Total number of candidate configs: {len(candidates)}", flush=True)

    # Run each candidate. Tensors (A/B/C/comm_out/flags) are reused across
    # candidates; the kernel resets flags internally. Skip any combo the kernel
    # can't implement — can_implement is deterministic so all ranks skip the
    # same ones, keeping rendezvous collective operations lockstep.
    # ~2s sleep between candidates to let the GPU cool down.
    results = []
    for i, cand in enumerate(candidates):
        if i > 0:
            time.sleep(2)
        try:
            avg_us = compile_and_benchmark(**cand)
        except testing.CantImplementError:
            continue
        results.append((cand, avg_us))

    # Each rank writes its own CSV — one row per candidate, one config field
    # per column. The path comes from --csv_report; per-rank suffix is appended
    # before the extension so concurrent ranks don't clobber the same file.
    global_rank = dist.get_rank()
    m, n, k, l = mnkl
    fieldnames = [
        "gemm_m",
        "gemm_n",
        "gemm_k",
        "gemm_l",
        "ab_dtype",
        "c_dtype",
        "acc_dtype",
        "a_major",
        "b_major",
        "c_major",
        "mma_tiler_m",
        "mma_tiler_n",
        "cluster_m",
        "cluster_n",
        "use_2cta_instrs",
        "use_tma_store",
        "all_reduce",
        "use_cuda_graph",
        "raster_order",
        "swizzle_size",
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
                    "ab_dtype": str(ab_dtype),
                    "c_dtype": str(c_dtype),
                    "acc_dtype": str(acc_dtype),
                    "a_major": a_major,
                    "b_major": b_major,
                    "c_major": c_major,
                    "mma_tiler_m": cand["mma_tiler_mn"][0],
                    "mma_tiler_n": cand["mma_tiler_mn"][1],
                    "cluster_m": cand["cluster_shape_mn"][0],
                    "cluster_n": cand["cluster_shape_mn"][1],
                    "use_2cta_instrs": cand["use_2cta_instrs"],
                    "use_tma_store": use_tma_store,
                    "all_reduce": all_reduce,
                    "use_cuda_graph": use_cuda_graph,
                    "raster_order": cand["raster_order"],
                    "swizzle_size": cand["swizzle_size"],
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
        description="Example of SM100 Persistent Dense GEMM AR on Blackwell."
    )

    def _parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser.add_argument(
        "--mnkl",
        type=_parse_comma_separated_ints,
        default=(256, 256, 512, 1),
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument(
        "--mma_tiler_mn",
        type=_parse_comma_separated_ints,
        default=(128, 128),
        help="Mma tile shape (comma-separated)",
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=_parse_comma_separated_ints,
        default=(1, 1),
        help="Cluster shape (comma-separated)",
    )
    parser.add_argument("--ab_dtype", type=cutlass.dtype, default=cutlass.TFloat32)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Enable 2CTA MMA instructions feature",
    )
    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n", "m"], type=str, default="n")
    parser.add_argument(
        "--use_tma_store", action="store_true", help="Use tma store or not"
    )
    parser.add_argument(
        "--benchmark_or_test",
        type=str,
        choices=["test", "benchmark", "benchmark_all"],
        default="test",
        help="Select run mode: 'test' for a single-launch correctness check, "
        "'benchmark' for cudaEvent timing + per-rank CSV on the given config, "
        "'benchmark_all' for the same with a sweep across kernel-config variants.",
    )
    parser.add_argument(
        "--warmup_iterations", type=int, default=0, help="Warmup iterations"
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=1,
        help="Number of iterations to run the kernel",
    )
    parser.add_argument(
        "--use_cuda_graph",
        action="store_true",
        default=False,
        help="Capture one iteration into a CUDA graph and replay per iteration",
    )
    parser.add_argument(
        "--all_reduce",
        choices=["LDMCxSTMC", "none"],
        type=str,
        default="LDMCxSTMC",
        help="Allreduce algorithm to fuse with gemm",
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
        help="Path for the per-rank benchmark CSV. Each rank appends "
        "_rank{R}_world{W} before the extension to avoid collisions.",
    )
    parser.add_argument(
        "--dump_input",
        type=str,
        default=None,
        help="(test mode only) Dump A and B tensors to this directory after init.",
    )
    parser.add_argument(
        "--dump_output",
        type=str,
        default=None,
        help="(test mode only) Dump C and comm_out tensors to this directory after kernel.",
    )
    parser.add_argument(
        "--load_input",
        type=str,
        default=None,
        help="(test mode only) Load A and B from this directory instead of random init.",
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
        args.mnkl,
        args.ab_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.mma_tiler_mn,
        args.cluster_shape_mn,
        args.swizzle_size,
        args.raster_order,
        args.use_2cta_instrs,
        args.use_tma_store,
        args.warmup_iterations,
        args.iterations,
        args.all_reduce,
        args.benchmark_or_test,
        args.use_cuda_graph,
        args.csv_report,
        dump_input=args.dump_input,
        dump_output=args.dump_output,
        load_input=args.load_input,
    )
    rank = int(os.environ["RANK"])
    local_rank = int(os.environ["LOCAL_RANK"])
    print(
        f"PASS (hostname={socket.gethostname()}, global_rank={rank}, local_rank={local_rank})",
        flush=True,
    )
