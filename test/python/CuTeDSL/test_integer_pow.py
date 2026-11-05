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
Unit tests for integer ``**`` (``a ** b`` with both operands integers).

Integer power used to be emitted as ``math.ipowi``, whose lowering inside a
GPU kernel crashed the compiler with SIGSEGV for scalar and vector operands
alike (NVIDIA/cutlass#3735). It is now expanded by
``cutlass._mlir_helpers.arith.expand_ipowi`` into square-and-multiply with the
semantics of ``math.ipowi``: wrapping overflow, and for a signed operand with
a negative exponent, ``1 ** n == 1``, ``(-1) ** n == +-1`` by parity and ``0``
otherwise. A constant non-negative exponent is unrolled.
"""

import unittest

import cutlass.cute as cute
from cutlass import Int32, Int64, Uint32

try:
    import torch
    from cutlass.cute.runtime import from_dlpack

    _HAS_CUDA = torch.cuda.is_available()
except ImportError:  # pragma: no cover - torch is optional for the compile-only tests
    torch = None
    _HAS_CUDA = False

_N = 256  # one element per thread


def _reference_ipowi(base: int, exponent: int, width: int, signed: bool) -> int:
    """``math.ipowi`` semantics (MLIR MathToFuncs) with wrapping overflow."""
    mask = (1 << width) - 1
    if signed and exponent < 0:
        if base == 1:
            result = 1
        elif base == -1:
            result = -1 if exponent & 1 else 1
        else:
            result = 0  # MLIR divides by zero for base 0; expand_ipowi yields 0
    else:
        result = pow(base & mask, exponent & mask, 1 << width)
    result &= mask
    if signed and result >= 1 << (width - 1):
        result -= 1 << width
    return result


_INT32_CASES = [
    (2, 3),
    (3, 4),
    (-2, 3),
    (-2, 4),
    (7, 0),
    (0, 0),
    (0, 5),
    (1, 1000000),
    (5, 13),
    (2, 30),
    (2, 31),
    (2, 32),
    (3, 21),
    (-3, 21),
    (2147483647, 2),
    (-2147483648, 3),
    (1, -3),
    (-1, -3),
    (-1, -4),
    (2, -1),
    (-5, -2),
    (0, -1),
]
_INT64_CASES = [
    (2, 3),
    (2, 40),
    (3, 39),
    (2, 62),
    (2, 63),
    (2, 64),
    (-2, 63),
    (6, 24),
    (4294967297, 2),
    (-4294967297, 3),
    (1, -7),
    (-1, -7),
    (-1, -8),
    (3, -2),
]
_UINT32_CASES = [
    (2, 3),
    (3, 20),
    (2, 31),
    (2, 32),
    (4294967295, 2),
    (4294967295, 3),
    (0, 0),
]
_CONST_EXPONENTS = (0, 1, 2, 3, 7, 31)


@cute.kernel
def _pow_i32_kernel(a: cute.Tensor, b: cute.Tensor, out: cute.Tensor):
    i, _, _ = cute.arch.thread_idx()
    out[i] = a[i] ** b[i]


@cute.kernel
def _pow_i64_kernel(a: cute.Tensor, b: cute.Tensor, out: cute.Tensor):
    i, _, _ = cute.arch.thread_idx()
    out[i] = a[i] ** b[i]


@cute.kernel
def _pow_u32_kernel(a: cute.Tensor, b: cute.Tensor, out: cute.Tensor):
    # Unsigned values travel through Int32 tensors (bit pattern preserved).
    i, _, _ = cute.arch.thread_idx()
    out[i] = Int32(Uint32(a[i]) ** Uint32(b[i]))


@cute.kernel
def _pow_const_kernel(a: cute.Tensor, out: cute.Tensor):
    i, _, _ = cute.arch.thread_idx()
    x = a[i]
    out[0 * _N + i] = x**0
    out[1 * _N + i] = x**1
    out[2 * _N + i] = x**2
    out[3 * _N + i] = x**3
    out[4 * _N + i] = x**7
    out[5 * _N + i] = x**31


@cute.kernel
def _pow_vector_i32_kernel(a: cute.Tensor, b: cute.Tensor, out: cute.Tensor):
    i, _, _ = cute.arch.thread_idx()
    ta = cute.local_tile(a, (4,), (i,))
    tb = cute.local_tile(b, (4,), (i,))
    to = cute.local_tile(out, (4,), (i,))
    to.store(ta.load() ** tb.load())


@cute.kernel
def _pow_vector_i64_const_kernel(a: cute.Tensor, out: cute.Tensor):
    i, _, _ = cute.arch.thread_idx()
    ta = cute.local_tile(a, (4,), (i,))
    to = cute.local_tile(out, (4,), (i,))
    to.store(ta.load() ** 3)


@cute.kernel
def _pow_math_ipowi_kernel(a: cute.Tensor, b: cute.Tensor, out: cute.Tensor):
    i, _, _ = cute.arch.thread_idx()
    out[i] = cute.math.ipowi(a[i], b[i])


def _launch(kernel, *tensors, block=_N):
    @cute.jit
    def launch(*args):
        kernel(*args).launch(grid=(1, 1, 1), block=(block, 1, 1))

    return launch


@cute.jit
def _host_pow_i32(a: Int32, b: Int32):
    cute.printf("{}", a**b)


@cute.jit
def _host_pow_i64_const(a: Int64):
    cute.printf("{}", a**5)


def _fill(cases, dtype):
    base = torch.tensor(
        [c[0] for c in cases] * (_N // len(cases) + 1), dtype=dtype, device="cuda"
    )[:_N]
    exp = torch.tensor(
        [c[1] for c in cases] * (_N // len(cases) + 1), dtype=dtype, device="cuda"
    )[:_N]
    return base, exp


class TestIntegerPow(unittest.TestCase):
    def test_host_int32_compiles(self):
        cute.compile(_host_pow_i32, Int32(2), Int32(3))

    def test_host_int64_constant_exponent_compiles(self):
        cute.compile(_host_pow_i64_const, Int64(2))

    def _check_scalar(self, kernel, cases, dtype, width, signed):
        base, exp = _fill(cases, dtype)
        out = torch.full_like(base, -123)
        tensors = [from_dlpack(t, assumed_align=16) for t in (base, exp, out)]
        compiled = cute.compile(_launch(kernel), *tensors)
        compiled(*tensors)
        torch.cuda.synchronize()
        got = out.cpu().tolist()
        for i, (b, e) in enumerate(cases):
            expected = _reference_ipowi(b, e, width, signed)
            if not signed and expected >= 1 << (width - 1):
                expected -= 1 << width  # stored through a signed tensor
            self.assertEqual(got[i], expected, f"{b} ** {e}")

    @unittest.skipUnless(_HAS_CUDA, "requires a CUDA device")
    def test_kernel_int32(self):
        self._check_scalar(_pow_i32_kernel, _INT32_CASES, torch.int32, 32, True)

    @unittest.skipUnless(_HAS_CUDA, "requires a CUDA device")
    def test_kernel_int64(self):
        self._check_scalar(_pow_i64_kernel, _INT64_CASES, torch.int64, 64, True)

    @unittest.skipUnless(_HAS_CUDA, "requires a CUDA device")
    def test_kernel_uint32(self):
        cases = [
            ((b + 2**31) % 2**32 - 2**31, (e + 2**31) % 2**32 - 2**31)
            for b, e in _UINT32_CASES
        ]
        base, exp = _fill(cases, torch.int32)
        out = torch.full_like(base, -123)
        tensors = [from_dlpack(t, assumed_align=16) for t in (base, exp, out)]
        compiled = cute.compile(_launch(_pow_u32_kernel), *tensors)
        compiled(*tensors)
        torch.cuda.synchronize()
        got = out.cpu().tolist()
        for i, (b, e) in enumerate(_UINT32_CASES):
            expected = _reference_ipowi(b, e, 32, False)
            self.assertEqual(got[i] % 2**32, expected, f"{b} ** {e} (unsigned)")

    @unittest.skipUnless(_HAS_CUDA, "requires a CUDA device")
    def test_kernel_math_ipowi(self):
        self._check_scalar(_pow_math_ipowi_kernel, _INT32_CASES, torch.int32, 32, True)

    @unittest.skipUnless(_HAS_CUDA, "requires a CUDA device")
    def test_kernel_constant_exponents(self):
        bases = [2, 3, -2, 0, 1, -1, 7, 2147483647]
        base = torch.tensor(
            bases * (_N // len(bases)), dtype=torch.int32, device="cuda"
        )
        out = torch.full(
            (len(_CONST_EXPONENTS) * _N,), -123, dtype=torch.int32, device="cuda"
        )
        tensors = [from_dlpack(t, assumed_align=16) for t in (base, out)]
        compiled = cute.compile(_launch(_pow_const_kernel), *tensors)
        compiled(*tensors)
        torch.cuda.synchronize()
        got = out.cpu().view(len(_CONST_EXPONENTS), _N).tolist()
        for k, e in enumerate(_CONST_EXPONENTS):
            for i, b in enumerate(bases):
                self.assertEqual(
                    got[k][i], _reference_ipowi(b, e, 32, True), f"{b} ** {e}"
                )

    @unittest.skipUnless(_HAS_CUDA, "requires a CUDA device")
    def test_kernel_vector_int32(self):
        base, exp = _fill(_INT32_CASES, torch.int32)
        out = torch.full_like(base, -123)
        tensors = [from_dlpack(t, assumed_align=16) for t in (base, exp, out)]
        compiled = cute.compile(
            _launch(_pow_vector_i32_kernel, block=_N // 4), *tensors
        )
        compiled(*tensors)
        torch.cuda.synchronize()
        got = out.cpu().tolist()
        for i, (b, e) in enumerate(_INT32_CASES):
            self.assertEqual(
                got[i], _reference_ipowi(b, e, 32, True), f"vector {b} ** {e}"
            )

    @unittest.skipUnless(_HAS_CUDA, "requires a CUDA device")
    def test_kernel_vector_int64_constant_exponent(self):
        bases = [2, -3, 1 << 21, -(1 << 21)]
        base = torch.tensor(
            bases * (_N // len(bases)), dtype=torch.int64, device="cuda"
        )
        out = torch.full_like(base, -123)
        tensors = [from_dlpack(t, assumed_align=16) for t in (base, out)]
        compiled = cute.compile(
            _launch(_pow_vector_i64_const_kernel, block=_N // 4), *tensors
        )
        compiled(*tensors)
        torch.cuda.synchronize()
        got = out.cpu().tolist()
        for i, b in enumerate(bases):
            self.assertEqual(
                got[i], _reference_ipowi(b, 3, 64, True), f"vector {b} ** 3"
            )


if __name__ == "__main__":
    unittest.main()
