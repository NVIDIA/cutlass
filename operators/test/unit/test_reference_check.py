# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""
Unit tests for assert_close_with_reference_conversion function. Does not require GPU.
"""

import sys

import numpy as np
import pytest
import torch

import cutlass

from test_utils.reference_check import ClampMode, assert_close_with_reference_conversion

# Several tests here use jax.numpy and jax is unavailable on Python < 3.11
if sys.version_info < (3, 11):
    pytest.skip(
        "JAX is unavailable on Python < 3.11",
        allow_module_level=True,
    )

import jax.numpy as jnp  # noqa: E402

from cutlass.operators.arguments import GemmArguments

from test_utils.reference_check import (
    GemmReferenceTolerances,
    gemm_reference_tolerances,
)


class TestTorchAssertCloseWithReferenceConversion:
    def test_basic_float32_match(self):
        """Test basic comparison with matching float32 tensors."""
        reference = torch.tensor([1.0, 2.0, 3.0], dtype=torch.float32)
        result = torch.tensor([1.0, 2.0, 3.0], dtype=torch.float32)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Float32
        )

    def test_float32_with_tolerance(self):
        """Test comparison with rtols and atols parameters."""
        reference = torch.tensor([1.0, 2.0, 3.0], dtype=torch.float32)
        result = torch.tensor([1.001, 2.002, 3.003], dtype=torch.float32)
        # Test that values within tolerance pass
        assert_close_with_reference_conversion(
            result,
            reference,
            output_dtypes=cutlass.Float32,
            rtols=[1e-2],
            atols=[1e-2],
        )
        # Test that values outside tolerance raise AssertionError
        # This test passes if AssertionError is raised (expected behavior)
        result_outside_tolerance = torch.tensor([1.1, 2.1, 3.1], dtype=torch.float32)
        with pytest.raises(AssertionError):
            assert_close_with_reference_conversion(
                result_outside_tolerance,
                reference,
                output_dtypes=cutlass.Float32,
                rtols=[1e-2],
                atols=[1e-2],
            )

    def test_cutlass_float16_dtype_conversion(self):
        """Test dtype conversion from float32 reference to cutlass.Float16 result."""
        reference = torch.tensor([1.0, 2.0, 3.0], dtype=torch.float32)
        result = torch.tensor([1.0, 2.0, 3.0], dtype=torch.float16)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Float16
        )

    def test_torch_float16_dtype_conversion(self):
        """Test dtype conversion from float32 reference to torch.float16 result."""
        reference = torch.tensor([1.0, 2.0, 3.0], dtype=torch.float32)
        result = torch.tensor([1.0, 2.0, 3.0], dtype=torch.float16)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=torch.float16
        )

    def test_int_dtype(self):
        """Test comparison with integer dtype."""
        reference = torch.tensor([1, 2, 3], dtype=torch.int32)
        result = torch.tensor([1, 2, 3], dtype=torch.int32)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Int32
        )

    def test_multiple_tensors(self):
        """Test comparison with multiple tensors."""
        ref1 = torch.tensor([1.0, 2.0], dtype=torch.float32)
        ref2 = torch.tensor([3.0, 4.0], dtype=torch.float32)
        res1 = torch.tensor([1.0, 2.0], dtype=torch.float32)
        res2 = torch.tensor([3.0, 4.0], dtype=torch.float32)
        assert_close_with_reference_conversion(
            [res1, res2],
            [ref1, ref2],
            output_dtypes=[cutlass.Float32, cutlass.Float32],
        )

    def test_multiple_tensors_different_dtypes(self):
        """Test multiple tensors with different dtypes."""
        ref1 = torch.tensor([1.0, 2.0], dtype=torch.float32)
        ref2 = torch.tensor([3, 4], dtype=torch.int32)
        res1 = torch.tensor([1.0, 2.0], dtype=torch.float16)
        res2 = torch.tensor([3, 4], dtype=torch.int32)
        assert_close_with_reference_conversion(
            [res1, res2],
            [ref1, ref2],
            output_dtypes=[cutlass.Float16, cutlass.Int32],
        )

    def test_overflow_saturation_float16(self):
        """Test that overflow values are clamped to dtype range."""
        # Create reference with values outside float16 range
        reference = torch.tensor([1e10, -1e10, 1.0], dtype=torch.float32)
        # Result should be saturated to float16 max/min
        result = torch.tensor([65504.0, -65504.0, 1.0], dtype=torch.float16)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Float16, clamp=True
        )

    def test_custom_message(self):
        """Test that custom error message is passed through."""
        reference = torch.tensor([1.0, 2.0, 3.0], dtype=torch.float32)
        result = torch.tensor([1.0, 2.0, 3.0], dtype=torch.float32)
        # Should not raise, but message should be set
        assert_close_with_reference_conversion(
            result,
            reference,
            output_dtypes=cutlass.Float32,
            msg="Custom test message",
        )

    def test_rtols_atols_expansion(self):
        """Test that single rtols/atols values are expanded to match tensor count."""
        ref1 = torch.tensor([1.0], dtype=torch.float32)
        ref2 = torch.tensor([2.0], dtype=torch.float32)
        res1 = torch.tensor([1.001], dtype=torch.float32)
        res2 = torch.tensor([2.001], dtype=torch.float32)
        # Single rtols/atols should be expanded to both tensors
        assert_close_with_reference_conversion(
            [res1, res2],
            [ref1, ref2],
            output_dtypes=[cutlass.Float32, cutlass.Float32],
            rtols=[1e-2],  # Single value
            atols=[1e-2],  # Single value
        )

    def test_mismatched_dtype_raises(self):
        """Test that mismatched result dtype raises ValueError."""
        reference = torch.tensor([1.0, 2.0], dtype=torch.float32)
        result = torch.tensor([1.0, 2.0], dtype=torch.float32)  # Wrong dtype in result
        with pytest.raises(ValueError, match="does not match target dtype"):
            assert_close_with_reference_conversion(
                result,
                reference,
                output_dtypes=cutlass.Float16,  # not float32
            )

    def test_wrong_number_of_tensors_raises(self):
        """Test that mismatched number of tensors raises ValueError."""
        reference = torch.tensor([1.0], dtype=torch.float32)
        result1 = torch.tensor([1.0], dtype=torch.float32)
        result2 = torch.tensor([2.0], dtype=torch.float32)
        with pytest.raises(
            ValueError,
            match="number of result tensors, references, and output dtypes must be the same",
        ):
            assert_close_with_reference_conversion(
                [result1, result2], reference, output_dtypes=cutlass.Float32
            )

    def test_wrong_number_of_rtols_raises(self):
        """Test that wrong number of rtols values raises ValueError."""
        ref1 = torch.tensor([1.0], dtype=torch.float32)
        ref2 = torch.tensor([2.0], dtype=torch.float32)
        res1 = torch.tensor([1.0], dtype=torch.float32)
        res2 = torch.tensor([2.0], dtype=torch.float32)
        with pytest.raises(ValueError, match="number of rtol values must be the same"):
            assert_close_with_reference_conversion(
                [res1, res2],
                [ref1, ref2],
                output_dtypes=[cutlass.Float32, cutlass.Float32],
                rtols=[1e-2, 1e-2, 1e-2],  # Wrong count
            )

    def test_wrong_number_of_atols_raises(self):
        """Test that wrong number of atols values raises ValueError."""
        ref1 = torch.tensor([1.0], dtype=torch.float32)
        ref2 = torch.tensor([2.0], dtype=torch.float32)
        res1 = torch.tensor([1.0], dtype=torch.float32)
        res2 = torch.tensor([2.0], dtype=torch.float32)
        with pytest.raises(ValueError, match="number of atol values must be the same"):
            assert_close_with_reference_conversion(
                [res1, res2],
                [ref1, ref2],
                output_dtypes=[cutlass.Float32, cutlass.Float32],
                atols=[1e-2, 1e-2, 1e-2],  # Wrong count
            )

    def test_invalid_output_dtype_raises(self):
        """Test that invalid output dtype type raises ValueError."""
        reference = torch.tensor([1.0, 2.0], dtype=torch.float32)
        result = torch.tensor([1.0, 2.0], dtype=torch.float32)
        with pytest.raises(
            ValueError, match="Output dtype requires a torch.dtype or cutlass.Numeric"
        ):
            assert_close_with_reference_conversion(
                result, reference, output_dtypes=["invalid"]
            )


class TestNumpyAssertCloseWithReferenceConversion:
    def test_np_array_basic(self):
        """Test basic comparison with numpy arrays."""
        reference = np.array([1.0, 2.0, 3.0], dtype=np.float32)
        result = np.array([1.0, 2.0, 3.0], dtype=np.float32)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Float32
        )

    def test_cutlass_float16_dtype_conversion(self):
        """Test dtype conversion from float32 reference to float16 result."""
        reference = np.array([1.0, 2.0, 3.0], dtype=np.float32)
        result = np.array([1.0, 2.0, 3.0], dtype=np.float16)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Float16
        )

    def test_overflow_float16(self):
        """Test that overflow values are not clamped with non-narrow datatype."""
        # Create reference with values outside float16 range
        reference = np.array([1e10, -1e10, 1.0], dtype=np.float32)
        result = np.array([float("inf"), float("-inf"), 1.0], dtype=np.float16)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Float16
        )

    def test_overflow_saturation_float8_e4m3fn(self):
        """Test that overflow values are clamped to dtype range."""
        # Create reference with values outside float8_e4m3fn range
        reference = np.array([1e10, -1e10, 1.0], dtype=np.float32)
        # Result should be saturated to float8_e4m3fn max/min
        result = np.array([448.0, -448.0, 1.0], dtype=jnp.float8_e4m3fn)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=jnp.float8_e4m3fn
        )

    def test_numpy_float16_dtype_conversion(self):
        """Test using np.dtype directly instead of cutlass.Numeric."""
        reference = np.array([1.0, 2.0], dtype=np.float32)
        result = np.array([1.0, 2.0], dtype=np.float16)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=np.float16
        )

    def test_mismatched_tensor_types_raises(self):
        """Test that mixing numpy and torch tensors raises ValueError."""
        reference = np.array([1.0, 2.0], dtype=np.float32)
        result = torch.tensor([1.0, 2.0], dtype=torch.float32)
        with pytest.raises(
            ValueError, match="jax array and result tensor is a torch tensor"
        ):
            assert_close_with_reference_conversion(
                result, reference, output_dtypes=cutlass.Float32
            )


class TestJaxAssertCloseWithReferenceConversion:
    def test_jax_array_float8_e4m3fn_with_cutlass_dtype(self):
        """Test jax float8_e4m3fn arrays with cutlass.Float8E4M3FN output dtype."""
        reference = jnp.array([1.0, -1.0, 0.5], dtype=jnp.float32)
        result = jnp.array([1.0, -1.0, 0.5], dtype=jnp.float8_e4m3fn)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Float8E4M3FN
        )

    def test_jax_array_float8_e5m2_with_cutlass_dtype(self):
        """Test jax float8_e5m2 arrays with cutlass.Float8E5M2 output dtype."""
        reference = jnp.array([1.0, -1.0, 0.5], dtype=jnp.float32)
        result = jnp.array([1.0, -1.0, 0.5], dtype=jnp.float8_e5m2)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Float8E5M2
        )

    def test_jax_array_overflow_clamp_float8_e4m3fn(self):
        """Test overflow clamping for jax float8_e4m3fn arrays."""
        reference = jnp.array([500.0, -500.0, 1.0], dtype=jnp.float32)
        result = jnp.array([448.0, -448.0, 1.0], dtype=jnp.float8_e4m3fn)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Float8E4M3FN
        )


class TestEdgeCasesAssertCloseWithReferenceConversion:
    def test_none_rtols_atols_defaults(self):
        """Test that None rtols/atols default to 0.0."""
        reference = torch.tensor([1.0, 2.0, 3.0], dtype=torch.float32)
        result = torch.tensor([1.0, 2.0, 3.0], dtype=torch.float32)
        # Should work with exact match when rtols/atols are None
        assert_close_with_reference_conversion(
            result,
            reference,
            output_dtypes=cutlass.Float32,
            rtols=None,
            atols=None,
        )
        result_outside_tolerance = torch.tensor([1.1, 2.1, 3.1], dtype=torch.float32)
        with pytest.raises(AssertionError):
            assert_close_with_reference_conversion(
                result_outside_tolerance,
                reference,
                output_dtypes=cutlass.Float32,
                rtols=None,
                atols=None,
            )

    def test_empty_tensor(self):
        """Test comparison with empty tensors."""
        reference = torch.tensor([], dtype=torch.float32)
        result = torch.tensor([], dtype=torch.float32)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Float32
        )

    def test_torch_equals_nan(self):
        """Test NaN equality does not raise on assertion."""
        reference = torch.tensor([1.0, float("nan"), 3.0], dtype=torch.float16)
        result = torch.tensor([1.0, float("nan"), 3.0], dtype=torch.float16)
        assert_close_with_reference_conversion(
            result,
            reference,
            output_dtypes=cutlass.Float16,
            clamp=False,
            equal_nan=True,
        )

    def test_numpy_equals_nan(self):
        """Test NaN equality does not raise on assertion."""
        reference = np.array([1.0, float("nan"), 3.0], dtype=np.float32)
        result = np.array([1.0, float("nan"), 3.0], dtype=np.float32)
        assert_close_with_reference_conversion(
            result,
            reference,
            output_dtypes=cutlass.Float32,
            clamp=False,
            equal_nan=True,
        )

    def test_clamp_mode_enum_clamp(self):
        """Test that ClampMode.Clamp enum value works correctly."""
        # Create reference with values outside float16 range
        reference = torch.tensor([1e10, -1e10, 1.0], dtype=torch.float32)
        # Result should be saturated to float16 max/min
        result = torch.tensor([65504.0, -65504.0, 1.0], dtype=torch.float16)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Float16, clamp=ClampMode.Clamp
        )

    def test_clamp_mode_enum_no_clamp(self):
        """Test that ClampMode.NoClamp enum value works correctly."""
        reference = torch.tensor([1.0, float("inf"), 3.0], dtype=torch.float32)
        result = torch.tensor([1.0, float("inf"), 3.0], dtype=torch.float32)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Float32, clamp=ClampMode.NoClamp
        )

    def test_restricted_clamp_mode_clamp_on_float16(self):
        """Test that ClampMode.ClampOnRestrictedDtypes doesn't clamp on float16."""
        # float16 is a restricted dtype, so should not clamp
        reference = torch.tensor([1.0, float("inf"), 3.0], dtype=torch.float32)
        result = torch.tensor([1.0, float("inf"), 3.0], dtype=torch.float16)
        # Should not raise ValueError when clamp=ClampMode.ClampOnRestrictedDtypes with float16
        assert_close_with_reference_conversion(
            result,
            reference,
            output_dtypes=cutlass.Float16,
            clamp=ClampMode.ClampOnRestrictedDtypes,
        )

    def test_restricted_clamp_mode_clamp_on_int8(self):
        """Test that ClampMode.ClampOnRestrictedDtypes doesn't clamp on int8."""
        # int8 is a restricted dtype, so should not clamp
        reference = torch.tensor([1000, -1000, 1], dtype=torch.int32)
        # When not clamped, overflow values will wrap or become invalid
        result = torch.tensor([-24, 24, 1], dtype=torch.int8)
        # Should not clamp overflow values for int8
        assert_close_with_reference_conversion(
            result,
            reference,
            output_dtypes=cutlass.Int8,
            clamp=ClampMode.ClampOnRestrictedDtypes,
        )

    def test_restricted_clamp_mode_clamp_on_uint8(self):
        """Test that ClampMode.ClampOnRestrictedDtypes doesn't clamp on uint8."""
        # uint8 is a restricted dtype, so should not clamp
        reference = torch.tensor([1000, 500, 1], dtype=torch.int32)
        # When not clamped, overflow values will wrap
        result = torch.tensor([232, 244, 1], dtype=torch.uint8)
        # Should not clamp overflow values for uint8
        assert_close_with_reference_conversion(
            result,
            reference,
            output_dtypes=cutlass.Uint8,
            clamp=ClampMode.ClampOnRestrictedDtypes,
        )

    def test_restricted_clamp_mode_clamp_on_float8_e4m3fn(self):
        """Test that ClampMode.ClampOnRestrictedDtypes DOES clamp on float8_e4m3fn (not in NOCLAMP list)."""
        # float8_e4m3fn is NOT in NOCLAMP list, so should clamp
        reference = torch.tensor([500.0, -500.0, 1.0], dtype=torch.float32)
        # Result should be clamped to float8_e4m3fn range
        result = torch.tensor([448.0, -448.0, 1.0], dtype=torch.float8_e4m3fn)
        # Should clamp overflow values for float8_e4m3fn
        assert_close_with_reference_conversion(
            result,
            reference,
            output_dtypes=cutlass.Float8E4M3FN,
            clamp=ClampMode.ClampOnRestrictedDtypes,
        )

    def test_restricted_clamp_mode_clamp_on_float8_e5m2(self):
        """Test that ClampMode.ClampOnRestrictedDtypes DOES clamp on float8_e5m2 (not in NOCLAMP list)."""
        # float8_e5m2 is NOT in NOCLAMP list, so should clamp
        reference = torch.tensor([100000.0, -100000.0, 1.0], dtype=torch.float32)
        # Result should be clamped to float8_e5m2 range
        result = torch.tensor([57344.0, -57344.0, 1.0], dtype=torch.float8_e5m2)
        # Should clamp overflow values for float8_e5m2
        assert_close_with_reference_conversion(
            result,
            reference,
            output_dtypes=cutlass.Float8E5M2,
            clamp=ClampMode.ClampOnRestrictedDtypes,
        )

    def test_clamp_mode_bool_true(self):
        """Test that ClampMode can be converted from boolean True."""
        reference = torch.tensor([100000.0, -100000.0, 1.0], dtype=torch.float32)
        result = torch.tensor([57344.0, -57344.0, 1.0], dtype=torch.float8_e5m2)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Float8E5M2, clamp=True
        )

    def test_clamp_mode_bool_false(self):
        """Test that ClampMode can be converted from boolean False."""
        reference = torch.tensor([1000.0, -1000.0, 1.0], dtype=torch.float32)
        result = torch.tensor(
            [float("nan"), -float("nan"), 1.0], dtype=torch.float8_e4m3fn
        )
        assert_close_with_reference_conversion(
            result,
            reference,
            output_dtypes=cutlass.Float8E4M3FN,
            clamp=False,
            equal_nan=True,
        )

    def test_numpy_reference_jax_result_float32(self):
        """Test numpy reference array with jax result array."""
        reference = np.array([1.0, 2.0, 3.0], dtype=np.float32)
        result = jnp.array([1.0, 2.0, 3.0], dtype=jnp.float32)
        assert_close_with_reference_conversion(
            result, reference, output_dtypes=cutlass.Float32
        )


