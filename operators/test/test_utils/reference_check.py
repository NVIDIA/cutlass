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

from __future__ import annotations

from enum import IntEnum
from functools import partial
from typing import TYPE_CHECKING

import torch

if TYPE_CHECKING:
    from collections.abc import Callable

    import jax.numpy as jnp
    import numpy as np

    import cutlass

    ArrayLike = torch.Tensor | np.ndarray | jnp.ndarray
    DtypeLike = cutlass.Numeric | torch.dtype | np.dtype | jnp.dtype
import cutlass
import cutlass.torch

import cutlass.operators.utils.dtype as dtype_utils
from cutlass.operators.utils.tensor import (
    is_jax_array,
    is_numpy_tensor,
    is_torch_tensor,
)


class ReferenceCheckWarning(UserWarning):
    """Warning related to reference check numerics."""


class ClampMode(IntEnum):
    NoClamp = 0  # bool(False) -> no clamp
    Clamp = 1  # bool(True) -> clamp
    ClampOnRestrictedDtypes = 2  # Clamp on narrow precision dtype


def get_clamp_torch_dtypes():
    """Get the dtypes that will be clamped under ClampOnRestrictedDtypes.
    These dtypes are narrow precision float datatypes that when used
    in kernels as output dtypes, typically use the saturation-to-finite
    modifier in mma ops. Therefore, to maintain same behavior between
    external numerical libraries and operators, we restrict the dtypes' behavior
    to clamp the reference tensor output to its max/min finite range.
    """
    import torch

    clamp_torch_dtypes = {
        torch.float8_e4m3fn,
        torch.float8_e5m2,
    }
    return clamp_torch_dtypes


def get_clamp_jax_dtypes():
    """Get the dtypes that will be clamped under ClampOnRestrictedDtypes."""
    import jax.numpy as jnp

    clamp_jax_dtypes = {
        jnp.dtype(jnp.float8_e4m3fn),
        jnp.dtype(jnp.float8_e5m2),
    }
    return clamp_jax_dtypes


def get_clamp_cutlass_dtypes():
    """Get the cutlass dtypes that will be clamped under ClampOnRestrictedDtypes."""
    clamp_cutlass_dtypes = {
        cutlass.Float8E4M3FN,
        cutlass.Float8E5M2,
    }
    return clamp_cutlass_dtypes


def get_torch_default_tolerances():
    """PyTorch per-dtype default ``(rtol, atol)`` tolerances.

    Snapshotted from
    https://docs.pytorch.org/docs/stable/testing.html#torch.testing.assert_close
    """
    import torch

    return {
        torch.float16: (1e-3, 1e-5),
        torch.bfloat16: (1.6e-2, 1e-5),
        torch.float32: (1.3e-6, 1e-5),
        torch.float64: (1e-7, 1e-7),
    }


