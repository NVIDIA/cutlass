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

from math import gcd
from pathlib import Path
from typing import List, Optional, Tuple, Type, Union, Literal

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
from cutlass.cute.typing import Pointer, Int32, Float32
from cutlass.cutlass_dsl import T, dsl_user_op, while_generate, yield_out
from cutlass._mlir import ir
from cutlass._mlir.dialects import llvm

"""
SM100 GEMM + AllReduce (Lamport) Fusion Kernel

* Test (correctness only — single launch, no warmup/iteration loop)
python3 -m torch.distributed.run --nproc-per-node=auto examples/python/CuTeDSL/cute/blackwell/kernel/distributed/distributed_gemm_all_reduce_lamport_blackwell.py  \
    --ab_dtype Float16 --c_dtype Float16 --acc_dtype Float32                                        \
    --a_major k --b_major k --c_major n                                                             \
    --mma_tiler_mn 256,256 --cluster_shape_mn 2,1                                                   \
    --mnkl 8192,8192,8192,1                                                                         \
    --use_tma_store --use_2cta_instrs --all_reduce Lamport                                          \
    --benchmark_or_test test

* Benchmark One
python3 -m torch.distributed.run --nproc-per-node=auto examples/python/CuTeDSL/cute/blackwell/kernel/distributed/distributed_gemm_all_reduce_lamport_blackwell.py  \
    --ab_dtype Float16 --c_dtype Float16 --acc_dtype Float32                                        \
    --a_major k --b_major k --c_major n                                                             \
    --mma_tiler_mn 256,256 --cluster_shape_mn 2,1                                                   \
    --mnkl 8192,8192,8192,1 --warmup_iterations 10 --iterations 20                                  \
    --use_tma_store --use_2cta_instrs --all_reduce Lamport                                          \
    --benchmark_or_test benchmark --use_cuda_graph --csv_report ./csv_report.csv

* Benchmark All
python3 -m torch.distributed.run --nproc-per-node=auto examples/python/CuTeDSL/cute/blackwell/kernel/distributed/distributed_gemm_all_reduce_lamport_blackwell.py  \
    --ab_dtype Float16 --c_dtype Float16 --acc_dtype Float32                                        \
    --a_major k --b_major k --c_major n                                                             \
    --mnkl 8192,8192,8192,1 --warmup_iterations 10 --iterations 20                                  \
    --use_tma_store --all_reduce Lamport                                                            \
    --benchmark_or_test benchmark_all --use_cuda_graph --csv_report ./csv_report.csv

NOTE:
* Float8E4M3FN / Float8E5M2 are rejected at allocate_tensors — the -0.0 → +0.0
  epilogue scrub is implemented for Float32 / Float16 / BFloat16 only.
* use_tma_store=True is required: multicast TMA store is the only producer
  path that fans the gemm-epi store out to peers atomically per 16B.
* C (workspace buffer) is a 3-slot grouped allocation (ping / pong / cooling).

ALGO:
-> Producer (each rank, per output tile)
    * Clear() kernel scrubs slot[pong] back to the per-byte -0.0 sentinel so the next-iter producer has an armed slot to overwrite
    * epilogue scrub: acc_vec + (+0.0) — flips any -0.0 lanes in gemm output to +0.0 (IEEE RTNE) so peers don't observe the sentinel as data (for f32/bf16/f16)
    * TMA multicast store [data] to slot[ping][local_rank] — NVSwitch fans out to every peer's mirror of slot[ping][local_rank] atomically per 16B
    * NO separate flag tensor — data IS the flag

-> Consumer (each rank, per output tile)
    * for each peer r: load with .relaxed .gpu from this rank's UC view of slot[ping][r] (direct P2P, no multimem)
    * spin while loaded data == -0.0 sentinel;
    * once data arrive, load data, convert to f32, reduce on f32, convert back.
        each cta now handle entire output tile, no collaboration with other rank
    * store data with .weak .gpu to local rank's global memory
"""

#####################################################################
#### KERNEL IMPLEMENTATION START HERE ####
#####################################################################


@dsl_user_op
def ld_weak_global_4xu32(
    ptr: Pointer,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[Int32, Int32, Int32, Int32]:
    ptr_int = ptr.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    return_struct = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(i32,i32,i32,i32)>"),
        [ptr_int],
        "ld.weak.global.v4.u32 {$0, $1, $2, $3}, [$4];",
        "=r,=r,=r,=r,l",
        has_side_effects=True,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )
    return_regs = [llvm.extractvalue(T.i32(), return_struct, [i]) for i in range(4)]
    return return_regs[0], return_regs[1], return_regs[2], return_regs[3]


@dsl_user_op
def ld_relaxed_gpu_global_4xu32(
    ptr: Pointer,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[Int32, Int32, Int32, Int32]:
    ptr_int = ptr.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    return_struct = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(i32,i32,i32,i32)>"),
        [ptr_int],
        "ld.relaxed.gpu.global.v4.u32 {$0, $1, $2, $3}, [$4];",
        "=r,=r,=r,=r,l",
        has_side_effects=True,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )
    return_regs = [llvm.extractvalue(T.i32(), return_struct, [i]) for i in range(4)]
    return return_regs[0], return_regs[1], return_regs[2], return_regs[3]