def _make_gemm_args(K: int, accumulator_type) -> GemmArguments:
    """Minimal GEMM problem with contraction dimension ``K``, for tolerance tests."""
    A = torch.empty((8, K), dtype=torch.float16)
    B = torch.empty((K, 8), dtype=torch.float16)
    out = torch.empty((8, 8), dtype=torch.float16)
    return GemmArguments(A, B, out, accumulator_type=accumulator_type)


class TestGemmReferenceTolerances:
    def test_integer_accumulator_dtype(self):
        """Integer accumulator dtypes should have exact tolerances."""
        args = _make_gemm_args(K=1024, accumulator_type=cutlass.Int32)
        assert gemm_reference_tolerances(args) == GemmReferenceTolerances(
            rtol=0.0, atol=0.0
        )

    def test_k_below_threshold_is_exact(self):
        """Below K=512, no accumulation error is expected, so tolerances are exact."""
        args = _make_gemm_args(K=511, accumulator_type=cutlass.Float16)
        assert gemm_reference_tolerances(args) == GemmReferenceTolerances(
            rtol=0.0, atol=0.0
        )

    def test_k_at_threshold(self):
        """K=512 is the documented anchor point where rtol starts at 0.001."""
        args = _make_gemm_args(K=512, accumulator_type=cutlass.Float16)
        tol = gemm_reference_tolerances(args)
        assert tol.atol == 0.0
        assert tol.rtol == pytest.approx(0.001, rel=1e-6)

    def test_k_above_threshold_grows(self):
        """rtol grows past its K=512 base value as K increases further."""
        args = _make_gemm_args(K=1500, accumulator_type=cutlass.Float16)
        tol = gemm_reference_tolerances(args)
        assert tol.rtol > 0.001

    def test_fp16_accumulator_looser_than_fp32(self):
        """fp16's larger ULP should recommend a looser rtol than fp32 at the same K."""
        K = 1500
        fp16_tol = gemm_reference_tolerances(_make_gemm_args(K, cutlass.Float16))
        fp32_tol = gemm_reference_tolerances(_make_gemm_args(K, cutlass.Float32))
        assert fp16_tol.rtol > fp32_tol.rtol
