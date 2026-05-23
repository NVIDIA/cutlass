# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""Minimal SM120 MXF4/NVFP4 native-TMA microtile smoke example.

This module exposes a callable JIT entry point. The corresponding pytest smoke
test demonstrates invocation and checks the fixed instruction mix.
"""

from typing import Optional

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass.cute.nvgpu import cpasync, warp
from cutlass.cutlass_dsl import dsl_user_op
from cutlass.utils.gemm import sm120
from cutlass.utils.gemm.sm120.constants import (
    MXF4NVF4_SCALE_TMA_BYTES,
    mxf4nvf4_full_tma_bytes,
)
from cutlass.utils.smem_allocator import SmemAllocator

_MXF4NVF4_SCALE_INTERLEAVED_K64_BYTES = MXF4NVF4_SCALE_TMA_BYTES // 2
_SM120_MXF4NVF4_MICROTILE_SMEM_BYTES = 49152


@dsl_user_op
def _issue_tma_load(
    tma_atom: cute.CopyAtom,
    tma_tensor: cute.Tensor,
    smem_tensor: cute.Tensor,
    tma_bar_ptr: cute.Pointer,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    tS, tG = cpasync.tma_partition(
        tma_atom,
        0,
        cute.make_layout(1, loc=loc, ip=ip),
        cute.group_modes(smem_tensor, 0, cute.rank(smem_tensor) - 1, loc=loc, ip=ip),
        cute.group_modes(tma_tensor, 0, cute.rank(tma_tensor), loc=loc, ip=ip),
        loc=loc,
        ip=ip,
    )
    cute.copy(
        tma_atom,
        tG,
        tS[(None, 0)],
        tma_bar_ptr=tma_bar_ptr,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def _load_ab_k_block(
    tiled_mma: cute.TiledMma,
    sA: cute.Tensor,
    sB: cute.Tensor,
    a_frag: cute.Tensor,
    b_frag: cute.Tensor,
    tidx: cutlass.Int32,
    k_block: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    copy_atom = cute.make_copy_atom(
        warp.LdMatrix8x8x16bOp(transpose=False, num_matrices=4),
        cutlass.Float4E2M1FN,
        loc=loc,
        ip=ip,
    )
    tiled_copy_a = cute.make_tiled_copy_A(copy_atom, tiled_mma, loc=loc, ip=ip)
    tiled_copy_b = cute.make_tiled_copy_B(copy_atom, tiled_mma, loc=loc, ip=ip)
    thr_copy_a = tiled_copy_a.get_slice(tidx)
    thr_copy_b = tiled_copy_b.get_slice(tidx)
    sA_src = cute.as_position_independent_swizzle_tensor(sA, loc=loc, ip=ip)
    sB_src = cute.as_position_independent_swizzle_tensor(sB, loc=loc, ip=ip)
    tCsA = thr_copy_a.partition_S(sA_src, loc=loc, ip=ip)
    tCsB = thr_copy_b.partition_S(sB_src, loc=loc, ip=ip)
    tCrA = thr_copy_a.retile(a_frag, loc=loc, ip=ip)
    tCrB = thr_copy_b.retile(b_frag, loc=loc, ip=ip)
    tCsA_stage = tCsA[(None, None, None, 0)]
    tCsB_stage = tCsB[(None, None, None, 0)]
    cute.copy(
        tiled_copy_a,
        tCsA_stage[(None, None, k_block)],
        tCrA[(None, None, k_block)],
        loc=loc,
        ip=ip,
    )
    cute.copy(
        tiled_copy_b,
        tCsB_stage[(None, None, k_block)],
        tCrB[(None, None, k_block)],
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def _load_uniform_scale_fragment_from_first_scale_column(
    scale_smem: cute.Tensor,
    is_sfa: cutlass.Constexpr[bool],
    k_block: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Tensor:
    """Load a scale fragment for this uniform-scale microtile only.

    This intentionally reads the first compact FP8 scale column for each K64
    half. It is not a general SM120 scale-fragment partitioner.
    """
    if is_sfa:
        scale_frag = warp.make_mxf4nvf4_sfa_fragment(loc=loc, ip=ip)
    else:
        scale_frag = warp.make_mxf4nvf4_sfb_fragment(loc=loc, ip=ip)
    scale_src = cute.recast_tensor(
        cute.make_tensor(
            scale_smem.iterator + k_block * _MXF4NVF4_SCALE_INTERLEAVED_K64_BYTES,
            cute.make_layout(4, loc=loc, ip=ip),
        ),
        cutlass.Float8E4M3FN,
        loc=loc,
        ip=ip,
    )
    cute.filter_zeros(scale_frag, loc=loc, ip=ip).store(
        scale_src.load(loc=loc, ip=ip), loc=loc, ip=ip
    )
    return scale_frag


@dsl_user_op
def _store_accumulator(
    thr_mma: cute.ThrMma,
    acc: cute.Tensor,
    out: cute.Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    tDgD = thr_mma.partition_C(out, loc=loc, ip=ip)
    rD = cute.make_rmem_tensor(acc.layout, out.element_type, loc=loc, ip=ip)
    rD.store(acc.load(loc=loc, ip=ip).to(out.element_type), loc=loc, ip=ip)
    copy_atom = cute.make_copy_atom(
        cute.nvgpu.CopyUniversalOp(), out.element_type, loc=loc, ip=ip
    )
    cute.copy(copy_atom, rD, tDgD, loc=loc, ip=ip)


@cute.jit
def sm120_mxf4nvf4_native_tma_microtile(
    a: cute.Tensor,
    b: cute.Tensor,
    sfa: cute.Tensor,
    sfb: cute.Tensor,
    d: cute.Tensor,
    stream: cuda.CUstream = cuda.CUstream(0),
):
    """Compute one 16x8 output microtile from a native-TMA SM120 K128 tile."""
    gSFA = cute.make_tensor(
        sfa.iterator,
        sm120.make_mxf4nvf4_scale_interleaved_gmem_layout(128, 128, 1),
    )
    gSFB = cute.make_tensor(
        sfb.iterator,
        sm120.make_mxf4nvf4_scale_interleaved_gmem_layout(128, 128, 1),
    )
    (
        tma_atom_a,
        tma_tensor_a,
        tma_atom_b,
        tma_tensor_b,
        tma_atom_sfa,
        tma_tensor_sfa,
        tma_atom_sfb,
        tma_tensor_sfb,
    ) = sm120.make_mxf4nvf4_native_tma_atoms(
        a,
        b,
        gSFA,
        gSFB,
        ab_smem_format="packed",
        ab_tile_coord=(0, 0, 0),
        scale_tile_coord=(0, 0, 0, 0),
    )

    _sm120_mxf4nvf4_native_tma_microtile_kernel(
        tma_atom_a,
        tma_tensor_a,
        tma_atom_b,
        tma_tensor_b,
        tma_atom_sfa,
        tma_tensor_sfa,
        tma_atom_sfb,
        tma_tensor_sfb,
        d,
    ).launch(
        grid=[1, 1, 1],
        block=[32, 1, 1],
        stream=stream,
        smem=_SM120_MXF4NVF4_MICROTILE_SMEM_BYTES,
    )


@cute.kernel
def _sm120_mxf4nvf4_native_tma_microtile_kernel(
    tma_atom_a: cute.CopyAtom,
    tma_tensor_a: cute.Tensor,
    tma_atom_b: cute.CopyAtom,
    tma_tensor_b: cute.Tensor,
    tma_atom_sfa: cute.CopyAtom,
    tma_tensor_sfa: cute.Tensor,
    tma_atom_sfb: cute.CopyAtom,
    tma_tensor_sfb: cute.Tensor,
    d: cute.Tensor,
):
    tidx, _, _ = cute.arch.thread_idx()

    @cute.struct
    class SharedStorage:
        tma_barrier: cute.struct.MemRange[cutlass.Int64, 1]

    smem = SmemAllocator()
    storage = smem.allocate(SharedStorage)
    sA, sB, sSFA, sSFB = sm120.make_mxf4nvf4_native_tma_smem_views(
        smem,
        ab_smem_format="packed",
    )
    tma_bar_ptr = storage.tma_barrier.data_ptr()

    with cute.arch.elect_one():
        cute.arch.mbarrier_init(tma_bar_ptr, 1)
        cute.arch.mbarrier_expect_tx(
            tma_bar_ptr, mxf4nvf4_full_tma_bytes("packed")
        )
    cute.arch.mbarrier_init_fence()
    cute.arch.barrier()

    _issue_tma_load(tma_atom_a, tma_tensor_a, sA, tma_bar_ptr)
    _issue_tma_load(tma_atom_b, tma_tensor_b, sB, tma_bar_ptr)
    _issue_tma_load(tma_atom_sfa, tma_tensor_sfa, sSFA, tma_bar_ptr)
    _issue_tma_load(tma_atom_sfb, tma_tensor_sfb, sSFB, tma_bar_ptr)
    with cute.arch.elect_one():
        cute.arch.mbarrier_arrive(tma_bar_ptr)

    cute.arch.mbarrier_wait(tma_bar_ptr, 0)
    cute.arch.barrier()

    tiled_mma = sm120.make_mxf4nvf4_tiled_mma(atom_layout_mnk=(1, 1, 1))
    thr_mma = tiled_mma.get_slice(tidx)
    tCsA_mma = thr_mma.partition_A(sA)
    tCsB_mma = thr_mma.partition_B(sB)
    a_frag = tiled_mma.make_fragment_A(tCsA_mma[None, None, None, 0])
    b_frag = tiled_mma.make_fragment_B(tCsB_mma[None, None, None, 0])
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    acc.fill(0.0)

    for k_block in range(2):
        _load_ab_k_block(tiled_mma, sA, sB, a_frag, b_frag, tidx, k_block)
        sfa_frag = _load_uniform_scale_fragment_from_first_scale_column(
            sSFA, True, k_block
        )
        sfb_frag = _load_uniform_scale_fragment_from_first_scale_column(
            sSFB, False, k_block
        )
        cute.gemm(
            tiled_mma,
            acc,
            (a_frag[(None, 0, k_block)], sfa_frag),
            (b_frag[(None, 0, k_block)], sfb_frag),
            acc,
        )

    _store_accumulator(thr_mma, acc, d)
