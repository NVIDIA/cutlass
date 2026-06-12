# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Regression for https://github.com/NVIDIA/cutlass/issues/3243 — FastDivmodDivisor
# must carry the scalar divisor SSA alongside the encoded divisor so that
# ``params.fdd.divisor`` is legal inside an isolated kernel region.

from dataclasses import dataclass

import cutlass
import cutlass.cute as cute
from cutlass import Int32
from cutlass.cute.runtime import make_fake_tensor


@dataclass
class Params:
    fdd: cute.FastDivmodDivisor


@cute.jit
def make_params(divisor: Int32) -> Params:
    return Params(cute.FastDivmodDivisor(divisor))


@cute.kernel
def write_divisor(out: cute.Tensor, params: Params):
    tidx, _, _ = cute.arch.thread_idx()
    if tidx == 0:
        out[0] = params.fdd.divisor


@cute.jit
def entry(out: cute.Tensor, divisor: Int32):
    params = make_params(divisor)
    write_divisor(out, params).launch(grid=(1, 1, 1), block=(32, 1, 1))


def test_fast_divmod_divisor_inside_params_compiles():
    out_fake = make_fake_tensor(cutlass.Int32, (1,), stride=(1,), assumed_align=4)
    cute.compile(entry, out_fake, Int32(0))
