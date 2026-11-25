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
Unit tests for the ``cute.arch`` helpers built on pure inline PTX.

Each helper is checked against a host reference, and its PTX is checked to
hold no more of its instruction when the kernel calls it twice on the same
input. A predicated packed-half add stays volatile and keeps both calls. The
tests need a CUDA GPU and skip without one.
"""

import unittest
import warnings
from unittest import mock

import numpy as np
import torch

import cutlass
import cutlass.cute as cute
from cutlass import Boolean, Float32, Int16, Int32
from cutlass._mlir import ir
from cutlass._mlir.dialects import arith, llvm, vector
from cutlass.cute.runtime import from_dlpack
from cutlass.cutlass_dsl import CuTeDSL
from cutlass.experimental.primitives import nvvm_wrapper as experimental


def _bytes(x, n):
    return llvm.bitcast(ir.VectorType.get([n], cutlass.Int8.mlir_type), x)


def _lane(vec, i):
    return Float32(vector.extract(vec, dynamic_position=[], static_position=[i]))


def _repacked(vec, n):
    word = Int32(0)
    for i in range(n):
        word = word | ((Int32(_lane(vec, i)) & Int32(0xFF)) << Int32(8 * i))
    return word


def _prmt(x):
    return Int32(cute.arch.prmt(x, Int32(0), Int32(0x0123)))


def _i8x4_to_f32x4(x):
    return _repacked(cute.arch.cvt_i8x4_to_f32x4(_bytes(Int32(x).ir_value(), 4)), 4)


def _i8x2_to_f32x2(x):
    low = arith.trunci(Int16.mlir_type, Int32(x).ir_value())
    return _repacked(cute.arch.cvt_i8x2_to_f32x2(_bytes(low, 2)), 2)


def _f32x2_to_bf16x2(x):
    lo = Float32(x & Int32(0xFFFF))
    hi = Float32((x >> Int32(16)) & Int32(0xFFFF))
    pair = vector.from_elements(
        ir.VectorType.get([2], Float32.mlir_type), [lo.ir_value(), hi.ir_value()]
    )
    return Int32(llvm.bitcast(Int32.mlir_type, cute.arch.cvt_f32x2_bf16x2(pair)))


def _exp2(x):
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", DeprecationWarning)
        return Int32(cute.arch.exp2(Float32(x & Int32(15))))


def _add_bf16x2(x):
    return cute.arch.add_packed_bf16x2(x, x)


def _add_bf16x2_predicated(x):
    return cute.arch.add_packed_bf16x2(x, x, predicate=Boolean(x != Int32(0)))


def _sub_f16x2(x):
    return cute.arch.sub_packed_f16x2(x, Int32(0x3C003C00))


def _exp2_f16x2(x):
    return cute.arch.exp2_packed_f16x2(x)


def _mul_bf16x2(x):
    return experimental.mul_bf16x2(x, x)


@cute.kernel
def _apply(
    src: cute.Tensor,
    dst: cute.Tensor,
    op: cutlass.Constexpr,
    twice: cutlass.Constexpr[bool],
):
    tidx, _, _ = cute.arch.thread_idx()
    x = src[tidx]
    out = op(x)
    if cutlass.const_expr(twice):
        out = out + op(x)
    dst[tidx] = out


@cute.jit
def _launch(
    src: cute.Tensor,
    dst: cute.Tensor,
    op: cutlass.Constexpr,
    twice: cutlass.Constexpr[bool],
):
    _apply(src, dst, op, twice).launch(grid=[1, 1, 1], block=[32, 1, 1])


def _packed(halves, dtype):
    bits = torch.tensor(halves, dtype=dtype).view(torch.int16).numpy()
    return bits.astype(np.uint16).view(np.uint32).view(np.int32)


def _unpacked(words, dtype):
    return torch.from_numpy(words.view(np.int16).copy()).view(dtype).float()


_RNG = np.random.default_rng(0)
_WORDS = _RNG.integers(-(2**31), 2**31, size=32, dtype=np.int64).astype(np.int32)
_BF16 = _packed(_RNG.uniform(1.0, 2.0, size=64), torch.bfloat16)
_F16 = _packed(_RNG.uniform(1.0, 2.0, size=64), torch.float16)
_SMALL_F16 = _packed(_RNG.integers(0, 8, size=64).astype(np.float32), torch.float16)


def _ref_f32x2_to_bf16x2(words):
    w = words.astype(np.int64)
    pair = np.stack([w & 0xFFFF, (w >> 16) & 0xFFFF], axis=1).astype(np.float32)
    bits = torch.from_numpy(pair).to(torch.bfloat16).view(torch.int16).numpy()
    return bits.astype(np.uint16).copy().view(np.uint32).view(np.int32).ravel()


# name: (op, input, PTX marker, reference on the input, compare as)
_CASES = {
    "prmt": (_prmt, _WORDS, "prmt.b32", lambda w: w.byteswap(), "bits"),
    "cvt_i8x4_to_f32x4": (
        _i8x4_to_f32x4,
        _WORDS,
        "dp4a",
        lambda w: w,
        "bits",
    ),
    "cvt_i8x2_to_f32x2": (
        _i8x2_to_f32x2,
        _WORDS,
        "dp4a",
        lambda w: w & 0xFFFF,
        "bits",
    ),
    "cvt_f32x2_bf16x2": (
        _f32x2_to_bf16x2,
        _WORDS,
        "cvt.rn.satfinite.bf16x2.f32",
        _ref_f32x2_to_bf16x2,
        "bits",
    ),
    "exp2": (
        _exp2,
        _WORDS,
        "ex2.approx.ftz.f32",
        lambda w: 2 ** (w.astype(np.int64) & 15),
        "bits",
    ),
    "add_packed_bf16x2": (
        _add_bf16x2,
        _BF16,
        "add.bf16x2 ",
        lambda w: _unpacked(w, torch.bfloat16) * 2,
        torch.bfloat16,
    ),
    "sub_packed_f16x2": (
        _sub_f16x2,
        _F16,
        "sub.f16x2",
        lambda w: _unpacked(w, torch.float16) - 1,
        torch.float16,
    ),
    "exp2_packed_f16x2": (
        _exp2_f16x2,
        _SMALL_F16,
        "ex2.approx.f16x2",
        lambda w: 2 ** _unpacked(w, torch.float16),
        torch.float16,
    ),
    "experimental.mul_bf16x2": (
        _mul_bf16x2,
        _BF16,
        "mul.bf16x2",
        lambda w: _unpacked(w, torch.bfloat16) ** 2,
        torch.bfloat16,
    ),
}


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class TestPureArchHelpers(unittest.TestCase):
    def setUp(self):
        patcher = mock.patch.object(CuTeDSL._get_dsl().envar, "keep_ptx", True)
        patcher.start()
        self.addCleanup(patcher.stop)

    def run_op(self, op, words, twice):
        src = torch.from_numpy(words.copy()).cuda()
        dst = torch.zeros_like(src)
        args = [from_dlpack(src), from_dlpack(dst), op, twice]
        compiled = cute.compile(_launch, *args)
        compiled(from_dlpack(src), from_dlpack(dst))
        return compiled.artifacts.PTX, dst.cpu().numpy()

    def test_matches_reference(self):
        for name, (op, words, _, reference, compare) in _CASES.items():
            with self.subTest(name):
                _, out = self.run_op(op, words, twice=False)
                if compare == "bits":
                    np.testing.assert_array_equal(out, reference(words))
                else:
                    torch.testing.assert_close(
                        _unpacked(out, compare),
                        reference(words).to(compare).float(),
                    )

    def test_second_call_is_merged(self):
        for name, (op, words, marker, _, _) in _CASES.items():
            with self.subTest(name):
                once, _ = self.run_op(op, words, twice=False)
                twice, _ = self.run_op(op, words, twice=True)
                self.assertGreater(once.count(marker), 0)
                self.assertEqual(twice.count(marker), once.count(marker))

    def test_predicated_call_is_kept(self):
        once, _ = self.run_op(_add_bf16x2_predicated, _BF16, twice=False)
        twice, _ = self.run_op(_add_bf16x2_predicated, _BF16, twice=True)
        self.assertEqual(twice.count("add.bf16x2 "), 2 * once.count("add.bf16x2 "))


if __name__ == "__main__":
    unittest.main()
