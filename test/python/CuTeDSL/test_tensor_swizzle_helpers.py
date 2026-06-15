# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from dataclasses import dataclass

import pytest

import cutlass
import cutlass.cute as cute
import cutlass.cute.tensor as cute_tensor
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.cute.typing import Tensor


@dataclass
class _DummyTensor(Tensor):
    _memspace: cute.AddressSpace
    _iterator: object
    _layout: object
    _element_type: object = cutlass.Float32

    def __str__(self) -> str:
        return "_DummyTensor"

    def __getitem__(self, idx):
        raise NotImplementedError

    def __setitem__(self, idx, value) -> None:
        raise NotImplementedError

    @property
    def element_type(self):
        return self._element_type

    @property
    def memspace(self):
        return self._memspace

    @property
    def iterator(self):
        return self._iterator

    @property
    def leading_dim(self):
        return None

    @property
    def layout(self):
        return self._layout

    @property
    def shape(self):
        return (1,)

    @property
    def stride(self):
        return (1,)

    def fill(self, value) -> None:
        raise NotImplementedError


def test_as_position_independent_swizzle_tensor_rejects_non_tensor():
    with pytest.raises(TypeError, match="expects a Tensor"):
        cute.as_position_independent_swizzle_tensor(object())


def test_as_position_independent_swizzle_tensor_rejects_non_smem_tensor():
    tensor = make_fake_compact_tensor(
        cutlass.Float32,
        (4,),
        memspace=cute.AddressSpace.gmem,
        assumed_align=16,
    )

    with pytest.raises(TypeError, match="shared-memory tensor"):
        cute.as_position_independent_swizzle_tensor(tensor)


def test_as_position_independent_swizzle_tensor_moves_swizzle_to_pointer(
    monkeypatch,
):
    source = _DummyTensor(
        cute.AddressSpace.smem,
        _iterator=object(),
        _layout=object(),
    )
    swizzle = object()
    nonswizzle_layout = object()
    recast_pointer = object()
    result_tensor = object()

    def fake_get_swizzle_portion(layout, *, loc=None, ip=None):
        assert layout is source.layout
        return swizzle

    def fake_get_nonswizzle_portion(layout, *, loc=None, ip=None):
        assert layout is source.layout
        return nonswizzle_layout

    def fake_recast_ptr(ptr, swizzle_=None, dtype=None, loc=None, ip=None):
        assert ptr is source.iterator
        assert swizzle_ is swizzle
        assert dtype is cutlass.Float32
        return recast_pointer

    def fake_make_tensor(ptr, layout, *, loc=None, ip=None):
        assert ptr is recast_pointer
        assert layout is nonswizzle_layout
        return result_tensor

    monkeypatch.setattr(cute_tensor, "get_swizzle_portion", fake_get_swizzle_portion)
    monkeypatch.setattr(
        cute_tensor, "get_nonswizzle_portion", fake_get_nonswizzle_portion
    )
    monkeypatch.setattr(cute_tensor, "recast_ptr", fake_recast_ptr)
    monkeypatch.setattr(cute_tensor, "make_tensor", fake_make_tensor)

    assert cute.as_position_independent_swizzle_tensor(source) is result_tensor


@cute.kernel
def _copy_position_independent_plain_smem_tensor_kernel(out: cute.Tensor):
    smem_ptr = cute.arch.alloc_smem(cutlass.Float32, 64, alignment=16)
    layout = cute.make_layout((8, 8), stride=(8, 1))
    smem_tensor = cute.make_tensor(smem_ptr, layout)
    smem_view = cute.as_position_independent_swizzle_tensor(smem_tensor)
    rmem_tensor = cute.make_rmem_tensor(layout, cutlass.Float32)

    rmem_tensor.fill(1.0)
    cute.basic_copy(rmem_tensor, smem_view)
    rmem_tensor.fill(0.0)
    cute.basic_copy(smem_view, rmem_tensor)

    tidx, _, _ = cute.arch.thread_idx()
    if tidx == 0:
        out[0] = rmem_tensor[0, 0]


@cute.jit
def _launch_copy_position_independent_plain_smem_tensor(out: cute.Tensor):
    _copy_position_independent_plain_smem_tensor_kernel(out).launch(
        grid=[1, 1, 1], block=[32, 1, 1]
    )


@cute.kernel
def _copy_position_independent_swizzle_tensor_kernel(out: cute.Tensor):
    smem_ptr = cute.arch.alloc_smem(cutlass.Float32, 64, alignment=16)
    base_layout = cute.make_layout((8, 8), stride=(8, 1))
    swizzled_layout = cute.make_composed_layout(
        cute.make_swizzle(1, 4, 3), 0, base_layout
    )
    smem_tensor = cute.make_tensor(smem_ptr, swizzled_layout)
    smem_view = cute.as_position_independent_swizzle_tensor(smem_tensor)
    rmem_tensor = cute.make_rmem_tensor(base_layout, cutlass.Float32)

    rmem_tensor.fill(1.0)
    cute.basic_copy(rmem_tensor, smem_view)
    rmem_tensor.fill(0.0)
    cute.basic_copy(smem_view, rmem_tensor)

    tidx, _, _ = cute.arch.thread_idx()
    if tidx == 0:
        out[0] = rmem_tensor[0, 0]


@cute.jit
def _launch_copy_position_independent_swizzle_tensor(out: cute.Tensor):
    _copy_position_independent_swizzle_tensor_kernel(out).launch(
        grid=[1, 1, 1], block=[32, 1, 1]
    )


def test_as_position_independent_swizzle_tensor_copy_path_compiles():
    out = make_fake_compact_tensor(
        cutlass.Float32,
        (1,),
        memspace=cute.AddressSpace.gmem,
        assumed_align=16,
    )

    cute.compile(_launch_copy_position_independent_swizzle_tensor, out)


def test_as_position_independent_swizzle_tensor_plain_smem_copy_path_compiles():
    out = make_fake_compact_tensor(
        cutlass.Float32,
        (1,),
        memspace=cute.AddressSpace.gmem,
        assumed_align=16,
    )

    cute.compile(_launch_copy_position_independent_plain_smem_tensor, out)
