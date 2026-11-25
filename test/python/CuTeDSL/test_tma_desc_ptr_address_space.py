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
Unit tests for the address space of the ``tma_desc_ptr`` kw argument of TMA copies.

The TMA instructions take the descriptor as a generic address. A gmem-space cute
pointer -- the default of ``TensorMapManager.get_tensormap_ptr`` -- used to pass
the Python checks of ``cute.copy`` and then fail in libNVVM with ``Call parameter
type does not match function signature!``; a pointer in any other address space
failed later with an internal IR verification error. ``cute.copy`` now converts a
gmem descriptor pointer to generic, and rejects other address spaces with a
``ValueError``.

One CTA TMA-loads a 64x64 fp32 tile through a global-memory copy of the atom's
descriptor, addressed through the pointer under test.
"""

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass import Float32, Int64
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import from_dlpack
from cutlass.memory import SmemAllocator
from cutlass.tensor_utils import TensorMapManager, TensorMapUpdateMode

M, N = 64, 64
TENSORMAP_BYTES = 128


@cute.kernel
def _load_tile(
    atom: cute.CopyAtom,
    mX: cute.Tensor,
    y: cute.Tensor,
    ws: cute.Tensor,
    space: cutlass.Constexpr[str],
):
    tidx, _, _ = cute.arch.thread_idx()
    smem = SmemAllocator()
    sX = smem.allocate_tensor(
        Float32, cute.make_layout((M, N, 1), stride=(N, 1, M * N)), 128
    )
    bar = smem.allocate_array(Int64, 1)
    smem_desc = smem.allocate_array(
        Int64, TENSORMAP_BYTES // 8, byte_alignment=TENSORMAP_BYTES
    )

    gX = cute.local_tile(mX, (M, N), (None, None))
    tXsX, tXgX = cpasync.tma_partition(
        atom,
        0,
        cute.make_layout(1),
        cute.group_modes(sX, 0, 2),
        cute.group_modes(gX, 0, 2),
    )

    tm = TensorMapManager(TensorMapUpdateMode.GMEM, TENSORMAP_BYTES)
    # default address_space is AddressSpace.gmem -- the form copy_tensormap needs
    desc = tm.get_tensormap_ptr(ws.iterator)
    if cutlass.const_expr(space == "generic"):
        copy_desc = tm.get_tensormap_ptr(desc, cute.AddressSpace.generic)
    elif cutlass.const_expr(space == "gmem"):
        copy_desc = desc
    else:
        copy_desc = smem_desc

    if tidx == 0:
        cpasync.copy_tensormap(atom, desc)
        cpasync.fence_tma_desc_release()
        cute.arch.mbarrier_init(bar, 1)
        cute.arch.mbarrier_init_fence()
    cute.arch.sync_threads()
    if tidx == 0:
        cute.arch.mbarrier_arrive_and_expect_tx(bar, M * N * 4)
    if tidx < 32:  # whole warp: the TMA copy elects one lane itself
        cpasync.fence_tma_desc_acquire(desc)
        cute.copy(
            atom,
            tXgX[(None, 0, 0)],
            tXsX[(None, 0)],
            tma_bar_ptr=bar,
            tma_desc_ptr=copy_desc,
        )
    cute.arch.mbarrier_wait(bar, 0)
    for m in cutlass.range(M, unroll_full=True):
        y[m, tidx] = sX[m, tidx, 0]


@cute.jit
def _run(
    x: cute.Tensor, y: cute.Tensor, ws: cute.Tensor, space: cutlass.Constexpr[str]
):
    atom, mX = cpasync.make_tiled_tma_atom(
        cpasync.CopyBulkTensorTileG2SOp(),
        x,
        cute.make_layout((M, N), stride=(N, 1)),
        (M, N),
    )
    _load_tile(atom, mX, y, ws, space).launch(
        grid=(1, 1, 1), block=(N, 1, 1), smem=M * N * 4 + 4 * TENSORMAP_BYTES
    )


def _has_tma():
    return torch.cuda.is_available() and torch.cuda.get_device_capability()[0] >= 9


@unittest.skipUnless(_has_tma(), "requires a CUDA device with TMA (sm_90+)")
class TestTmaDescPtrAddressSpace(unittest.TestCase):
    def setUp(self):
        self.x = torch.arange(M * N, dtype=torch.float32, device="cuda").reshape(M, N)
        self.y = torch.zeros_like(self.x)
        self.ws = torch.zeros(TENSORMAP_BYTES // 8, dtype=torch.int64, device="cuda")
        self.args = (
            from_dlpack(self.x, assumed_align=16),
            from_dlpack(self.y, assumed_align=16),
            from_dlpack(self.ws, assumed_align=TENSORMAP_BYTES),
        )

    def _load_through(self, space):
        cute.compile(_run, *self.args, space)(*self.args)
        torch.cuda.synchronize()
        self.assertTrue(torch.equal(self.y, self.x))

    def test_generic_descriptor_pointer(self):
        self._load_through("generic")

    def test_gmem_descriptor_pointer_is_converted_to_generic(self):
        self._load_through("gmem")

    def test_other_address_space_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "generic or gmem address space"):
            cute.compile(_run, *self.args, "smem")


if __name__ == "__main__":
    unittest.main()
