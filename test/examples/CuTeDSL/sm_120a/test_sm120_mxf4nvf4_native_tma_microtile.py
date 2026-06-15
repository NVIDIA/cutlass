# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path

import pytest

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


pytestmark = [pytest.mark.arch(["120a"])]

_MXF4NVF4_MMA_PTX = (
    "mma.sync.aligned.m16n8k64.row.col.kind::mxf4nvf4.block_scale."
    "scale_vec::4X.f32.e2m1.e2m1.f32.ue4m3"
)

_EXAMPLES_DIR = Path(__file__).parents[4] / "examples/python/CuTeDSL"


def _make_cute_fp4_tensor(torch, logical_major: int, logical_k: int):
    storage = torch.empty(
        (1, logical_major, logical_k // 2),
        device="cuda",
        dtype=torch.float4_e2m1fn_x2,
    )
    storage.view(torch.uint8).fill_(0x22)
    tensor = storage.permute(1, 2, 0)
    # Torch exposes packed FP4 storage as x2 bytes. Disable TVM FFI conversion
    # and restore the logical CuTe element type so TMA sees Float4E2M1FN.
    cute_tensor = from_dlpack(tensor, assumed_align=16, enable_tvm_ffi=False)
    cute_tensor.element_type = cutlass.Float4E2M1FN
    assert cute_tensor.element_type is cutlass.Float4E2M1FN
    assert cute_tensor.shape == (logical_major, logical_k, 1)
    return cute_tensor


def _make_cute_tensor(tensor):
    return from_dlpack(tensor, assumed_align=16, enable_tvm_ffi=True)


def test_sm120_mxf4nvf4_native_tma_microtile_example(monkeypatch):
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    if torch.cuda.get_device_capability()[0] < 12:
        pytest.skip("SM120 CUDA device required")
    if not hasattr(torch, "float4_e2m1fn_x2"):
        pytest.skip("torch Float4E2M1FN storage dtype unavailable")
    if not hasattr(torch, "float8_e4m3fn"):
        pytest.skip("torch Float8E4M3FN dtype unavailable")
    monkeypatch.syspath_prepend(str(_EXAMPLES_DIR))
    from cute.blackwell.kernel.blockscaled_gemm.sm120_mxf4nvf4_native_tma_microtile import (
        sm120_mxf4nvf4_native_tma_microtile,
    )

    a = _make_cute_fp4_tensor(torch, 128, 128)
    b = _make_cute_fp4_tensor(torch, 128, 128)
    sfa_storage = torch.ones((1024,), device="cuda", dtype=torch.float8_e4m3fn)
    sfa_storage[512:].fill_(2.0)
    sfb_storage = torch.ones((1024,), device="cuda", dtype=torch.float8_e4m3fn)
    d_storage = torch.empty((16, 8), device="cuda", dtype=torch.bfloat16)
    sfa = _make_cute_tensor(sfa_storage)
    sfb = _make_cute_tensor(sfb_storage)
    d = _make_cute_tensor(d_storage)

    compiled = cute.compile(
        sm120_mxf4nvf4_native_tma_microtile,
        a,
        b,
        sfa,
        sfb,
        d,
        options="--keep-ptx",
    )
    # Exact instruction counts are intentional for this fixed 16x8 K128
    # microtile: two K64 MMAs, two A/B TMA loads, and two scale TMA loads.
    assert compiled.__ptx__.count(_MXF4NVF4_MMA_PTX) == 2
    assert compiled.__ptx__.count("cp.async.bulk.tensor.3d") == 2
    assert compiled.__ptx__.count("cp.async.bulk.tensor.2d") == 2

    d_storage.zero_()
    compiled(a, b, sfa, sfb, d)
    torch.cuda.synchronize()

    torch.testing.assert_close(
        d_storage.float(), torch.full_like(d_storage.float(), 192.0), rtol=0, atol=0
    )
