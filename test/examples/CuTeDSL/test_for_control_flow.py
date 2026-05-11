# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def _for_loop_carried_reused_target_kernel(out: cute.Tensor, n: cutlass.Int32):
    acc = cutlass.Int32(0)
    i = cutlass.Int32(-1)

    for i in cutlass.range(0, n):
        acc = cutlass.Int32(1)

    out[0] = acc
    out[1] = i


@cute.jit
def _for_loop_carried_reused_target_host(out: cute.Tensor, n: cutlass.Int32):
    _for_loop_carried_reused_target_kernel(out, n).launch(
        grid=[1, 1, 1],
        block=[1, 1, 1],
    )


def test_for_loop_carried_var_with_reused_loop_target():
    n = 5
    out = torch.zeros(2, device="cuda", dtype=torch.int32)
    out_cute = from_dlpack(out).mark_layout_dynamic()
    n_cute = cutlass.Int32(n)

    compiled = cute.compile(_for_loop_carried_reused_target_host, out_cute, n_cute)
    compiled(out_cute, n_cute)
    torch.cuda.synchronize()

    actual = out.cpu().tolist()
    expected = [1, n - 1]
    print(f"for loop carried reused target actual={actual}, expected={expected}")
    assert actual == expected