@dsl_user_op
def st_weak_global_4xu32(
    ptr: Pointer,
    x: Int32,
    y: Int32,
    z: Int32,
    w: Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    ptr_int = ptr.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    x_ir = Int32(x).ir_value(loc=loc, ip=ip)
    y_ir = Int32(y).ir_value(loc=loc, ip=ip)
    z_ir = Int32(z).ir_value(loc=loc, ip=ip)
    w_ir = Int32(w).ir_value(loc=loc, ip=ip)
    llvm.inline_asm(
        None,
        [ptr_int, x_ir, y_ir, z_ir, w_ir],
        "st.weak.global.v4.u32 [$0], {$1, $2, $3, $4};",
        "l,r,r,r,r",
        has_side_effects=True,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cvt_bf16x2_to_2xf32(
    bf16x2_b32: Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[Float32, Float32]:
    ret = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(f32, f32)>"),
        [bf16x2_b32],
        "{ .reg .b16 hl, hh;\n"
        "  mov.b32 {hl, hh}, $2;\n"
        "  cvt.f32.bf16 $0, hl;\n"
        "  cvt.f32.bf16 $1, hh; }",
        "=f,=f,r",
        has_side_effects=False,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )
    f_lo = Float32(llvm.extractvalue(T.f32(), ret, [0]))
    f_hi = Float32(llvm.extractvalue(T.f32(), ret, [1]))
    return f_lo, f_hi


@dsl_user_op
def cvt_f16x2_to_2xf32(
    f16x2_b32: Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[Float32, Float32]:
    ret = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(f32, f32)>"),
        [f16x2_b32],
        "{ .reg .b16 hl, hh;\n"
        "  mov.b32 {hl, hh}, $2;\n"
        "  cvt.f32.f16 $0, hl;\n"
        "  cvt.f32.f16 $1, hh; }",
        "=f,=f,r",
        has_side_effects=False,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )
    f_lo = Float32(llvm.extractvalue(T.f32(), ret, [0]))
    f_hi = Float32(llvm.extractvalue(T.f32(), ret, [1]))
    return f_lo, f_hi


@dsl_user_op
def cvt_2xf32_to_bf16x2(
    f_lo: Float32,
    f_hi: Float32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32:
    return llvm.inline_asm(
        T.i32(),
        [
            Float32(f_lo).ir_value(loc=loc, ip=ip),
            Float32(f_hi).ir_value(loc=loc, ip=ip),
        ],
        "cvt.rn.bf16x2.f32 $0, $2, $1;",
        "=r,f,f",
        has_side_effects=False,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cvt_2xf32_to_f16x2(
    f_lo: Float32,
    f_hi: Float32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32:
    return llvm.inline_asm(
        T.i32(),
        [
            Float32(f_lo).ir_value(loc=loc, ip=ip),
            Float32(f_hi).ir_value(loc=loc, ip=ip),
        ],
        "cvt.rn.f16x2.f32 $0, $2, $1;",
        "=r,f,f",
        has_side_effects=False,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def add_rn_f32(
    a: Float32,
    b: Float32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Float32:
    return Float32(
        llvm.inline_asm(
            T.f32(),
            [Float32(a).ir_value(loc=loc, ip=ip), Float32(b).ir_value(loc=loc, ip=ip)],
            "add.rn.f32 $0, $1, $2;",
            "=f,f,f",
            has_side_effects=False,
            asm_dialect=0,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def add_rn_f32x2_pair(
    a_lo: Float32,
    a_hi: Float32,
    b_lo: Float32,
    b_hi: Float32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[Float32, Float32]:
    ret = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(f32, f32)>"),
        [
            Float32(a_lo).ir_value(loc=loc, ip=ip),
            Float32(a_hi).ir_value(loc=loc, ip=ip),
            Float32(b_lo).ir_value(loc=loc, ip=ip),
            Float32(b_hi).ir_value(loc=loc, ip=ip),
        ],
        "{ .reg .b64 ab, bb, db;\n"
        "  mov.b64 ab, {$2, $3};\n"
        "  mov.b64 bb, {$4, $5};\n"
        "  add.rn.f32x2 db, ab, bb;\n"
        "  mov.b64 {$0, $1}, db; }",
        "=f,=f,f,f,f,f",
        has_side_effects=False,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )
    sum_lo = Float32(llvm.extractvalue(T.f32(), ret, [0]))
    sum_hi = Float32(llvm.extractvalue(T.f32(), ret, [1]))
    return sum_lo, sum_hi


@dsl_user_op
def cvt_e4m3x4_to_4xf32(
    e4m3x4_b32: Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[Float32, Float32, Float32, Float32]:
    ret = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(f32, f32, f32, f32)>"),
        [e4m3x4_b32],
        "{ .reg .b16 e8x2_lo, e8x2_hi;\n"
        "  .reg .b32 f16x2_lo, f16x2_hi;\n"
        "  .reg .b16 h0, h1, h2, h3;\n"
        "  mov.b32 {e8x2_lo, e8x2_hi}, $4;\n"
        "  cvt.rn.f16x2.e4m3x2 f16x2_lo, e8x2_lo;\n"
        "  cvt.rn.f16x2.e4m3x2 f16x2_hi, e8x2_hi;\n"
        "  mov.b32 {h0, h1}, f16x2_lo;\n"
        "  mov.b32 {h2, h3}, f16x2_hi;\n"
        "  cvt.f32.f16 $0, h0;\n"
        "  cvt.f32.f16 $1, h1;\n"
        "  cvt.f32.f16 $2, h2;\n"
        "  cvt.f32.f16 $3, h3; }",
        "=f,=f,=f,=f,r",
        has_side_effects=False,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )
    return tuple(Float32(llvm.extractvalue(T.f32(), ret, [i])) for i in range(4))


@dsl_user_op
def cvt_e5m2x4_to_4xf32(
    e5m2x4_b32: Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[Float32, Float32, Float32, Float32]:
    ret = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(f32, f32, f32, f32)>"),
        [e5m2x4_b32],
        "{ .reg .b16 e8x2_lo, e8x2_hi;\n"
        "  .reg .b32 f16x2_lo, f16x2_hi;\n"
        "  .reg .b16 h0, h1, h2, h3;\n"
        "  mov.b32 {e8x2_lo, e8x2_hi}, $4;\n"
        "  cvt.rn.f16x2.e5m2x2 f16x2_lo, e8x2_lo;\n"
        "  cvt.rn.f16x2.e5m2x2 f16x2_hi, e8x2_hi;\n"
        "  mov.b32 {h0, h1}, f16x2_lo;\n"
        "  mov.b32 {h2, h3}, f16x2_hi;\n"
        "  cvt.f32.f16 $0, h0;\n"
        "  cvt.f32.f16 $1, h1;\n"
        "  cvt.f32.f16 $2, h2;\n"
        "  cvt.f32.f16 $3, h3; }",
        "=f,=f,=f,=f,r",
        has_side_effects=False,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )
    return tuple(Float32(llvm.extractvalue(T.f32(), ret, [i])) for i in range(4))


@dsl_user_op
def cvt_4xf32_to_e4m3x4(
    f0: Float32,
    f1: Float32,
    f2: Float32,
    f3: Float32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32:
    return llvm.inline_asm(
        T.i32(),
        [
            Float32(f0).ir_value(loc=loc, ip=ip),
            Float32(f1).ir_value(loc=loc, ip=ip),
            Float32(f2).ir_value(loc=loc, ip=ip),
            Float32(f3).ir_value(loc=loc, ip=ip),
        ],
        "{ .reg .b16 e8x2_lo, e8x2_hi;\n"
        "  cvt.rn.satfinite.e4m3x2.f32 e8x2_lo, $2, $1;\n"
        "  cvt.rn.satfinite.e4m3x2.f32 e8x2_hi, $4, $3;\n"
        "  mov.b32 $0, {e8x2_lo, e8x2_hi}; }",
        "=r,f,f,f,f",
        has_side_effects=False,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cvt_4xf32_to_e5m2x4(
    f0: Float32,
    f1: Float32,
    f2: Float32,
    f3: Float32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32:
    return llvm.inline_asm(
        T.i32(),
        [
            Float32(f0).ir_value(loc=loc, ip=ip),
            Float32(f1).ir_value(loc=loc, ip=ip),
            Float32(f2).ir_value(loc=loc, ip=ip),
            Float32(f3).ir_value(loc=loc, ip=ip),
        ],
        "{ .reg .b16 e8x2_lo, e8x2_hi;\n"
        "  cvt.rn.satfinite.e5m2x2.f32 e8x2_lo, $2, $1;\n"
        "  cvt.rn.satfinite.e5m2x2.f32 e8x2_hi, $4, $3;\n"
        "  mov.b32 $0, {e8x2_lo, e8x2_hi}; }",
        "=r,f,f,f,f",
        has_side_effects=False,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cvt_b32_to_1xf32(
    b32_in: Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[Float32]:
    return (Float32(llvm.bitcast(T.f32(), b32_in, loc=loc, ip=ip)),)


@dsl_user_op
def cvt_1xf32_to_b32(
    f: Float32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32:
    return llvm.bitcast(T.i32(), Float32(f).ir_value(loc=loc, ip=ip), loc=loc, ip=ip)


@dsl_user_op
def elem_wise_add_f32(
    a: Tuple[Float32, ...],
    b: Tuple[Float32, ...],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[Float32, ...]:
    assert len(a) == len(b), f"Mismatched tuple sizes: {len(a)} vs {len(b)}"
    n = len(a)
    if n == 1:
        return (add_rn_f32(a[0], b[0], loc=loc, ip=ip),)
    assert n % 2 == 0, f"elem_wise_add_f32: tuple length {n} must be 1 or even"
    # Pair consecutive f32 values into FADD2 invocations.
    out: Tuple[Float32, ...] = ()
    for i in range(0, n, 2):
        s_lo, s_hi = add_rn_f32x2_pair(a[i], a[i + 1], b[i], b[i + 1], loc=loc, ip=ip)
        out = out + (s_lo, s_hi)
    return out


@cute.jit
def Lamport(
    kernel,
    cur_tile_coord,
    tiled_mma: cute.TiledMma,
    comm_tidx: cutlass.Int32,
    tCgCommInUC_per_peer: Tuple[cute.Tensor, ...],
    tCgCommOutUC: cute.Tensor,
) -> None:
    mma_tile_coord_mnl = (
        cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
        cur_tile_coord[1],
        cur_tile_coord[2],
    )

    # Per-peer UC views share shape/strides with the local UC tensor (only the
    # base pointer differs), so one coord pattern slices every peer the same way.
    tCgCommInUC_slice_per_peer = tuple(
        t[((None, None), 0, 0, *mma_tile_coord_mnl)] for t in tCgCommInUC_per_peer
    )
    tCgCommOutUC_slice = tCgCommOutUC[((None, None), 0, 0, *mma_tile_coord_mnl)]

    cta_mma_tile_m = kernel.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape)
    cta_tile_n = kernel.mma_tiler[1]
    total_comm_threads = len(kernel.comm_warp_id) * cute.arch.WARP_SIZE

    local_tile_m = cta_mma_tile_m
    local_tile_n = cta_tile_n

    tCgCommInUC_local_rank_per_peer = tCgCommInUC_slice_per_peer
    tCgCommOutUC_local_rank = tCgCommOutUC_slice

    elements_per_thread = (local_tile_m * local_tile_n) // total_comm_threads
    atom_num_elements_128 = 128 // kernel.c_dtype.width
    atom_num_elements = atom_num_elements_128

    # 128-bit ld/st is mandatory; the cvt wrappers assume 32-bit packed atoms.
    # _pick_num_comm_warp_for_128b ensures divisibility; this assert fires at
    # @cute.jit time if that invariant ever breaks (a `raise` here would be
    # rejected by the AST preprocessor).
    assert cutlass.const_expr(elements_per_thread % atom_num_elements_128 == 0), (
        f"[Lamport] 128-bit instruction required but not viable: "
        f"elements_per_thread={elements_per_thread} is not divisible by "
        f"atom_num_elements_128={atom_num_elements_128}. "
        f"This should never happen if _pick_num_comm_warp_for_128b is correct."
    )

    # Row-major: threads contiguous along N; col-major: along M. GCD handles
    # non-pow2 widths (e.g. cta_n=192) that don't naively divide thread count.
    if cutlass.const_expr(kernel.c_layout.is_n_major_c()):
        max_thr_n = local_tile_n // atom_num_elements
        atom_thr_n = gcd(max_thr_n, total_comm_threads)
        atom_thr_m = total_comm_threads // atom_thr_n
        thr_layout = cute.make_layout((atom_thr_m, atom_thr_n), stride=(atom_thr_n, 1))
        val_layout = cute.make_layout(
            (1, atom_num_elements), stride=(atom_num_elements, 1)
        )
    else:
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

    tTR_gCommInUC_per_peer = tuple(
        thr_copy_fake.partition_S(t) for t in tCgCommInUC_local_rank_per_peer
    )
    tTR_gCommOutUC = thr_copy_fake.partition_S(tCgCommOutUC_local_rank)
    _atom, loop_m, loop_n = tTR_gCommOutUC.shape

    # Dtype dispatch — cvt_to_xf32: i32 → n_per_b32 f32; cvt_back: f32… → i32.
    # neg_zero_dtype_32bit packs the dtype-specific -0.0 across all lanes of
    # one i32 so the spin's break test is a single setp.eq, no bit-extract.
    if cutlass.const_expr(kernel.c_dtype is cutlass.BFloat16):
        cvt_to_xf32 = cvt_bf16x2_to_2xf32
        cvt_back = cvt_2xf32_to_bf16x2
        n_per_b32 = 2
        neg_zero_dtype_32bit = 0x80008000  # bf16 -0.0 × 2 lanes
    elif cutlass.const_expr(kernel.c_dtype is cutlass.Float16):
        cvt_to_xf32 = cvt_f16x2_to_2xf32
        cvt_back = cvt_2xf32_to_f16x2
        n_per_b32 = 2
        neg_zero_dtype_32bit = 0x80008000  # f16 -0.0 × 2 lanes
    elif cutlass.const_expr(kernel.c_dtype is cutlass.Float8E4M3FN):
        cvt_to_xf32 = cvt_e4m3x4_to_4xf32
        cvt_back = cvt_4xf32_to_e4m3x4
        n_per_b32 = 4
        neg_zero_dtype_32bit = 0x80808080  # e4m3 -0.0 × 4 lanes
    elif cutlass.const_expr(kernel.c_dtype is cutlass.Float8E5M2):
        cvt_to_xf32 = cvt_e5m2x4_to_4xf32
        cvt_back = cvt_4xf32_to_e5m2x4
        n_per_b32 = 4
        neg_zero_dtype_32bit = 0x80808080  # e5m2 -0.0 × 4 lanes
    elif cutlass.const_expr(kernel.c_dtype is cutlass.Float32):
        cvt_to_xf32 = cvt_b32_to_1xf32
        cvt_back = cvt_1xf32_to_b32
        n_per_b32 = 1
        neg_zero_dtype_32bit = 0x80000000  # f32 -0.0 × 1 lane
    else:
        raise ValueError(
            f"Lamport: unsupported c_dtype {kernel.c_dtype} "
            "(supported: BFloat16, Float16, Float8E4M3FN, Float8E5M2, Float32)"
        )

    # Accumulator stays in f32 across the full peer chain — one cvt_back at
    # the end preserves the same precision a multimem.ld_reduce path would.
    # Flat-tuple length n_atom * n_per_b32 is always even (4/8/16), so
    # elem_wise_add_f32 always lands on FADD2.
    num_peers = len(tTR_gCommInUC_per_peer)
    n_atom = 4  # 128b / 32b per i32

    # `unroll=1` on the outer (i, j) lattice forces the CuTe preprocessor to
    # emit ONE shared body. Full unroll explodes register pressure
    # (num_peers × n_atom × cvt-tuple f32s live per (i, j)) and the allocator
    # spills to local memory. Inner peer / atom loops stay range_constexpr
    # so their unrolling helps instruction scheduling within one (i, j).
    for i in cutlass.range(loop_m, unroll=1):
        for j in cutlass.range(loop_n, unroll=1):
            # (1) Per-peer load with flag-via-data spin: ld.relaxed.gpu on the
            # peer's UC view, break when g3 (last i32 of the 16B chunk) leaves
            # the sentinel. g3-only is sound because the producer is a TMA
            # multicast store, which lands at peer mirrors atomically per 16B
            # — no torn writes where g3 could update before g0/g1/g2. Random
            # GEMM bits hitting the sentinel are ~2^-32 / lane and the
            # producer-side scrub (epilogue_tma_store_handle_neg_zero) flips
            # -0.0 → +0.0 to remove the only systematic source. If a non-TMA
            # producer is ever wired in, widen the predicate.
            peer_loaded = []
            for r in cutlass.range_constexpr(num_peers):
                ptr = tTR_gCommInUC_per_peer[r][None, i, j].iterator
                init_g0, init_g1, init_g2, init_g3 = ld_relaxed_gpu_global_4xu32(ptr)
                spin = while_generate(
                    [init_g0, init_g1, init_g2, init_g3],
                    lambda _g0, _g1, _g2, g3: g3 == neg_zero_dtype_32bit,
                )
                with spin:
                    new_regs = ld_relaxed_gpu_global_4xu32(ptr)
                    yield_out(list(new_regs))
                peer_loaded.append(tuple(spin.results))

            # (2) build flat f32 tuple from each peer; init accumulator from
            #     peer 0, then vectorized-add the rest.
            acc = ()
            for r in cutlass.range_constexpr(num_peers):
                p_acc = ()
                for k in cutlass.range_constexpr(n_atom):
                    p_acc = p_acc + cvt_to_xf32(peer_loaded[r][k])
                acc = p_acc if r == 0 else elem_wise_add_f32(acc, p_acc)

            # (3) cvt accumulator back to source dtype, once per atom.
            out_regs = []
            for k in cutlass.range_constexpr(n_atom):
                chunk = acc[k * n_per_b32 : (k + 1) * n_per_b32]
                out_regs.append(cvt_back(*chunk))

            # (4) plain st.weak.global.v4.u32 to this rank's local UC slot.
            out_uc_ptr = tTR_gCommOutUC[None, i, j].iterator
            st_weak_global_4xu32(out_uc_ptr, *out_regs)


@cute.jit
def Clear(
    kernel,
    cur_tile_coord,
    tiled_mma: cute.TiledMma,
    comm_tidx: cutlass.Int32,
    tCgCommClearUC_per_peer: Tuple[cute.Tensor, ...],
) -> None:
    # Per-tile scrub of slot[pong] back to the dtype-specific -0.0 sentinel.

    mma_tile_coord_mnl = (
        cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
        cur_tile_coord[1],
        cur_tile_coord[2],
    )

    tCgCommClearUC_slice_per_peer = tuple(
        t[((None, None), 0, 0, *mma_tile_coord_mnl)] for t in tCgCommClearUC_per_peer
    )

    cta_mma_tile_m = kernel.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape)
    cta_tile_n = kernel.mma_tiler[1]
    # Partitioned over EPILOGUE warps (vs Lamport's comm warps).
    total_threads = len(kernel.epilogue_warp_id) * cute.arch.WARP_SIZE

    local_tile_m = cta_mma_tile_m
    local_tile_n = cta_tile_n

    elements_per_thread = (local_tile_m * local_tile_n) // total_threads
    atom_num_elements_128 = 128 // kernel.c_dtype.width
    atom_num_elements = atom_num_elements_128

    assert cutlass.const_expr(elements_per_thread % atom_num_elements_128 == 0), (
        f"[Clear] 128-bit instruction required but not viable: "
        f"elements_per_thread={elements_per_thread} is not divisible by "
        f"atom_num_elements_128={atom_num_elements_128}."
    )

    if cutlass.const_expr(kernel.c_layout.is_n_major_c()):
        max_thr_n = local_tile_n // atom_num_elements
        atom_thr_n = gcd(max_thr_n, total_threads)
        atom_thr_m = total_threads // atom_thr_n
        thr_layout = cute.make_layout((atom_thr_m, atom_thr_n), stride=(atom_thr_n, 1))
        val_layout = cute.make_layout(
            (1, atom_num_elements), stride=(atom_num_elements, 1)
        )
    else:
        max_thr_m = local_tile_m // atom_num_elements
        atom_thr_m = gcd(max_thr_m, total_threads)
        atom_thr_n = total_threads // atom_thr_m
        thr_layout = cute.make_layout((atom_thr_m, atom_thr_n), stride=(1, atom_thr_m))
        val_layout = cute.make_layout(
            (atom_num_elements, 1), stride=(1, atom_num_elements)
        )

    copy_atom_store = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), kernel.c_dtype)
    tiled_copy_fake = cute.make_tiled_copy_tv(copy_atom_store, thr_layout, val_layout)
    thr_copy_fake = tiled_copy_fake.get_slice(
        comm_tidx - kernel.epilogue_warp_id[0] * 32
    )

    tTR_gCommClearUC_per_peer = tuple(
        thr_copy_fake.partition_S(t) for t in tCgCommClearUC_slice_per_peer
    )
    _atom, loop_m, loop_n = tTR_gCommClearUC_per_peer[0].shape

    # Same dtype → -0.0 byte pattern as Lamport's neg_zero_dtype_32bit table.
    if cutlass.const_expr(kernel.c_dtype is cutlass.BFloat16):
        neg_zero_dtype_32bit = 0x80008000  # bf16 -0.0 × 2 lanes
    elif cutlass.const_expr(kernel.c_dtype is cutlass.Float16):
        neg_zero_dtype_32bit = 0x80008000  # f16 -0.0 × 2 lanes
    elif cutlass.const_expr(kernel.c_dtype is cutlass.Float8E4M3FN):
        neg_zero_dtype_32bit = 0x80808080  # e4m3 -0.0 × 4 lanes
    elif cutlass.const_expr(kernel.c_dtype is cutlass.Float8E5M2):
        neg_zero_dtype_32bit = 0x80808080  # e5m2 -0.0 × 4 lanes
    elif cutlass.const_expr(kernel.c_dtype is cutlass.Float32):
        neg_zero_dtype_32bit = 0x80000000  # f32 -0.0 × 1 lane
    else:
        raise ValueError(
            f"Clear: unsupported c_dtype {kernel.c_dtype} "
            "(supported: BFloat16, Float16, Float8E4M3FN, Float8E5M2, Float32)"
        )

    num_peers = len(tTR_gCommClearUC_per_peer)

    # `unroll=1` outer (same reason as Lamport); inner peer loop is short
    # const_expr so it unrolls into back-to-back STG.E.128.
    for i in cutlass.range(loop_m, unroll=1):
        for j in cutlass.range(loop_n, unroll=1):
            for r in cutlass.range_constexpr(num_peers):
                ptr = tTR_gCommClearUC_per_peer[r][None, i, j].iterator
                st_weak_global_4xu32(
                    ptr,
                    neg_zero_dtype_32bit,
                    neg_zero_dtype_32bit,
                    neg_zero_dtype_32bit,
                    neg_zero_dtype_32bit,
                )


@cute.jit
def epilogue_tma_store_handle_neg_zero(
    gemm_kernel,
    epi_tidx: cutlass.Int32,
    warp_idx: cutlass.Int32,
    tma_atom_c: cute.CopyAtom,
    # Input of epilogue
    tCtAcc_base: cute.Tensor,
    # Staging of epilogue
    sC: cute.Tensor,
    # Output of epilogue
    tCgC_base: cute.Tensor,
    epi_tile: cute.Tile,
    num_tiles_executed: cutlass.Int32,
    epilogue_op: cutlass.Constexpr,
    mma_tile_coord_mnl: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
    acc_consumer_state: pipeline.PipelineState,
    acc_pipeline: pipeline.PipelineAsync,
    c_pipeline: pipeline.PipelineTmaStore,
) -> pipeline.PipelineState:
    # Fork of cutlass.utils.gemm.sm100.epilogue_tma_store with the Lamport
    # -0.0 → +0.0 scrub spliced in below; otherwise behaviour-identical to
    # the upstream helper.

    # Layout transformation for tCgC_base
    # ((MMA_ATOM_M, MMA_ATOM_N), MMA_M, MMA_N, TILE_M, TILE_N, TILE_K)
    # -> ((MMA_ATOM_M, MMA_M), (MMA_ATOM_N, MMA_N), TILE_M, TILE_N, TILE_K)
    tCgC = utils.gemm.sm100.transform_partitioned_tensor_layout(tCgC_base)

    # Layout transformation for tCtAcc_base
    # ((MMA_ATOM_M, MMA_ATOM_N), MMA_M, MMA_N, STAGE)
    # -> ((MMA_ATOM_M, MMA_M), (MMA_ATOM_N, MMA_N), STAGE)
    tCtAcc = utils.gemm.sm100.transform_partitioned_tensor_layout(tCtAcc_base)

    tiled_copy_t2r, tTR_tAcc_base, tTR_rAcc = (
        utils.gemm.sm100.epilogue_tmem_copy_and_partition(
            gemm_kernel, epi_tidx, tCtAcc, tCgC, epi_tile, gemm_kernel.use_2cta_instrs
        )
    )

    tTR_rC = cute.make_rmem_tensor(tTR_rAcc.shape, gemm_kernel.c_dtype)
    tiled_copy_r2s, tRS_rC, tRS_sC = utils.gemm.sm100.epilogue_smem_copy_and_partition(
        gemm_kernel, tiled_copy_t2r, tTR_rC, epi_tidx, sC
    )

    # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, RestM, RestN, RestL)
    tCgC_epi = cute.flat_divide(tCgC, epi_tile)
    # ((ATOM_V, REST_V), EPI_M, EPI_N)
    # ((ATOM_V, REST_V), EPI_M, EPI_N, RestM, RestN, RestL)
    bSG_sC, bSG_gC_partitioned = cpasync.tma_partition(
        tma_atom_c,
        0,
        cute.make_layout(1),
        cute.group_modes(sC, 0, 2),
        cute.group_modes(tCgC_epi, 0, 2),
    )

    epilog_sync_barrier = pipeline.NamedBarrier(
        barrier_id=gemm_kernel.epilog_sync_bar_id,
        num_threads=32 * len(gemm_kernel.epilogue_warp_id),
    )

    #
    # Slice to per mma tile index
    #
    # ((ATOM_V, REST_V), EPI_M, EPI_N)
    bSG_gC = bSG_gC_partitioned[(None, None, None, *mma_tile_coord_mnl)]

    # Set tensor memory buffer for current tile
    # (T2R, T2R_M, T2R_N, EPI_M, EPI_M)
    tTR_tAcc = tTR_tAcc_base[(None, None, None, None, None, acc_consumer_state.index)]

    #
    # Wait for accumulator buffer full
    #
    acc_pipeline.consumer_wait(acc_consumer_state)

    tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
    bSG_gC = cute.group_modes(bSG_gC, 1, cute.rank(bSG_gC))

    #
    # Store accumulator to global memory in subtiles
    #
    subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])  # type: ignore[union-attr]
    num_prev_subtiles = num_tiles_executed * subtile_cnt
    for subtile_idx in range(subtile_cnt):
        #
        # Load accumulator from tensor memory buffer to register
        #
        tTR_tAcc_mn = tTR_tAcc[(None, None, None, subtile_idx)]  # type: ignore[call-overload]
        cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)

        #
        # Convert to C type
        #
        acc_vec = tiled_copy_r2s.retile(tTR_rAcc).load()
        acc_vec = epilogue_op(acc_vec.to(gemm_kernel.c_dtype))  # type: ignore[operator]

        # Lamport scrub: peers spin on -0.0 as the "not arrived" sentinel,
        # so a legitimate -0.0 in GEMM output must not reach C. IEEE RTNE
        # gives `-0.0 + +0.0 = +0.0` and is bit-exact pass-through for every
        # other value, so a +0 lane-tensor add flips only the sentinel
        # lanes. Not constant-folded: cute doesn't enable nsz globally.
        if cutlass.const_expr(gemm_kernel.all_reduce == "Lamport"):
            acc_vec = acc_vec + cute.full_like(acc_vec, 0.0)

        tRS_rC.store(acc_vec)

        #
        # Store C to shared memory
        #
        c_buffer = (num_prev_subtiles + subtile_idx) % gemm_kernel.num_c_stage
        cute.copy(tiled_copy_r2s, tRS_rC, tRS_sC[(None, None, None, c_buffer)])
        # Fence and barrier to make sure shared memory store is visible to TMA store
        cute.arch.fence_proxy(
            "async.shared",
            space="cta",
        )
        epilog_sync_barrier.arrive_and_wait()

        #
        # TMA store C to global memory
        #
        if warp_idx == gemm_kernel.epilogue_warp_id[0]:
            cute.copy(
                tma_atom_c,
                bSG_sC[(None, c_buffer)],
                bSG_gC[(None, subtile_idx)],
            )
            # Fence and barrier to make sure shared memory store is visible to TMA store
            c_pipeline.producer_commit()
            c_pipeline.producer_acquire()
        epilog_sync_barrier.arrive_and_wait()

    epilog_sync_barrier.arrive_and_wait()

    #
    # Async arrive accumulator buffer empty
    #
    with cute.arch.elect_one():
        acc_pipeline.consumer_release(acc_consumer_state)
    acc_consumer_state.advance()
    return acc_consumer_state


class Sm100PersistentDenseGemmAllReduceLamportKernel:
    """
    **Example:**
        gemm = Sm100PersistentDenseGemmAllReduceLamportKernel(
            acc_dtype=cutlass.Float32,
            c_dtype=cutlass.BFloat16,
            use_2cta_instrs=True,
            mma_tiler_mn=(256, 256),
            cluster_shape_mn=(2, 1),
            use_tma_store=True,
            rank_id=rank_id,
            num_ranks=num_ranks,
            all_reduce="Lamport",
            swizzle_size=1,
            raster_order="m",
        )
        compiled_gemm = cute.compile(
            gemm,
            a=a, b=b,
            c_multicast_tensor=c_mc_slot_ping_local_rank,
            comm_in_unicast_tensor_per_peer=c_uc_per_peer_slot_ping,
            comm_clear_unicast_tensor_per_peer=c_uc_per_peer_slot_pong,
            comm_out_unicast_tensor=comm_out_uc,
            stream=stream,
            max_active_clusters=max_active_clusters,
        )
        compiled_gemm(
            a=a, b=b,
            c_multicast_tensor=c_mc_slot_ping_local_rank,
            comm_in_unicast_tensor_per_peer=c_uc_per_peer_slot_ping,
            comm_clear_unicast_tensor_per_peer=c_uc_per_peer_slot_pong,
            comm_out_unicast_tensor=comm_out_uc,
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
        all_reduce: str = "Lamport",
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
        if all_reduce == "Lamport":
            self.rank_id = rank_id
            self.num_ranks = num_ranks
            num_comm_warps = self._pick_num_comm_warp_for_128b(c_dtype)
            self.comm_warp_id = tuple(range(6, 6 + num_comm_warps))
        else:
            # Other AR mode not support by now.
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
        across T threads AND every thread gets a full 128 b LD/ST payload
        (= ``atom_128`` elements, where ``atom_128 = 16 / sizeof(c_dtype)``).

        Iterates W = 4 → 1 and returns the first match, so the largest
        viable W is returned. Smaller W is only chosen when strictly
        necessary, because larger W means more parallel AR threads and
        proportionally fewer per-thread PTX instructions.
        """
        # cta-tile dims (the per-CTA M·N output the AR walks). 2cta halves M.
        # Lamport: each rank handles the entire CTA tile (no // num_ranks split),
        # so the slab a single rank's comm warps must cover is the full M·N.
        cta_mma_tile_m = self.mma_tiler_mn[0] // (2 if self.use_2cta_instrs else 1)
        cta_tile_n = self.mma_tiler_mn[1]
        slab_elements = cta_mma_tile_m * cta_tile_n
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
        """Set up configurations that are dependent on GEMM inputs

        This method configures various attributes based on the input tensor properties
        (data types, leading dimensions) and kernel settings:
        - Configuring tiled MMA
        - Computing MMA/cluster/tile shapes
        - Computing cluster layout
        - Computing multicast CTAs for A/B
        - Computing epilogue subtile
        - Setting up A/B/C stage counts in shared memory
        - Computing A/B/C shared memory layout
        - Computing tensor memory allocation columns
        """
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
        c_multicast_tensor: cute.Tensor,
        comm_in_unicast_tensor_per_peer: Tuple[cute.Tensor, ...],
        comm_clear_unicast_tensor_per_peer: Tuple[cute.Tensor, ...],
        comm_out_unicast_tensor: cute.Tensor,
        stream: cuda.CUstream,
        max_active_clusters: cutlass.Constexpr,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        # Setup static attributes before smem/grid/tma computation.
        # NOTE: self.c_dtype was set in __init__ from the explicit c_dtype
        # arg. We only sanity-check here that the C tensor matches that hint.
        # Lamport mandates use_tma_store=True
        if cutlass.const_expr(self.all_reduce == "Lamport"):
            assert self.use_tma_store, (
                "Lamport requires use_tma_store=True (the C tensor is now a "
                "multicast view; STG on a multicast address does not fan out)."
            )
            # f8 is temporarily rejected
            assert self.c_dtype not in (
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            ), (
                f"Lamport currently does not support c_dtype={self.c_dtype}: the "
                "epilogue -0.0 → +0.0 scrub is implemented for Float32/Float16/"
                "BFloat16 only. The f8 path will land once the bitwise haszero "
                "scrub is verified."
            )
        self.a_dtype: Type[cutlass.Numeric] = a.element_type
        self.b_dtype: Type[cutlass.Numeric] = b.element_type
        if cutlass.const_expr(c_multicast_tensor.element_type != self.c_dtype):
            raise TypeError(
                f"C tensor element_type ({c_multicast_tensor.element_type}) does not match "
                f"the c_dtype declared at __init__ ({self.c_dtype})"
            )
        self.a_major_mode = utils.LayoutEnum.from_tensor(a).mma_major_mode()
        self.b_major_mode = utils.LayoutEnum.from_tensor(b).mma_major_mode()
        self.c_layout = utils.LayoutEnum.from_tensor(c_multicast_tensor)

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
                cpasync.CopyBulkTensorTileS2GOp(),
                c_multicast_tensor,
                epi_smem_layout,
                self.epi_tile,
            )

        # Compute grid size
        self.tile_sched_params, grid = self._compute_grid(
            c_multicast_tensor,
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
            mC_mc_mnl=tma_tensor_c,
            mCommInUC_mnl_per_peer=comm_in_unicast_tensor_per_peer,
            mCommClearUC_mnl_per_peer=comm_clear_unicast_tensor_per_peer,
            mCommOutUC_mnl=comm_out_unicast_tensor,
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
        mC_mc_mnl: cute.Tensor,
        mCommInUC_mnl_per_peer: Tuple[cute.Tensor, ...],
        mCommClearUC_mnl_per_peer: Tuple[cute.Tensor, ...],
        mCommOutUC_mnl: cute.Tensor,
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
        num_tma_producer = self.num_mcast_ctas_a + self.num_mcast_ctas_b - 1
        ab_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_tma_producer
        )
        ab_producer, ab_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_pipeline_producer_group,
            consumer_group=ab_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
            cta_layout_vmnk=cluster_layout_vmnk,
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
        # (bM, bN, RestM, RestN, RestL). For Lamport this is the multicast view
        # of THIS rank's C_tuple[rank_id]; the TMA store on it broadcasts to
        # all peers' C_tuple[rank_id].uc.
        gC_mnl = cute.local_tile(
            mC_mc_mnl,
            cute.slice_(self.mma_tiler, (None, None, 0)),
            (None, None, None),
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

            # Build the per-peer Clear partition
            if cutlass.const_expr(self.all_reduce == "Lamport"):
                gCommClearUC_mnl_per_peer = tuple(
                    cute.local_tile(
                        t,
                        cute.slice_(self.mma_tiler, (None, None, 0)),
                        (None, None, None),
                    )
                    for t in mCommClearUC_mnl_per_peer
                )
                tCgCommClearUC_per_peer = tuple(
                    thr_mma.partition_C(g) for g in gCommClearUC_mnl_per_peer
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

                # Per-tile scrub of slot[pong]'s `world_size` local UC slabs
                # back to the -0.0 sentinel, in preparation for the next-iter
                # ping write. Runs in the epilogue warp BEFORE the TMA store
                if cutlass.const_expr(self.all_reduce == "Lamport"):
                    Clear(
                        self,
                        cur_tile_coord=cur_tile_coord,
                        tiled_mma=tiled_mma,
                        comm_tidx=tidx,
                        tCgCommClearUC_per_peer=tCgCommClearUC_per_peer,
                    )

                if cutlass.const_expr(self.use_tma_store):
                    acc_consumer_state = epilogue_tma_store_handle_neg_zero(
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

                # Lamport: no per-tile flag release. The data store itself is
                # the flag — peers spin on the per-i32 -0.0 sentinel inside
                # their AR warp and observe arrival when the broadcast lands.

            if cutlass.const_expr(self.use_tma_store):
                # Drain all in-flight TMA stores once at end of the loop. For
                # Lamport this is the only producer-side wait: peers detect
                # individual tile arrival via data polling, not via this tail.
                c_pipeline.producer_tail()
            else:
                # Synchronize before TMEM dealloc
                if cutlass.const_expr(self.all_reduce != "Lamport"):
                    tmem_dealloc_barrier.arrive_and_wait()

            #
            # Dealloc the tensor memory buffer
            #
            tmem.relinquish_alloc_permit()
            tmem.free(tmem_ptr)

        # ///////////////////////////////////////////////////////////////////////////////
        #  AllReduce warps
        # ///////////////////////////////////////////////////////////////////////////////
        if cutlass.const_expr(self.all_reduce == "Lamport"):
            if warp_idx >= self.comm_warp_id[0]:
                # Per peer: (bM, bN, RestM, RestN, RestL) with that peer's local
                # UC view (direct P2P address). Same tile bounds as the MC view —
                # only the base pointer differs across the tuple. Used by Lamport
                # to issue per-peer ld.weak.global.v4.u32 loads.
                gCommInUC_mnl_per_peer = tuple(
                    cute.local_tile(
                        t,
                        cute.slice_(self.mma_tiler, (None, None, 0)),
                        (None, None, None),
                    )
                    for t in mCommInUC_mnl_per_peer
                )
                # (bM, bN, RestM, RestN, RestL) with local UC memory as comm output
                gCommOutUC_mnl = cute.local_tile(
                    mCommOutUC_mnl,
                    cute.slice_(self.mma_tiler, (None, None, 0)),
                    (None, None, None),
                )
                # Per-peer thread-MMA partitioning of the input UC views.
                tCgCommInUC_per_peer = tuple(
                    thr_mma.partition_C(g) for g in gCommInUC_mnl_per_peer
                )
                # (MMA, MMA_M, MMA_N, RestM, RestN, RestL) with local UC memory
                tCgCommOutUC = thr_mma.partition_C(gCommOutUC_mnl)

                #
                # Persistent tile scheduling loop for all reduce
                #

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
                    Lamport(
                        self,
                        cur_tile_coord=cur_tile_coord,
                        tiled_mma=tiled_mma,
                        comm_tidx=tidx,
                        tCgCommInUC_per_peer=tCgCommInUC_per_peer,
                        tCgCommOutUC=tCgCommOutUC,
                    )

                    #
                    # Advance to next tile
                    #
                    tile_sched.advance_to_next_work()
                    work_tile = tile_sched.get_current_work()

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
            # Make sure the swizzle size divides the cta/cga count since non TMA epilogue don't support OOB tiles.
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
        if self.all_reduce not in ["Lamport", "none"]:
            raise testing.CantImplementError(
                f"[all_reduce_mode] Invalid all-reduce mode: {self.all_reduce}, expected 'Lamport' or 'none'"
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
        # Only check for Lamport mode which uses multimem operations
        if self.all_reduce != "Lamport":
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
                    f"must be divisible by swizzle_size={self.swizzle_size} for Lamport with raster_order_m"
                )
        else:
            # Swizzle applies to M dimension only
            if num_clusters_m % self.swizzle_size != 0:
                raise testing.CantImplementError(
                    f"[problem_size_divisible_swizzle_size] Number of clusters in M dimension ({num_clusters_m}) "
                    f"must be divisible by swizzle_size={self.swizzle_size} for Lamport with raster_order_n"
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

        # Skip if swizzle doesn't evenly divide the problem (for Lamport communication)
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
    import torch

    num_devices = torch.cuda.device_count()
    cuda_p2p_access_available = True
    for i in range(num_devices - 1):
        for j in range(i + 1, num_devices):
            if not torch.cuda.can_device_access_peer(i, j):
                cuda_p2p_access_available = False
                break
        if not cuda_p2p_access_available:
            break
    return cuda_p2p_access_available


# Check for multicast support
def check_multicast_support():
    try:
        from torch._C._autograd import DeviceType
        from torch._C._distributed_c10d import _SymmetricMemory

        device_count = torch.cuda.device_count()
        for device_id in range(device_count):
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
    def _simple_torch_allreduce():
        tensor = symm_mem.empty((16384), dtype=torch.float32, device=device)
        symm_mem.rendezvous(tensor, group=dist.group.WORLD)
        torch.ops.symm_mem.multimem_all_reduce_(
            tensor, "sum", dist.group.WORLD.group_name
        )

    try:
        _simple_torch_allreduce()
    except Exception:
        return False
    return True


def allocate_tensors(
    *,
    mnkl: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    a_major: Literal["k", "m"],
    b_major: Literal["k", "n"],
    c_major: Literal["n", "m"],
    num_workspace: int,
    world_size: int,
    global_rank: int,
    device: int,
    slot_init_mode: Literal["test", "benchmark"] = "test",
):
    """Allocate every tensor the Lamport kernel touches.

    Lamport requires a 3-slot grouped C buffer (ping / pong / cooling).
    Each outer slot holds
    ``world_size`` symmetric-memory allocations (one peer-owned slab apiece),
    and each allocation exposes a unicast (UC) view, a multicast (MC) view,
    and a tuple of per-peer direct-P2P UC views built from
    ``buffer_ptrs[r]`` of the symm_mem rendezvous handle.

    Slot initialization depends on ``slot_init_mode``:

    - ``"test"``: slot[0] is pre-seeded with the per-element Lamport ``-0.0``
      sentinel; slots [1] and [2] are seeded with random non-sentinel data so
      the in-kernel clear of slot[1] (back to ``-0.0``) is observable as a
      bit-pattern change in the post-run verification. The correctness path
      uses ping=0, pong=1.
    - ``"benchmark"``: every outer slot is pre-seeded with the ``-0.0``
      sentinel because the benchmark rotates through all three slots in the
      ping role, so every slot must look "not-yet-arrived" the first time
      it is read.

    A and B are allocated as ``num_workspace`` per-device copies (L2-cold
    ring buffer), all bit-exact equal. ``comm_out`` is a plain per-device
    tensor — Lamport only writes it locally via ``st.weak.global``; no peer
    reads, no multicast.

    Returns a dict keyed for ``run_distributed_test`` / ``compile_and_benchmark``.
    The ``_anchors`` tuple holds every torch handle that keeps the underlying
    GPU allocations alive for the lifetime of the caller.
    """
    NUM_C_BUFFERS = 3

    if c_dtype in (cutlass.Float8E4M3FN, cutlass.Float8E5M2):
        # Lamport's -0.0 sentinel epilogue is implemented for f32/f16/bf16
        # only (see the file header). Reject f8 here so the failure surfaces
        # before any GPU allocation.
        raise testing.CantImplementError(
            f"Lamport currently does not support c_dtype={c_dtype}: the "
            "epilogue -0.0 → +0.0 scrub is implemented for Float32 / Float16 / "
            "BFloat16 only."
        )

    def _create_multicast_tensor(
        *,
        torch_tensor_ref: torch.Tensor,
        dtype: Type[cutlass.Numeric],
        leading_dim: int,
    ):
        # PyTorch symmetric-memory allocation + multicast view, mirroring the
        # pattern used in distributed_gemm_blockscaled_all_reduce_ldmcxstmc_blackwell.py.
        #
        # After the collective ``symm_mem.rendezvous(t, group=...)`` the
        # returned handle exposes:
        #   - ``multicast_ptr``: VA of the multicast view onto the same
        #     symmetric allocation. Writes/reads through it hit every rank's
        #     copy via multimem.*.
        #   - ``buffer_ptrs[r]``: per-peer VAs onto peer r's slab. Lamport
        #     issues plain ld.weak.global vector loads through these.
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

        if is_col_major:
            torch_tensor_mc = cutlass_torch.as_tensor(
                torch_tensor_hdl.multicast_ptr, reversed_shape, ref_dtype
            ).permute(perm)
        else:
            torch_tensor_mc = cutlass_torch.as_tensor(
                torch_tensor_hdl.multicast_ptr, shape, ref_dtype
            )

        def _make_peer_torch(r: int) -> torch.Tensor:
            if is_col_major:
                return cutlass_torch.as_tensor(
                    torch_tensor_hdl.buffer_ptrs[r], reversed_shape, ref_dtype
                ).permute(perm)
            return cutlass_torch.as_tensor(
                torch_tensor_hdl.buffer_ptrs[r], shape, ref_dtype
            )

        torch_tensors_uc_per_peer = tuple(
            _make_peer_torch(r) for r in range(world_size)
        )

        cute_tensor_uc = from_dlpack(torch_tensor_uc, assumed_align=16)
        cute_tensor_uc.element_type = dtype
        cute_tensor_uc = cute_tensor_uc.mark_layout_dynamic(leading_dim=leading_dim)
        cute_tensor_uc = cutlass_torch.convert_cute_tensor(
            torch_tensor_uc,
            cute_tensor_uc,
            dtype,
            is_dynamic_layout=True,
        )

        cute_tensor_mc = from_dlpack(torch_tensor_mc, assumed_align=16)
        cute_tensor_mc.element_type = dtype
        cute_tensor_mc = cute_tensor_mc.mark_layout_dynamic(leading_dim=leading_dim)

        def _wrap_peer_cute(peer_torch: torch.Tensor):
            peer_cute = from_dlpack(peer_torch, assumed_align=16)
            peer_cute.element_type = dtype
            peer_cute = peer_cute.mark_layout_dynamic(leading_dim=leading_dim)
            return cutlass_torch.convert_cute_tensor(
                peer_torch, peer_cute, dtype, is_dynamic_layout=True
            )

        cute_tensors_uc_per_peer = tuple(
            _wrap_peer_cute(peer_torch) for peer_torch in torch_tensors_uc_per_peer
        )

        return (
            cute_tensor_uc,
            cute_tensor_mc,
            cute_tensors_uc_per_peer,
            torch_tensor_uc,
            torch_tensor_mc,
            torch_tensors_uc_per_peer,
        )

    # Per-rank seed: distinct A/B per rank so AR sees real cross-rank diversity
    # (matches the original run_distributed init). fp8 is rejected above, so
    # the fp8-specific same-seed branch is no longer needed.
    torch.manual_seed(42 + global_rank)

    m, n, k, l = mnkl

    # CPU random Int32 in [-1, 1] then cast — Lamport uses this narrower
    # range than ldmcxstmc ([-2, 2]) because the all-reduce sum across N
    # ranks must not overflow the f16 / bf16 dynamic range.
    _init_lo, _init_hi = (-1, 1) if slot_init_mode == "test" else (-20, 20)
    torch_tensor_a_int_cpu = cutlass_torch.matrix(
        l,
        m,
        k,
        a_major == "m",
        cutlass.Int32,
        init_type=cutlass_torch.TensorInitType.RANDOM,
        init_config=cutlass_torch.RandomInitConfig(min_val=_init_lo, max_val=_init_hi),
    )
    torch_tensor_b_int_cpu = cutlass_torch.matrix(
        l,
        n,
        k,
        b_major == "n",
        cutlass.Int32,
        init_type=cutlass_torch.TensorInitType.RANDOM,
        init_config=cutlass_torch.RandomInitConfig(min_val=_init_lo, max_val=_init_hi),
    )
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

    torch_tensor_a_cpu = torch_tensor_a_int_cpu.to(dtype=torch_dtype(ab_dtype))
    torch_tensor_b_cpu = torch_tensor_b_int_cpu.to(dtype=torch_dtype(ab_dtype))
    torch_tensor_c_cpu = torch_tensor_c_int_cpu.to(dtype=torch_dtype(c_dtype))
    torch_tensor_comm_out_c_cpu = torch_tensor_comm_out_c_int_cpu.to(
        dtype=torch_dtype(c_dtype)
    )

    # The Lamport sentinel-vs-random init pattern depends on slot_init_mode.
    # In test mode, slot[0] enters as the -0.0 sentinel and slots [1, 2] hold
    # random data so the in-kernel clear of slot[1] is observable in
    # _compare_buffer_clear. In benchmark mode every slot enters as the
    # sentinel because the rotation cycles all three through the ping role.
    torch_tensor_c_random_cpu = torch_tensor_c_cpu.clone()
    torch_tensor_c_cpu.fill_(-0.0)

    # A, B GPU: num_workspace copies (L2-cold ring buffer), bit-exact equal.
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

    # Grouped C: NUM_C_BUFFERS outer × world_size inner symmetric allocations.
    # Each rank "owns" allocation index `global_rank` for scatter — its TMA
    # multicast store goes through the MC view of slot[s][global_rank], which
    # NVSwitch fans out to slot[s][global_rank] on every peer. Every rank then
    # reads slot[s][r] (its own UC view of allocation r) to find peer r's
    # contribution.
    leading_dim_c = 1 if c_major == "n" else 0
    cute_uc_grouped: List[Tuple[cute.Tensor, ...]] = []
    cute_mc_grouped: List[Tuple[cute.Tensor, ...]] = []
    torch_uc_grouped: List[Tuple[torch.Tensor, ...]] = []
    torch_mc_grouped: List[Tuple[torch.Tensor, ...]] = []
    for buf_idx in range(NUM_C_BUFFERS):
        cute_uc_list: List[cute.Tensor] = []
        cute_mc_list: List[cute.Tensor] = []
        torch_uc_list: List[torch.Tensor] = []
        torch_mc_list: List[torch.Tensor] = []
        if slot_init_mode == "test":
            # Test scaffold: slot[0] enters as the Lamport -0.0 sentinel
            # (live ping this iteration); slots [1, 2] init with random
            # non-sentinel data so the kernel-side clear of slot[1] is
            # observable as a bit-pattern change in the post-run verify.
            init_ref = torch_tensor_c_cpu if buf_idx == 0 else torch_tensor_c_random_cpu
        else:
            # Benchmark: every slot enters as -0.0 because the rotation
            # cycles all three through the ping role.
            init_ref = torch_tensor_c_cpu
        for _ in range(world_size):
            (
                _c_uc,
                _c_mc,
                _c_uc_per_peer,
                _t_uc,
                _t_mc,
                _t_uc_per_peer,
            ) = _create_multicast_tensor(
                torch_tensor_ref=init_ref,
                dtype=c_dtype,
                leading_dim=leading_dim_c,
            )
            cute_uc_list.append(_c_uc)
            cute_mc_list.append(_c_mc)
            torch_uc_list.append(_t_uc)
            torch_mc_list.append(_t_mc)
        cute_uc_grouped.append(tuple(cute_uc_list))
        cute_mc_grouped.append(tuple(cute_mc_list))
        torch_uc_grouped.append(tuple(torch_uc_list))
        torch_mc_grouped.append(tuple(torch_mc_list))

    cute_tensors_c_uc_per_peer_grouped = tuple(cute_uc_grouped)
    cute_tensors_c_mc_per_peer_grouped = tuple(cute_mc_grouped)
    torch_tensors_c_uc_per_peer_grouped = tuple(torch_uc_grouped)
    torch_tensors_c_mc_per_peer_grouped = tuple(torch_mc_grouped)

    # comm_out: plain per-device CUDA tensor (Lamport only writes it locally
    # via st.weak.global — no multicast, no peer reads).
    cute_tensor_comm_out_uc, torch_tensor_comm_out_gpu = cutlass_torch.cute_tensor_like(
        torch_tensor_comm_out_c_cpu,
        c_dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )

    return {
        "cute_tensor_a_list": cute_tensor_a_list,
        "cute_tensor_b_list": cute_tensor_b_list,
        "cute_tensors_c_uc_per_peer_grouped": cute_tensors_c_uc_per_peer_grouped,
        "cute_tensors_c_mc_per_peer_grouped": cute_tensors_c_mc_per_peer_grouped,
        "cute_tensor_comm_out_uc": cute_tensor_comm_out_uc,
        "torch_tensor_a_cpu": torch_tensor_a_cpu,
        "torch_tensor_b_cpu": torch_tensor_b_cpu,
        "torch_tensor_c_cpu": torch_tensor_c_cpu,
        "torch_tensors_c_uc_per_peer_grouped": torch_tensors_c_uc_per_peer_grouped,
        "torch_tensor_comm_out_gpu": torch_tensor_comm_out_gpu,
        "_anchors": (
            torch_tensor_a_gpu_list,
            torch_tensor_b_gpu_list,
            torch_tensors_c_uc_per_peer_grouped,
            torch_tensors_c_mc_per_peer_grouped,
            torch_tensor_comm_out_gpu,
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
    all_reduce: str = "Lamport",
    benchmark_or_test: str = "test",
    use_cuda_graph: bool = False,
    csv_report: str = "./csv_report.csv",
):
    """Top-level Lamport entry point. Initializes distributed, dispatches to
    the test or benchmark driver, and tears distributed down on exit.

    ``benchmark_or_test`` selects the mode:
      - ``"test"``: single-launch correctness check via run_distributed_test.
      - ``"benchmark"``: cudaEvent timing + per-rank CSV on the supplied config.
      - ``"benchmark_all"``: sweep across kernel-config variants, one row per
        candidate in the per-rank CSV.
    """
    global_rank, world_size, device = init_distributed()

    if all_reduce == "Lamport":
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
    all_reduce: str = "Lamport",
):
    # * CUDA *
    # Non-default stream as we'll use CUDA graphs
    torch_stream = torch.cuda.Stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)

    # * Build GEMM AllReduce Object *
    gemm_all_reduce = Sm100PersistentDenseGemmAllReduceLamportKernel(
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
        world_size=world_size,
        global_rank=global_rank,
        device=device,
        slot_init_mode="test",
    )
    cute_tensor_a = tensors["cute_tensor_a_list"][0]
    cute_tensor_b = tensors["cute_tensor_b_list"][0]
    cute_tensors_c_uc_per_peer_grouped = tensors["cute_tensors_c_uc_per_peer_grouped"]
    cute_tensors_c_mc_per_peer_grouped = tensors["cute_tensors_c_mc_per_peer_grouped"]
    cute_tensor_comm_out_uc = tensors["cute_tensor_comm_out_uc"]
    torch_tensor_a_cpu = tensors["torch_tensor_a_cpu"]
    torch_tensor_b_cpu = tensors["torch_tensor_b_cpu"]
    torch_tensors_c_uc_per_peer_grouped = tensors["torch_tensors_c_uc_per_peer_grouped"]
    torch_tensor_comm_out = tensors["torch_tensor_comm_out_gpu"]

    # Test mode: ping=0, pong=1. Slot[0]/slot[1] indexing is inlined at the
    # cute.compile / compiled_gemm call sites rather than hoisted into locals
    # so the slot semantics stay visible at the kernel boundary.
    compiled_gemm = cute.compile(
        gemm_all_reduce,
        a=cute_tensor_a,
        b=cute_tensor_b,
        c_multicast_tensor=cute_tensors_c_mc_per_peer_grouped[0][global_rank],
        comm_in_unicast_tensor_per_peer=cute_tensors_c_uc_per_peer_grouped[0],
        comm_clear_unicast_tensor_per_peer=cute_tensors_c_uc_per_peer_grouped[1],
        comm_out_unicast_tensor=cute_tensor_comm_out_uc,
        stream=stream,
        max_active_clusters=utils.HardwareInfo().get_max_active_clusters(
            cluster_shape_mn[0] * cluster_shape_mn[1]
        ),
    )
    compiled_gemm(
        a=cute_tensor_a,
        b=cute_tensor_b,
        c_multicast_tensor=cute_tensors_c_mc_per_peer_grouped[0][global_rank],
        comm_in_unicast_tensor_per_peer=cute_tensors_c_uc_per_peer_grouped[0],
        comm_clear_unicast_tensor_per_peer=cute_tensors_c_uc_per_peer_grouped[1],
        comm_out_unicast_tensor=cute_tensor_comm_out_uc,
        stream=stream,
    )

    # * Compare *
    # FP8 nan to saturate
    def _fp8_nan_to_saturate(tensor_fp8: torch.Tensor) -> torch.Tensor:
        if tensor_fp8.dtype == torch.float8_e4m3fn:
            tensor_u8 = tensor_fp8.view(torch.uint8)
            is_pos_nan = tensor_u8 == 0x7F
            is_neg_nan = tensor_u8 == 0xFF
            tensor_f32 = tensor_fp8.to(dtype=torch.float32)
            tensor_f32[is_pos_nan] = 448
            tensor_f32[is_neg_nan] = -448
            return tensor_f32.to(dtype=tensor_fp8.dtype)
        if tensor_fp8.dtype == torch.float8_e5m2:
            tensor_u8 = tensor_fp8.view(torch.uint8)
            is_pos_nan = tensor_u8 == 0x7F
            is_neg_nan = tensor_u8 == 0xFF
            tensor_f32 = tensor_fp8.to(dtype=torch.float32)
            tensor_f32[is_pos_nan] = 57344
            tensor_f32[is_neg_nan] = -57344
            return tensor_f32.to(dtype=tensor_fp8.dtype)
        return tensor_fp8

    def _compare_gemm(
        torch_tensor_a_cpu: torch.Tensor,
        torch_tensor_b_cpu: torch.Tensor,
        torch_tensor_c: torch.Tensor,
        c_dtype: Type[cutlass.Numeric],
        atol: float,
        rtol: float,
    ):
        gemm_ref_f32 = torch.einsum(
            "mkl,nkl->mnl",
            torch_tensor_a_cpu.to(dtype=torch.float32),
            torch_tensor_b_cpu.to(dtype=torch.float32),
        )
        if c_dtype == cutlass.Float8E4M3FN:
            gemm_ref_f32 = torch.clamp(gemm_ref_f32, min=-448, max=448)
            gemm_ref_f32_c = gemm_ref_f32.to(dtype=torch_dtype(c_dtype))
        elif c_dtype == cutlass.Float8E5M2:
            gemm_ref_f32 = torch.clamp(gemm_ref_f32, min=-57344, max=57344)
            gemm_ref_f32_c = gemm_ref_f32.to(dtype=torch_dtype(c_dtype))
        else:
            gemm_ref_f32_c = gemm_ref_f32.to(dtype=torch_dtype(c_dtype))
        gemm_ref_f32_c_f32 = gemm_ref_f32_c.to(dtype=torch.float32)
        gemm_out_f32 = torch_tensor_c.cpu().to(dtype=torch.float32)
        torch.testing.assert_close(
            gemm_out_f32, gemm_ref_f32_c_f32, atol=atol, rtol=rtol
        )

    def _compare_comm(
        torch_tensor_comm_in: torch.Tensor,
        torch_tensor_comm_out: torch.Tensor,
        c_dtype: Type[cutlass.Numeric],
        atol: float,
        rtol: float,
    ):
        comm_ref = torch_tensor_comm_in
        dist.barrier()
        if c_dtype in [cutlass.Float32, cutlass.BFloat16, cutlass.Float16]:
            comm_ref = comm_ref.contiguous()
            dist.all_reduce(comm_ref, op=torch.distributed.ReduceOp.SUM)
            comm_ref_f32 = comm_ref.to(dtype=torch.float32).cpu()
        elif c_dtype in [cutlass.Float8E4M3FN, cutlass.Float8E5M2]:
            comm_ref_fp32_acc = comm_ref.to(dtype=torch.float32).contiguous()
            dist.all_reduce(comm_ref_fp32_acc, op=torch.distributed.ReduceOp.SUM)
            epsilon = 1e-2
            comm_ref_c = (comm_ref_fp32_acc + epsilon).to(dtype=torch_dtype(c_dtype))
            comm_ref_nan2sat = _fp8_nan_to_saturate(comm_ref_c)
            comm_ref_f32 = comm_ref_nan2sat.to(dtype=torch.float32).cpu()

        comm_out = torch_tensor_comm_out.cpu()
        if c_dtype in [cutlass.Float8E4M3FN, cutlass.Float8E5M2]:
            comm_out = _fp8_nan_to_saturate(comm_out)
        comm_out_f32 = comm_out.to(dtype=torch.float32)
        torch.testing.assert_close(comm_ref_f32, comm_out_f32, atol=atol, rtol=rtol)

    def _compare_buffer_clear(
        torch_tensors_c_uc_per_peer_for_slot: Tuple[torch.Tensor, ...],
        slot_idx: int,
        c_dtype,
    ):
        # Lamport litmus test: after the kernel consumes slot[ping], slot[pong]
        # must be byte-exact -0.0 across every per-peer slab (sentinel pattern
        # mirrors the AR kernel's neg_zero_dtype_32bit table).
        if c_dtype is cutlass.Float32:
            view_dtype, sentinel, hex_width = torch.int32, -0x80000000, 8
        elif c_dtype is cutlass.Float16 or c_dtype is cutlass.BFloat16:
            view_dtype, sentinel, hex_width = torch.int16, -0x8000, 4
        elif c_dtype is cutlass.Float8E4M3FN or c_dtype is cutlass.Float8E5M2:
            view_dtype, sentinel, hex_width = torch.uint8, 0x80, 2
        else:
            raise AssertionError(
                f"_compare_buffer_clear: unsupported c_dtype {c_dtype}"
            )
        mask = (1 << (hex_width * 4)) - 1
        sentinel_hex = f"0x{sentinel & mask:0{hex_width}x}"

        for p, slab in enumerate(torch_tensors_c_uc_per_peer_for_slot):
            elements = slab.contiguous().cpu().view(view_dtype)
            if not bool((elements == sentinel).all().item()):
                bad_idx = (elements != sentinel).nonzero(as_tuple=False)[0].tolist()
                bad_val = int(elements[tuple(bad_idx)].item()) & mask
                raise AssertionError(
                    f"comm_in slot[{slot_idx}][{p}] not cleared to "
                    f"-0.0 sentinel: element at {bad_idx} = "
                    f"0x{bad_val:0{hex_width}x} (expected {sentinel_hex}). "
                    f"Kernel-side buffer-clear pass not yet wired."
                )

    torch_tensor_c_local_slot = torch_tensors_c_uc_per_peer_grouped[0][global_rank]

    # compare
    # Impose a strict check on GEMM as input is uniform random int
    gemm_atol = 1e-05
    gemm_rtol = 1e-05
    _compare_gemm(
        torch_tensor_a_cpu=torch_tensor_a_cpu,
        torch_tensor_b_cpu=torch_tensor_b_cpu,
        torch_tensor_c=torch_tensor_c_local_slot,
        c_dtype=c_dtype,
        atol=gemm_atol,
        rtol=gemm_rtol,
    )

    if all_reduce != "none":
        # Relaxed tolerance — _compare_comm uses NCCL dist.all_reduce, which
        # reduces in a different order than the fused multimem kernel.
        comm_rtol = 1e-1
        comm_atol = 5
        if c_dtype in [cutlass.Float8E4M3FN, cutlass.Float8E5M2]:
            comm_rtol = 1e-1
            comm_atol = 0.0
        _compare_comm(
            torch_tensor_comm_in=torch_tensor_c_local_slot,
            torch_tensor_comm_out=torch_tensor_comm_out,
            c_dtype=c_dtype,
            atol=comm_atol,
            rtol=comm_rtol,
        )

    # * Check slot[pong] cleared *
    # Lamport scrubs slot[1] back to -0.0 after consuming slot[0]; verify here.
    if all_reduce == "Lamport":
        _compare_buffer_clear(
            torch_tensors_c_uc_per_peer_grouped[1],
            slot_idx=1,
            c_dtype=c_dtype,
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
    """Compile one Lamport candidate, time warmup + benchmark with slot rotation.

    Slot rotation is:

        signal = i (per-iteration counter)
        ping    = signal       % NUM_C_BUFFERS    # this iter's read+write+epi target
        pong    = (signal + 1) % NUM_C_BUFFERS    # this iter's clear target
        cooling = (signal + 2) % NUM_C_BUFFERS    # untouched (draining)

    ``num_workspace`` is locked to ``len(cute_tensors_c_uc_per_peer_grouped)``
    so the A/B ring buffer rotates in lockstep with the slot rotation —
    a single set of NUM_C_BUFFERS captured CUDA graphs covers both.

    Returns the mean per-iteration time in microseconds (warmup excluded).
    """
    cute_tensor_a_list = tensors["cute_tensor_a_list"]
    cute_tensor_b_list = tensors["cute_tensor_b_list"]
    cute_tensors_c_uc_per_peer_grouped = tensors["cute_tensors_c_uc_per_peer_grouped"]
    cute_tensors_c_mc_per_peer_grouped = tensors["cute_tensors_c_mc_per_peer_grouped"]
    cute_tensor_comm_out_uc = tensors["cute_tensor_comm_out_uc"]

    num_c_buffers = len(cute_tensors_c_uc_per_peer_grouped)
    assert num_workspace == num_c_buffers, (
        f"compile_and_benchmark requires num_workspace == NUM_C_BUFFERS "
        f"({num_c_buffers}) so the A/B ring buffer rotates in lockstep "
        f"with the Lamport slot rotation; got num_workspace={num_workspace}."
    )

    # Build kernel + can_implement first — before any cross-rank op, so a
    # deterministic skip keeps all ranks in lockstep for the next candidate.
    gemm_all_reduce = Sm100PersistentDenseGemmAllReduceLamportKernel(
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

    def make_kernel_kwargs(i):
        ping = i % num_c_buffers
        pong = (i + 1) % num_c_buffers
        return dict(
            a=cute_tensor_a_list[i % num_workspace],
            b=cute_tensor_b_list[i % num_workspace],
            c_multicast_tensor=cute_tensors_c_mc_per_peer_grouped[ping][global_rank],
            comm_in_unicast_tensor_per_peer=cute_tensors_c_uc_per_peer_grouped[ping],
            comm_clear_unicast_tensor_per_peer=cute_tensors_c_uc_per_peer_grouped[pong],
            comm_out_unicast_tensor=cute_tensor_comm_out_uc,
            stream=stream,
        )

    kernel_kwargs_list = [make_kernel_kwargs(i) for i in range(num_c_buffers)]

    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )
    compiled_gemm = cute.compile(
        gemm_all_reduce,
        **kernel_kwargs_list[0],
        max_active_clusters=max_active_clusters,
    )

    # Under --use_cuda_graph capture NUM_C_BUFFERS graphs (one per slot
    # rotation — pointers are baked at capture time). Without it dispatch
    # the compiled kernel directly with the rotated kwargs.
    if use_cuda_graph:
        graphs = []
        for r in range(num_c_buffers):
            g = torch.cuda.CUDAGraph()
            with torch.cuda.graph(g, stream=torch_stream):
                compiled_gemm(**kernel_kwargs_list[r])
            graphs.append(g)

        def run_one_iter(i):
            graphs[i % num_c_buffers].replay()
    else:

        def run_one_iter(i):
            compiled_gemm(**kernel_kwargs_list[i % num_c_buffers])

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
    all_reduce: str = "Lamport",
    use_cuda_graph: bool = False,
    benchmark_all: bool = False,
    csv_report: str = "./csv_report.csv",
):
    """Lamport benchmark driver — single config or full sweep + per-rank CSV.

    All allocations happen once up front; the A/B ring buffer length is
    locked to ``len(cute_tensors_c_uc_per_peer_grouped)`` so a single set
    of captured CUDA graphs covers both A/B and slot rotations.

    --benchmark_all sweeps raster ∈ {m, n}, swizzle ∈ {1, 2, 4, 8}, and the
    (use_2cta_instrs, cluster_shape_mn, mma_tiler_mn) joint variants from
    the LDMCxSTMC sweep list (cluster_m ∈ {2,4,8} requires 2cta).

    Lamport rejects use_tma_store=False at the kernel layer, so the
    candidate list keeps the user-supplied value rather than sweeping it.
    """
    # NUM_C_BUFFERS = 3 is fixed inside allocate_tensors. num_workspace is
    # locked to the same value here so the A/B ring rotates in lockstep
    # with the slot rotation. The compile_and_benchmark assert below
    # enforces the invariant against whatever allocate_tensors returns.
    num_workspace = 3
    tensors = allocate_tensors(
        mnkl=mnkl,
        ab_dtype=ab_dtype,
        c_dtype=c_dtype,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
        num_workspace=num_workspace,
        world_size=world_size,
        global_rank=global_rank,
        device=device,
        slot_init_mode="benchmark",
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
        help="Capture one CUDA graph per slot rotation (3) and replay per iteration",
    )
    parser.add_argument(
        "--all_reduce",
        choices=["Lamport", "none"],
        type=str,
        default="Lamport",
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
    )
    rank = int(os.environ["RANK"])
    local_rank = int(os.environ["LOCAL_RANK"])
    print(
        f"PASS (hostname={socket.gethostname()}, global_rank={rank}, local_rank={local_rank})",
        flush=True,
    )
