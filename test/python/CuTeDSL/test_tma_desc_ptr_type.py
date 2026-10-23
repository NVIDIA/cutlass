# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
Unit tests for the type of the ``tma_desc_ptr`` kw argument of TMA copies.

A ``tma_desc_ptr`` that is not a ``cute.Pointer``, such as the
``cutlass.Pointer`` returned by ``TensorMap.get_ptr()``, used to be dropped
without an error, so the copy silently kept using the descriptor baked into
the atom.
"""

import unittest

import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import make_fake_tensor
from cutlass.experimental.cuda import TensorMap, create_tensor_map_tiled_from_view
from cutlass.memory import SmemAllocator
from cutlass.tensor_utils import TensorMapManager, TensorMapUpdateMode

M, N = 64, 64


@cute.kernel
def _tma_kernel(
    atom: cute.CopyAtom,
    mX: cute.Tensor,
    desc: cutlass.GridConstant[TensorMap],
    workspace: cute.Tensor,
    is_load: cutlass.Constexpr,
    desc_ptr_kind: cutlass.Constexpr,
):
    smem = SmemAllocator()
    sX = smem.allocate_tensor(
        cutlass.Float32, cute.make_layout((M, N, 1), stride=(N, 1, M * N)), 128
    )
    gX = cute.local_tile(mX, (M, N), (None, None))
    tXsX, tXgX = cpasync.tma_partition(
        atom,
        0,
        cute.make_layout(1),
        cute.group_modes(sX, 0, 2),
        cute.group_modes(gX, 0, 2),
    )

    if cutlass.const_expr(desc_ptr_kind == "cutlass.Pointer"):
        desc_ptr = desc.get_ptr()
    elif cutlass.const_expr(desc_ptr_kind == "cute.Pointer"):
        desc_ptr = TensorMapManager(TensorMapUpdateMode.GMEM, 128).get_tensormap_ptr(
            workspace.iterator, cute.AddressSpace.generic
        )
    else:
        desc_ptr = None

    if cutlass.const_expr(is_load):
        bar = smem.allocate_array(cutlass.Int64, 1)
        cute.copy(
            atom,
            tXgX[(None, 0, 0)],
            tXsX[(None, 0)],
            tma_bar_ptr=bar,
            tma_desc_ptr=desc_ptr,
        )
    else:
        cute.copy(atom, tXsX[(None, 0)], tXgX[(None, 0, 0)], tma_desc_ptr=desc_ptr)


@cute.jit
def _launch(
    x: cute.Tensor,
    workspace: cute.Tensor,
    is_load: cutlass.Constexpr,
    desc_ptr_kind: cutlass.Constexpr,
):
    if cutlass.const_expr(is_load):
        op = cpasync.CopyBulkTensorTileG2SOp()
    else:
        op = cpasync.CopyBulkTensorTileS2GOp()
    atom, mX = cpasync.make_tiled_tma_atom(
        op, x, cute.make_layout((M, N), stride=(N, 1)), (M, N)
    )
    desc = create_tensor_map_tiled_from_view(x, box_dims=(M, N))
    _tma_kernel(atom, mX, desc, workspace, is_load, desc_ptr_kind).launch(
        grid=(1, 1, 1), block=(32, 1, 1)
    )


def _compile(is_load, desc_ptr_kind):
    x = make_fake_tensor(cutlass.Float32, (M, N), stride=(N, 1), assumed_align=16)
    workspace = make_fake_tensor(cutlass.Int64, (16,), stride=(1,), assumed_align=128)
    cute.compile(
        _launch, x, workspace, is_load, desc_ptr_kind, options="--gpu-arch sm_90a"
    )


class TestTmaDescPtrType(unittest.TestCase):
    def test_non_cute_pointer_raises(self):
        for is_load in (True, False):
            with self.subTest(is_load=is_load):
                with self.assertRaisesRegex(ValueError, "tma_desc_ptr"):
                    _compile(is_load, "cutlass.Pointer")

    def test_cute_pointer_or_none_compiles(self):
        for is_load in (True, False):
            for desc_ptr_kind in ("cute.Pointer", "none"):
                with self.subTest(is_load=is_load, desc_ptr_kind=desc_ptr_kind):
                    _compile(is_load, desc_ptr_kind)


if __name__ == "__main__":
    unittest.main()
