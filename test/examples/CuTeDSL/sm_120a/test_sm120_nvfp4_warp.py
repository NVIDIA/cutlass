# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import pytest
import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu import warp
from cutlass.cute.runtime import from_dlpack


pytestmark = [pytest.mark.arch(["120a"])]


@cute.kernel
def _sm120_mxf4nvf4_mma_unpack_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()

    mma_op = warp.MmaMXF4NVF4Op(
        cutlass.Float4E2M1FN, cutlass.Float32, cutlass.Float8E4M3FN
    )
    tiled_mma = cute.make_tiled_mma(mma_op)

    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(
        tiled_mma.partition_shape_C((16, 8)), cutlass.Float32
    )
    sfa = warp.make_mxf4nvf4_sfa_fragment()
    sfb = warp.make_mxf4nvf4_sfb_fragment()

    cute.recast_tensor(a, cutlass.Int32).fill(0x22222222)
    cute.recast_tensor(b, cutlass.Int32).fill(0x22222222)
    acc.fill(0.0)
    sfa.fill(1.0)
    sfb.fill(1.0)

    warp.mma_unpack(tiled_mma, acc, (a, sfa), (b, sfb), acc)

    acc_size = cute.size(acc)
    for i in cutlass.range(acc_size, unroll_full=True):
        out[tidx * acc_size + i] = acc[i]


@cute.kernel
def _sm120_mxf4nvf4_gemm_sequence_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()

    mma_op = warp.MmaMXF4NVF4Op(
        cutlass.Float4E2M1FN, cutlass.Float32, cutlass.Float8E4M3FN
    )
    tiled_mma = cute.make_tiled_mma(mma_op)

    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(
        tiled_mma.partition_shape_C((16, 8)), cutlass.Float32
    )
    sfa = warp.make_mxf4nvf4_sfa_fragment()
    sfb = warp.make_mxf4nvf4_sfb_fragment()

    cute.recast_tensor(a, cutlass.Int32).fill(0x22222222)
    cute.recast_tensor(b, cutlass.Int32).fill(0x22222222)
    acc.fill(0.0)
    sfa.fill(1.0)
    sfb.fill(1.0)

    cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)

    acc_size = cute.size(acc)
    for i in cutlass.range(acc_size, unroll_full=True):
        out[tidx * acc_size + i] = acc[i]


@cute.jit
def _launch_mma_unpack(out: cute.Tensor):
    _sm120_mxf4nvf4_mma_unpack_kernel(out).launch(
        grid=[1, 1, 1], block=[32, 1, 1]
    )


@cute.jit
def _launch_gemm_sequence(out: cute.Tensor):
    _sm120_mxf4nvf4_gemm_sequence_kernel(out).launch(
        grid=[1, 1, 1], block=[32, 1, 1]
    )


def _run_kernel(host_fn):
    out = torch.zeros(128, device="cuda", dtype=torch.float32)
    out_cute = from_dlpack(out)

    cute.compile(host_fn, out_cute)(out_cute)
    torch.cuda.synchronize()
    return out


def test_sm120_mxf4nvf4_mma_unpack_accumulates_64():
    out = _run_kernel(_launch_mma_unpack)
    torch.testing.assert_close(out, torch.full_like(out, 64.0), rtol=0, atol=0)


def test_sm120_mxf4nvf4_gemm_sequence_accumulates_64():
    out = _run_kernel(_launch_gemm_sequence)
    torch.testing.assert_close(out, torch.full_like(out, 64.0), rtol=0, atol=0)


def test_sm120_fp4_ldmatrix_unpack_atom_is_exported():
    op = warp.LdMatrix8x16x8bOp(num_matrices=1, unpack_bits=4)

    assert op.unpack_bits == 4