def check_as_numpy_or_jax(
    out: np.ndarray | jnp.ndarray,
    reference: np.ndarray | jnp.ndarray,
    output_dtype: np.dtype | jnp.dtype | cutlass.Numeric,
    rtol: float,
    atol: float,
    equal_nan: bool,
    msg: str,
    skip_check: bool,
    clamp_mode: ClampMode,
) -> np.ndarray:
    """Helper functions for assert_close_with_reference_conversion when the
    reference uses numpy or jax arrays. Returns converted ref as numpy array.
    """
    import jax.numpy as jnp
    import numpy as np

    convert_fn = np.ndarray.astype
    base = np.float32

    safe_emulate_fn = partial(convert_fn, dtype=base)

    # convert from jax to numpy array
    # (numpy and jax share dtypes if jax is imported with numpy)
    reference = np.asarray(reference)
    out = np.asarray(out)

    if isinstance(output_dtype, type) and issubclass(output_dtype, cutlass.Numeric):
        embedded_dtype = dtype_utils.jax_type_from_cutlass_type(output_dtype)
    else:
        # raises a TypeError if cannot convert
        embedded_dtype = jnp.dtype(output_dtype)

    if clamp_mode == ClampMode.ClampOnRestrictedDtypes:
        clamp = embedded_dtype in get_clamp_jax_dtypes()
    elif clamp_mode == ClampMode.Clamp:
        clamp = True
    elif clamp_mode == ClampMode.NoClamp:
        clamp = False
    else:
        raise ValueError(f"Unsupported clamp mode: {clamp_mode}")

    # Check that out tensor dtype matches expected dtype
    if out.dtype != embedded_dtype:
        raise ValueError(
            f"Result tensor dtype {out.dtype} does not match target dtype {output_dtype} ({embedded_dtype})"
        )

    if clamp:
        if jnp.issubdtype(embedded_dtype, jnp.floating):
            embedded_info = jnp.finfo(embedded_dtype)
        elif jnp.issubdtype(embedded_dtype, jnp.integer):
            embedded_info = jnp.iinfo(embedded_dtype)
        else:
            raise ValueError(f"Unsupported dtype {embedded_dtype}")

        # clamp the value of the reference tensor to the finite range of the output dtype
        reference = np.clip(reference, min=embedded_info.min, max=embedded_info.max)

    # Convert reference tensor if it doesn't match expected dtype
    if reference.dtype != embedded_dtype:
        reference = convert_fn(reference, embedded_dtype)

    if not skip_check:
        np.testing.assert_allclose(
            safe_emulate_fn(out),
            safe_emulate_fn(reference),
            rtol=rtol,
            atol=atol,
            equal_nan=equal_nan,
            err_msg=msg,
        )
    return reference


def check_as_torch(
    out: torch.Tensor,
    reference: torch.Tensor,
    output_dtype: torch.dtype,
    rtol: float,
    atol: float,
    equal_nan: bool,
    msg: str,
    skip_check: bool,
    clamp_mode: ClampMode,
) -> torch.Tensor:
    """Helper functions for assert_close_with_reference_conversion when the
    reference uses PyTorch tensors. Returns converted ref as torch tensor.
    """
    import torch

    convert_fn = torch.Tensor.to
    base = torch.float32
    safe_emulate_fn = partial(convert_fn, dtype=base)

    # Normalize output dtype to torch dtype
    if isinstance(output_dtype, torch.dtype):
        embedded_dtype = output_dtype
    elif isinstance(output_dtype, type) and issubclass(output_dtype, cutlass.Numeric):
        embedded_dtype = cutlass.torch.dtype(output_dtype)
    else:
        raise ValueError(
            f"Output dtype requires a torch.dtype or cutlass.Numeric, got {output_dtype}"
        )

    if clamp_mode == ClampMode.ClampOnRestrictedDtypes:
        clamp = embedded_dtype in get_clamp_torch_dtypes()
    elif clamp_mode == ClampMode.Clamp:
        clamp = True
    elif clamp_mode == ClampMode.NoClamp:
        clamp = False
    else:
        raise ValueError(f"Unsupported clamp mode: {clamp_mode}")

    # Check that out tensor dtype matches expected dtype
    if out.dtype != embedded_dtype:
        raise ValueError(
            f"Result tensor dtype {out.dtype} does not match target dtype {output_dtype} ({embedded_dtype})"
        )

    if clamp:
        if embedded_dtype.is_floating_point:
            embedded_info = torch.finfo(embedded_dtype)
        elif embedded_dtype.is_complex:
            raise ValueError(f"Complex dtype {embedded_dtype} is not supported")
        else:
            embedded_info = torch.iinfo(embedded_dtype)

        # clamp the value of the reference tensor to the finite range of the output dtype
        reference = torch.clamp(reference, min=embedded_info.min, max=embedded_info.max)

    # Convert reference tensor if it doesn't match expected dtype
    if reference.dtype != embedded_dtype:
        reference = convert_fn(reference, embedded_dtype)

    # Do comparisons in float32 because testing.assert_close and testing.assert_allclose
    # is not safe, doesn't support atol and rtol on lower-bitwidth datatypes
    if not skip_check:
        torch.testing.assert_close(
            safe_emulate_fn(out),
            safe_emulate_fn(reference),
            rtol=rtol,
            atol=atol,
            equal_nan=equal_nan,
            msg=msg,
        )
    return reference


