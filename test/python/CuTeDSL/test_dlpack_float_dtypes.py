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
Unit tests for the DLPack element-type mapping of narrow float formats.

The DLPack importer decodes the raw dtype into a canonical name and then
resolves that name against the DSL numeric types. The decoder recognizes every
MLIR float format, but the Python side only carries a type for each format it
declares, so a format with no matching class used to fail resolution with a
bare ``AttributeError`` on the typing module -- an error that named the missing
attribute rather than the tensor being imported.

These tests pin the round trip in both directions:

* torch dtype -> ``from_dlpack`` -> DSL element type, which is what a caller
  importing a real tensor exercises.
* DSL element type -> MLIR type -> DSL element type, which is the lookup table
  the importer itself uses, checked without needing torch.
* DSL element type -> a compiled kernel that reads the imported tensor, which
  is the only way to prove the declared element width is usable end to end.

The first two need no GPU. The kernel test does, and skips without one.
"""

import unittest

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack

try:
    import torch
except ImportError:  # torch is optional for the DSL itself
    torch = None

# Every float8 format the DLPack decoder can emit, paired with the DSL type
# that must resolve it. FNUZ ("finite, no unsigned zero") and E3M4 have MLIR
# types but had no DSL class, so importing one of them raised AttributeError.
EXPECTED_DLPACK_FLOAT_DTYPES = [
    ("float8_e5m2", cutlass.Float8E5M2),
    ("float8_e5m2fnuz", cutlass.Float8E5M2FNUZ),
    ("float8_e4m3fn", cutlass.Float8E4M3FN),
    ("float8_e4m3fnuz", cutlass.Float8E4M3FNUZ),
    ("float8_e8m0fnu", cutlass.Float8E8M0FNU),
]

# Formats with a DSL type but no torch equivalent. They cannot be reached
# through torch, so they are covered by the MLIR round trip below.
DSL_ONLY_FLOAT_DTYPES = [
    cutlass.Float8E4M3,
    cutlass.Float8E4M3B11FNUZ,
    cutlass.Float8E3M4,
    cutlass.Float6E2M3FN,
    cutlass.Float6E3M2FN,
    cutlass.Float4E2M1FN,
]

# Formats a GPU kernel can both read and widen. The FNUZ formats are excluded:
# the NVGPU backend has no legalization for `nvgpu.cvt_fpext` out of them on
# consumer architectures, so a kernel that widens one fails to compile. That is
# a backend limitation independent of DLPack import, which these tests cover.
KERNEL_CONVERTIBLE_DTYPES = [
    ("float8_e5m2", cutlass.Float8E5M2),
    ("float8_e4m3fn", cutlass.Float8E4M3FN),
]


class TestDlpackFloatDtypes(unittest.TestCase):
    """torch dtype -> from_dlpack -> DSL element type."""

    @unittest.skipIf(torch is None, "torch is not installed")
    def test_float8_dtypes_import(self):
        for torch_name, expected in EXPECTED_DLPACK_FLOAT_DTYPES:
            with self.subTest(dtype=torch_name):
                torch_dtype = getattr(torch, torch_name, None)
                if torch_dtype is None:
                    self.skipTest(f"torch.{torch_name} is unavailable")

                tensor = from_dlpack(
                    torch.zeros(8, dtype=torch_dtype), assumed_align=16
                )
                self.assertIs(tensor.element_type, expected)

    @unittest.skipIf(torch is None, "torch is not installed")
    def test_unsupported_float8_dtypes_no_attribute_error(self):
        """The reported failure mode was an AttributeError naming the typing
        module, which told the caller nothing about which tensor failed.

        Pin the error type instead: an unrecognized torch dtype must surface a
        DSL-level diagnostic, never a missing-attribute lookup on the typing
        module. This guards the mapping even for formats torch gains later.
        """
        # torch has no float8_e3m4; if it ever gains one, it must map cleanly.
        torch_dtype = getattr(torch, "float8_e3m4", None)
        if torch_dtype is None:
            self.skipTest("torch.float8_e3m4 is unavailable")

        tensor = from_dlpack(torch.zeros(8, dtype=torch_dtype), assumed_align=16)
        self.assertIs(tensor.element_type, cutlass.Float8E3M4)

    @unittest.skipIf(torch is None, "torch is not installed")
    def test_non_float_dtypes_unaffected(self):
        """Widening the float mapping must not disturb the formats that
        already resolved correctly."""
        for torch_dtype, expected in [
            (torch.float32, cutlass.Float32),
            (torch.float16, cutlass.Float16),
            (torch.bfloat16, cutlass.BFloat16),
            (torch.int8, cutlass.Int8),
            (torch.uint8, cutlass.Uint8),
            (torch.bool, cutlass.Boolean),
        ]:
            with self.subTest(dtype=str(torch_dtype)):
                tensor = from_dlpack(torch.zeros(8, dtype=torch_dtype))
                self.assertIs(tensor.element_type, expected)


class TestFloatDtypeMlirRoundTrip(unittest.TestCase):
    """DSL element type -> MLIR type -> DSL element type.

    This is the lookup table the importer uses internally, exercised directly
    so the formats torch cannot express are still covered.
    """

    def test_float_dtypes_round_trip(self):
        from cutlass._mlir import ir
        from cutlass.base_dsl.typing import Numeric

        dtypes = [expected for _, expected in EXPECTED_DLPACK_FLOAT_DTYPES]
        dtypes += DSL_ONLY_FLOAT_DTYPES

        with ir.Context():
            for dtype in dtypes:
                with self.subTest(dtype=dtype.__name__):
                    self.assertIs(Numeric.from_mlir_type(dtype.mlir_type), dtype)

    def test_float_dtypes_exported(self):
        """Each new format must be reachable under its documented name."""
        from cutlass.base_dsl.typing import dtype as dtype_from_name

        for dtype in DSL_ONLY_FLOAT_DTYPES + [
            expected for _, expected in EXPECTED_DLPACK_FLOAT_DTYPES
        ]:
            with self.subTest(dtype=dtype.__name__):
                self.assertIs(getattr(cutlass, dtype.__name__), dtype)
                self.assertIs(dtype_from_name(dtype.__name__), dtype)


@cute.kernel
def _widen_kernel(src: cute.Tensor, dst: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    dst[tidx] = src[tidx].to(cutlass.Float32)


@cute.jit
def _widen_jit(src: cute.Tensor, dst: cute.Tensor, n: cutlass.Constexpr[int]):
    _widen_kernel(src, dst).launch(grid=[1, 1, 1], block=[n, 1, 1])


class TestFloatDtypesInKernel(unittest.TestCase):
    """End-to-end: a DLPack-imported fp8 tensor must work as real kernel input.

    Resolving the element type is only half the contract; the tensor also has
    to be usable as a kernel operand with the width the DSL type declares.
    """

    @unittest.skipIf(torch is None, "torch is not installed")
    @unittest.skipUnless(
        torch.cuda.is_available(), "a CUDA device is required to compile a kernel"
    )
    def test_fp8_tensor_widens_in_kernel(self):
        # Small enough to fit one block, so the index math stays trivial.
        n = 64
        base = torch.arange(n, device="cuda", dtype=torch.float32)

        for torch_name, expected in KERNEL_CONVERTIBLE_DTYPES:
            with self.subTest(dtype=torch_name):
                src = base.to(getattr(torch, torch_name))
                # Compare against the value after the host-side narrowing, not
                # against `base`: fp8 keeps 3 mantissa bits, so most integers
                # above 16 do not survive the round trip. Asserting on `base`
                # would blame the kernel for the host's rounding.
                reference = src.to(torch.float32)
                dst = torch.zeros(n, device="cuda", dtype=torch.float32)

                imported = from_dlpack(src, assumed_align=16)
                self.assertIs(imported.element_type, expected)

                _widen_jit(imported, from_dlpack(dst, assumed_align=16), n)
                torch.cuda.synchronize()

                self.assertTrue(torch.equal(dst, reference))


if __name__ == "__main__":
    unittest.main()
