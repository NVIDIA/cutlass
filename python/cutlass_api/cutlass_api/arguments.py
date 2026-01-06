# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

from collections import OrderedDict
from dataclasses import dataclass, field, fields
from typing import TYPE_CHECKING, get_type_hints

if TYPE_CHECKING:
    from collections.abc import Callable

    from cutlass_api.metadata import (
        ElementwiseOperandsMetadata,
        GemmOperandsMetadata,
    )

import cutlass
import cutlass.cute as cute

from cutlass_api.fusion import EmptyTensor, trace, trace_in_out
from cutlass_api.fusion.library import LayoutType
from cutlass_api.typing import NumericLike, TensorLike
from cutlass_api.utils import (
    TensorWrapper,
    add_batch_mode,
    is_torch_tensor,
    to_cutlass_type,
)


@dataclass
class PerformanceControls:
    pass


class EpilogueArguments:
    def __init__(
        self,
        epilogue_fn: Callable | str,
        **kwargs,
    ):
        """
        Describes a user-defined epilogue that is performed on top of the operation
        described by the primary `RuntimeArguments`.

        It encapsulates an epilogue function and its arguments needed to
        determine the functional operation of an epilogue pattern.

        To support flexible definition of epilogues, `EpilogueArguments` is
        defined generically as taking in an `epilogue_fn` and additional `kwargs`.

        Under the hood, the AST for `epilogue_fn` is parsed to determine the
        operands and outputs of the epilogue. `kwargs` must contain Tensors or scalars
        for all operands and outputs in the provided epilogue.

        Structure of `epilogue_fn`
        --------------------------
        Epilogue fusion patterns are defined via Python functions that perform Tensor-level
        operations -- using a `torch.Tensor` (for example) resulting from matrix multiplication,
        the function must be able to compute the desired results of the epilogue.

        The structure of these functions is as follows:
        ```python
        def custom_epi_name(accum, *args) -> Union[TensorType, tuple[TensorType]]:
            '''
            :param accum: result of matrix multiplication, convolution, etc. before the epilogue
            :type accum: TensorType
            :param args: additional arguments to be used in the epilogue (e.g., aux tensors)
            :type args: list[Union[TensorType, ScalarType]]

            :returns: at least one tensor resulting from the operation of the epilogue
            :rtype: Union[TensorType, tuple[TensorType]]
            '''
            # Do some compute
            return D # and potentially other values
        ```

        `epilogue_fn` must be a Python function or strign representation of a Python function
        that **must** satisfy the following constraints:
            - Take in a first positional argument named `accum` that represents the result
              of operation just before the epilogue is to be performed. For example, in a
              GEMM, `accum = A @ B`.
            - Return at least one tensor that results from computing the epilogue.
              Currently, the return list must contain at least one output named `D`,
              though this constraint may be loosened in the future.

        Each additional argument following `accum` in the function definition must be
        a Tensor or scalar to be loaded. Each variable in the return statement represents
        a Tensor or scalar to be stored. The underlying implementation of the epilogue in
        the kernel will determine how operands are loaded and stored.

        Structure of `kwargs`
        ----------------------
        `kwargs` must contain Tensors or scalars for all operands and outputs in the provided epilogue.
        For example, with an epilogue of:
        ```python
            def my_epi(accum, alpha, C, beta):
                F = (accum * alpha) + (C * beta)
                D = relu(F)
                return D, F
        ```
        A user would need to construct epilogue arguments as follows:
        ```python
            epi_args = EpilogueArguments(
                my_epi,
                alpha=..., C=..., beta=..., D=..., F=...
            )
        ```

        :param epilogue_fn: The epilogue function to be traced.
        :type epilogue_fn: Optional[Union[Callable, str]]
        :param kwargs: Additional keyword arguments consisting of the metadata
                    for operands and outputs of the epilogue function.
        :type kwargs: dict
        """
        epilogue_inputs: list[str] = []
        epilogue_outputs: list[str] = []
        if epilogue_fn is not None:
            # Parse the epilogue_fn AST to get the required input and output arguments
            epilogue_inputs, epilogue_outputs = trace_in_out(epilogue_fn)

        # Get required input and output arguments from kwargs
        self.tensors = OrderedDict()
        for kw in epilogue_inputs + epilogue_outputs:
            if kw not in kwargs:
                raise ValueError(
                    f"Argument {kw} is not provided in the kwargs of the EpilogueArguments constructor"
                )
            self.tensors[kw] = kwargs[kw]
            del kwargs[kw]

        if len(kwargs) > 0:
            raise ValueError(
                f"Unexpected keyword arguments for epilogue: {kwargs.keys()}"
            )

        self.epilogue_fn = epilogue_fn

    @property
    def parameters(self) -> list[cute.Tensor | cutlass.Numeric]:
        """Returns the list of input and output parameters of the epilogue"""
        return list(self.tensors.values())

    @property
    def parameter_names(self) -> list[str]:
        """Returns the list of names of the input and output parameters of the epilogue"""
        return list(self.tensors.keys())

    def add_batch_modes(self):
        for name in self.tensors:
            self.tensors[name] = add_batch_mode(self.tensors[name])

    def to_tensor_wrappers(self, permute: list[int] | None = None):
        """Converts the input and output parameters of the epilogue to TensorWrappers"""
        for k, v in self.tensors.items():
            if is_torch_tensor(v):
                if permute is not None:
                    v = v.permute(permute)

                self.tensors[k] = TensorWrapper(v)

    def trace(
        self, accumulator_shape: tuple[int, ...], accumulator_type: cutlass.Numeric
    ):
        """
        Traces the epilogue function and generates an internal representation of the epilogue.

        :param accumulator_shape: The shape of the accumulator tensor. For example, for a GEMM, this would be the shape of the output tensor.
        :type accumulator_shape: tuple[int, ...]
        :param accumulator_type: The datatype of the accumulator tensor.
        :type accumulator_type: cutlass.Numeric
        """
        accumulator = EmptyTensor(
            element=accumulator_type,
            shape=accumulator_shape,
            layout_tag=LayoutType.RowMajor,
        )
        tensors_for_tracing = {**self.tensors, "accum": accumulator}

        # Parse the AST of the epilogue_fn again, this time with the set of required
        # tensors. This pass converts the epilogue into an internal representation and
        # performs a limited set of correctness checks (e.g., shape matches)
        #
        # Since all current providers are not based on C++ EVT, we do not need to convert
        # the DAG to a tree. If a provider that tightly matches the C++ EVT template structure,
        # this will need to be revisited.
        self.traced_epilogue = trace(
            self.epilogue_fn, tensors_for_tracing, requires_conversion_to_tree=False
        )