def assert_close_with_reference_conversion(
    result_tensors: ArrayLike | list[ArrayLike],
    accumulator_reference_tensor: ArrayLike | list[ArrayLike],
    output_dtypes: DtypeLike | list[DtypeLike],
    rtols: float | list[float] = None,
    atols: float | list[float] = None,
    equal_nan: bool = False,
    msg: str = None,
    skip_check: bool = False,
    clamp: ClampMode | int = ClampMode.ClampOnRestrictedDtypes,
) -> torch.Tensor | np.ndarray | list[torch.Tensor | np.ndarray]:
    """
    Asserts that the result tensor is similar to the reference tensor.
    This function automatically handles:
    - Converting the reference tensor to the correct output dtype
    - Handling overflow as saturation instead of NaN or Inf
    When reference checking multiple tensors at a time, they must be passed in the same order.

    Args:
        result_tensors (ArrayLike | list[ArrayLike]): The output tensors to compare against the reference. Can be a torch.Tensor, np.ndarray, or jnp.ndarray
        or a list of these types.
        accumulator_reference_tensor (ArrayLike | list[ArrayLike]): The reference tensor in accumulator dtype. Must be the same type as the result tensor.
        output_dtypes (DtypeLike | list[DtypeLike]): The dtypes of the output, can be a cutlass.Numeric, torch.dtype, np.dtype, or jnp.dtype
        or a list of these types.
        rtols (float | list[float]): The relative tolerance to use. Optional, if no value is set then will default to 0.0.
        atols (float | list[float]): The absolute tolerance to use. Optional, if no value is set then will default to 0.0.
        equal_nan (bool): If True, will compare NaN values as equal
        msg (str): The message to display if the assertion fails
        skip_check (bool): If True, will skip the ref check and return the reference tensors directly
        clamp (ClampMode | int): Configures whether to clamp the reference tensor to the range of the output dtype

    Returns:
        The reference tensors as torch.Tensor or np.array, after being converted to output dtype

    Raises:
        ValueError: If the number of result tensors, references, and output dtypes are not the same
        ValueError: If the number of rtol or atol values is >1 but not the same as the number of result tensors
        ValueError: If the reference tensor and result tensor types don't match
        ValueError: If the reference tensor is not a torch tensor, numpy array, or jax array
        ValueError: If the clamp mode is not supported
    """

    # Argument list preprocessing
    accumulator_reference_tensor = (
        [accumulator_reference_tensor]
        if not isinstance(accumulator_reference_tensor, list)
        else accumulator_reference_tensor
    )
    result_tensors = (
        [result_tensors] if not isinstance(result_tensors, list) else result_tensors
    )
    output_dtypes = (
        [output_dtypes] if not isinstance(output_dtypes, list) else output_dtypes
    )
    rtols = [rtols] if not isinstance(rtols, list) else rtols
    atols = [atols] if not isinstance(atols, list) else atols

    num_to_check = len(result_tensors)
    dtypes_match = num_to_check == len(output_dtypes)
    rtols_match = num_to_check == len(rtols)
    atols_match = num_to_check == len(atols)
    references_match = num_to_check == len(accumulator_reference_tensor)

    if not all([dtypes_match, references_match]):
        raise ValueError(
            "The number of result tensors, references, and output dtypes must be the same"
        )

    if not rtols_match:
        if len(rtols) == 1:
            rtols = (
                rtols * num_to_check
            )  # expands length of list to match number of tensors
        else:
            raise ValueError(
                "The number of rtol values must be the same as the number of result tensors"
            )
    if not atols_match:
        if len(atols) == 1:
            atols = (
                atols * num_to_check
            )  # expands length of list to match number of tensors
        else:
            raise ValueError(
                "The number of atol values must be the same as the number of result tensors"
            )

    clamp_mode = ClampMode(int(clamp))

    # When rtol/atol are not explicitly passed, they default to 0.0 (exact
    # match). Tests should compute the reference at the kernel's precision
    # rather than relax tolerances; the exception is hardware fast-math
    # transcendentals (tanh/exp/sigmoid), which need the dtype-default
    # tolerance from get_torch_default_tolerances.
    #
    # Call reference check for each set of reference, result, output_dtype, and rtol/atol
    for i, (reference, out, output_dtype, rtol, atol) in enumerate(
        zip(accumulator_reference_tensor, result_tensors, output_dtypes, rtols, atols)
    ):
        rtol = rtol if rtol is not None else 0.0
        atol = atol if atol is not None else 0.0

        if is_torch_tensor(reference):
            if is_numpy_tensor(out) or is_jax_array(out):
                raise ValueError(
                    "Reference tensor is a torch tensor and result tensor is not, this is not supported"
                )
            accumulator_reference_tensor[i] = check_as_torch(
                out,
                reference,
                output_dtype,
                rtol,
                atol,
                equal_nan,
                msg,
                skip_check,
                clamp_mode,
            )
        elif is_numpy_tensor(reference) or is_jax_array(reference):
            if is_torch_tensor(out):
                raise ValueError(
                    "Reference tensor is a jax array and result tensor is a torch tensor, this is not supported"
                )
            accumulator_reference_tensor[i] = check_as_numpy_or_jax(
                out,
                reference,
                output_dtype,
                rtol,
                atol,
                equal_nan,
                msg,
                skip_check,
                clamp_mode,
            )
        else:
            raise ValueError(f"Unsupported tensor type: {type(reference)}")

    return accumulator_reference_tensor


