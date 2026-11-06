# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""
Unit tests for ``cutlass.Pointer`` TMA descriptors passed via ``tma_desc_ptr``.

``cutlass.experimental.cuda.TensorMap.get_ptr()`` returns a ``cutlass.Pointer``,
not a cute pointer. ``cute.copy`` used to set the descriptor-pointer field only
for cute pointers, so such a descriptor was silently dropped and the copy ran
with the descriptor baked into the atom. Any other non-pointer value was
dropped the same way. ``cute.copy`` now honours a ``cutlass.Pointer`` and
raises ``TypeError`` for values that are not pointers.

One CTA TMA-loads a 64x64 fp32 tile. The atom's descriptor is based at ``x``
and the override descriptor at ``z``, so an honoured override gives ``y == z``.
"""

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass import Float32, Int64
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import from_dlpack
from cutlass.experimental.cuda import TensorMap, create_tensor_map_tiled_from_view
from cutlass.memory import SmemAllocator

M, N = 64, 64


@cute.kernel
def _load_tile(
    atom: cute.CopyAtom,
    mX: cute.Tensor,
    y: cute.Tensor,
    desc: cutlass.GridConstant[TensorMap],
    mode: cutlass.Constexpr[str],
):
    tidx, _, _ = cute.arch.thread_idx()
    smem = SmemAllocator()
    sX = smem.allocate_tensor(
        Float32, cute.make_layout((M, N, 1), stride=(N, 1, M * N)), 128
    )
    bar = smem.allocate_array(Int64, 1)

    gX = cute.local_tile(mX, (M, N), (None, None))
    tXsX, tXgX = cpasync.tma_partition(
        atom,
        0,
        cute.make_layout(1),
        cute.group_modes(sX, 0, 2),
        cute.group_modes(gX, 0, 2),
    )

    if tidx == 0:
        cute.arch.mbarrier_init(bar, 1)
        cute.arch.mbarrier_init_fence()
    cute.arch.sync_threads()
    if tidx == 0:
        cute.arch.mbarrier_arrive_and_expect_tx(bar, M * N * 4)
    if tidx < 32:  # whole warp: the TMA copy elects one lane itself
        if cutlass.const_expr(mode == "baked"):
            cute.copy(atom, tXgX[(None, 0, 0)], tXsX[(None, 0)], tma_bar_ptr=bar)
        elif cutlass.const_expr(mode == "get_ptr"):
            cute.copy(
                atom,
                tXgX[(None, 0, 0)],
                tXsX[(None, 0)],
                tma_bar_ptr=bar,
                tma_desc_ptr=desc.get_ptr(),
            )
        else:
            cute.copy(
                atom,
                tXgX[(None, 0, 0)],
                tXsX[(None, 0)],
                tma_bar_ptr=bar,
                tma_desc_ptr=Int64(0),
            )
    cute.arch.mbarrier_wait(bar, 0)
    for m in cutlass.range(M, unroll_full=True):
        y[m, tidx] = sX[m, tidx, 0]


@cute.jit
def _run(x: cute.Tensor, z: cute.Tensor, y: cute.Tensor, mode: cutlass.Constexpr[str]):
    atom, mX = cpasync.make_tiled_tma_atom(
        cpasync.CopyBulkTensorTileG2SOp(),
        x,
        cute.make_layout((M, N), stride=(N, 1)),
        (M, N),
    )
    # same box as the atom, based at z
    desc = create_tensor_map_tiled_from_view(z, box_dims=(M, N))
    _load_tile(atom, mX, y, desc, mode).launch(
        grid=(1, 1, 1), block=(N, 1, 1), smem=M * N * 4 + 1024
    )


def _has_tma():
    return torch.cuda.is_available() and torch.cuda.get_device_capability()[0] >= 9


@unittest.skipUnless(_has_tma(), "requires a CUDA device with TMA (sm_90+)")
class TestTmaDescPtrCutlassPointer(unittest.TestCase):
    def setUp(self):
        self.x = torch.arange(M * N, dtype=torch.float32, device="cuda").reshape(M, N)
        self.z = -self.x - 1
        self.y = torch.zeros_like(self.x)
        self.args = (
            from_dlpack(self.x, assumed_align=16),
            from_dlpack(self.z, assumed_align=16),
            from_dlpack(self.y, assumed_align=16),
        )

    def _load(self, mode):
        cute.compile(_run, *self.args, mode)(*self.args)
        torch.cuda.synchronize()

    def test_baked_descriptor(self):
        self._load("baked")
        self.assertTrue(torch.equal(self.y, self.x))

    def test_tensormap_get_ptr_is_honoured(self):
        self._load("get_ptr")
        self.assertTrue(torch.equal(self.y, self.z))

    def test_non_pointer_is_rejected(self):
        with self.assertRaisesRegex(TypeError, "pointer to a TMA descriptor"):
            cute.compile(_run, *self.args, "int")


if __name__ == "__main__":
    unittest.main()