@dataclass
class RuntimeArguments:
    """
    Base class for container of all runtime operands and other runtime parameters needed
    by a kernel. This includes primary runtime operands to the operation, as well as
    any custom epilogue fusions and runtime performance knobs.

    Subclasses map to an operation type (e.g., GEMM, elementwise). These subclasses have
    additional fields that are specific to the operation type.

    :param epilogue: Optional custom epilogue fusion to be performed after the operation.
    :type epilogue: Optional[EpilogueArguments]
    :param performance: Optional performance controls to be used by the kernel.
    :type performance: Optional[PerformanceControls]
    """

    epilogue: EpilogueArguments | None = field(default=None, kw_only=True)
    performance: PerformanceControls | None = field(default=None, kw_only=True)

    def _validate(self):
        """
        Checks that the arguments are valid.
        This is run before all fields have been converted to TensorWrapper and cutlass.Numeric.
        """

    def __post_init__(self):
        self._validate()
        self._convert_to_internal_types()

    def _convert_to_internal_types(self):
        """
        Converts all fields to their internal types.
        """
        type_hints = get_type_hints(type(self))
        for f in fields(self):
            hint = type_hints.get(f.name)
            value = getattr(self, f.name)

            # Find all fields that are annotated as TensorLike,
            # and wrap them in TensorWrapper
            if hint is TensorLike:
                setattr(self, f.name, TensorWrapper(value))
            elif hint is NumericLike:
                setattr(self, f.name, to_cutlass_type(value))