def reference_scaled_mm(
    A: torch.Tensor,
    B: torch.Tensor,
    scale_A: torch.Tensor,
    scale_B: torch.Tensor,
    out_dtype: torch.dtype,
    transform_sf: Callable[[torch.Tensor], torch.Tensor] = lambda x: x,
):
    """
    Computes a reference scaled mm operation. Currently, torch._scaled_mm does not support batch mode.
    When a batch mode is present, this function iterates through each problem in the batch.

    :param A: The A tensor
    :type A: torch.Tensor
    :param B: The B tensor
    :type B: torch.Tensor
    :param scale_A: The scale factor tensor for operand A
    :type scale_A: torch.Tensor
    :param scale_B: The scale factor tensor for operand B
    :type scale_B: torch.Tensor
    :param out_dtype: The output dtype
    :type out_dtype: torch.dtype
    :param transform_sf: A function to transform the scale factor tensors to the correct shape for the scaled mm operation
    :type transform_sf: Callable
    :return: The reference scaled mm operation
    """
    if len(A.shape) == 2:
        return torch._scaled_mm(
            A, B, scale_a=scale_A, scale_b=scale_B, out_dtype=out_dtype
        )
    else:
        # torch._scaled_mm does not support batch mode. Iterate through each problem in the batch
        L, M, N = A.shape[0], A.shape[1], B.shape[2]
        scale_A = scale_A.view(L, -1)
        scale_B = scale_B.view(L, -1)
        reference = torch.empty((L, M, N), device=A.device, dtype=out_dtype)
        for l_idx in range(L):
            reference[l_idx] = torch._scaled_mm(
                A[l_idx],
                B[l_idx],
                scale_a=transform_sf(scale_A[l_idx]),
                scale_b=transform_sf(scale_B[l_idx]),
                out_dtype=out_dtype,
            )
        return reference