@dataclass
class GemmArguments(RuntimeArguments):
    """
    Arguments for a Generalized Matrix Multiplication (GEMM) operation: out = A @ B

    The tensors must be all rank-3 or all rank-2.
    L: Number of batches
    M: Number of rows in A and out
    K: Number of columns in A and rows in B
    N: Number of columns in B and out

    :param A: Input tensor A of shape (L, M, K) or (M, K)
    :type A: TensorLike
    :param B: Input tensor B of shape (L, K, N) or (K, N)
    :type B: TensorLike
    :param out: Output tensor C of shape (L, M, N) or (M, N)
    :type out: TensorLike
    :param accumulator_type: Data type of the accumulator
    :type accumulator_type: NumericLike
    """

    A: TensorLike
    B: TensorLike
    out: TensorLike
    accumulator_type: NumericLike

    def to_operands_metadata(self) -> GemmOperandsMetadata:
        from cutlass_api.metadata import GemmOperandsMetadata

        return GemmOperandsMetadata.from_args(self)

    def _validate(self):
        """
        Checks that the arguments are valid.
        """
        if len(self.A.shape) < 2 or len(self.A.shape) > 3:
            raise ValueError(
                f"A must be a tensor of rank 2 or 3 (L=1, M, K), got {self.A.shape}"
            )
        if len(self.B.shape) < 2 or len(self.B.shape) > 3:
            raise ValueError(
                f"B must be a tensor of rank 2 or 3 (L=1, K, N), got {len(self.B.shape)}"
            )
        if len(self.out.shape) < 2 or len(self.out.shape) > 3:
            raise ValueError(
                f"out must be a tensor of rank 2 or 3 (L=1, M, N), got {len(self.out.shape)}"
            )
        if self.A.shape[-1] != self.B.shape[-2]:
            raise ValueError(
                f"A's K dimension ({self.A.shape[-1]}) must be equal to B's K dimension ({self.B.shape[-2]}). A shape (L, M, K): {self.A.shape}, B shape (L, K, N): {self.B.shape}"
            )
        if self.out.shape[-2] != self.A.shape[-2]:
            raise ValueError(
                f"out's M dimension ({self.out.shape[-2]}) must be equal to A's M dimension ({self.A.shape[-2]}). A shape (L, M, K): {self.A.shape}, out shape (L, M, N): {self.out.shape}"
            )
        if self.out.shape[-1] != self.B.shape[-1]:
            raise ValueError(
                f"out's N dimension ({self.out.shape[-1]}) must be equal to B's N dimension ({self.B.shape[-1]}). B shape (L, K, N): {self.B.shape}, out shape (L, M, N): {self.out.shape}"
            )
        if self.A.shape[:-2] != self.B.shape[:-2]:
            raise ValueError(
                f"A & B must have the same rank and batch dimension (if any). A shape (L, M, K): {self.A.shape}, B shape (L, K, N): {self.B.shape}"
            )
        if self.out.shape[:-2] != self.A.shape[:-2]:
            raise ValueError(
                f"out & A must have the same rank and batch dimension (if any). out shape (L, M, N): {self.out.shape}, A shape (L, M, K): {self.A.shape}"
            )

        if isinstance(self.epilogue, EpilogueArguments):
            L = self.A.shape[0] if len(self.A.shape) == 3 else 1
            M, N = self.A.shape[-2], self.B.shape[-1]
            accum_shape = (L, M, N)
            self.epilogue.trace(accum_shape, self.accumulator_type)
            self.epilogue.to_tensor_wrappers()


@dataclass
class ElementwiseArguments(RuntimeArguments):
    """
    Arguments needed for an elementwise operation.

    :param A: The input tensor A.
    :type A: TensorLike
    :param B: The input tensor B.
    :type B: TensorLike
    :param out: The output tensor.
    :type out: TensorLike
    """

    A: TensorLike
    B: TensorLike
    out: TensorLike

    def to_operands_metadata(self) -> ElementwiseOperandsMetadata:
        from cutlass_api.metadata import ElementwiseOperandsMetadata

        return ElementwiseOperandsMetadata.from_args(self)

    def _validate(self):
        """
        Checks that the arguments are valid.
        """
        if self.A.shape != self.B.shape:
            raise ValueError(
                f"A.shape ({self.A.shape}) must be equal to B.shape ({self.B.shape})"
            )
        if self.out.shape != self.A.shape:
            raise ValueError(
                f"out.shape ({self.out.shape}) must be equal to A.shape ({self.A.shape})"
            )
