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

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import TYPE_CHECKING, Self

if TYPE_CHECKING:
    import cutlass

import cutlass.cute as cute

from cutlass_api.arguments import (
    ElementwiseArguments,
    EpilogueArguments,
    GemmArguments,
    RuntimeArguments,
)
from cutlass_api.status import Status
from cutlass_api.utils import TensorWrapper


def _convert_stride(shape: tuple[int, ...], stride: tuple[int, ...]) -> tuple[int, ...]:
    """
    Zeros out modes of stride that have a shape of 1.

    :param shape: the shape of the tensor
    :type shape: tuple[int, ...]
    :param stride: the stride of the tensor
    :type stride: tuple[int, ...]

    :return: the converted stride
    :rtype: tuple[int, ...]
    """
    new_stride = []
    for i in range(len(shape)):
        if shape[i] == 1:
            new_stride.append(0)
        else:
            new_stride.append(stride[i])
    return new_stride


def _is_tuple_aligned(tup: tuple[int], divisibility: int, contiguous_dim: int) -> bool:
    """
    Check if the all elements of the shape/stride tuple are divisible by a given
    divisibility, except along the contiguous dimension.
    """
    return all(
        t % divisibility == 0 for dim, t in enumerate(tup) if dim != contiguous_dim
    )


def _get_max_pow2_divisibility(shape: tuple[int, ...], stride: tuple[int, ...]) -> int:
    """
    Get the maximum power of 2 divisibility met by the given shape and stride.
    This is the largest power of 2 that divides the number of elements in the major mode (with stride 1).

    :param shape: the shape of the tensor
    :type shape: tuple[int, ...]
    :param stride: the stride of the tensor
    :type stride: tuple[int, ...]

    :return: the maximum power of 2 divisibility by which the shape is divisible
    :rtype: int
    """
    if 1 not in stride:
        return 1
    major_mode_idx = stride.index(1)
    num_major_elements = shape[major_mode_idx]

    best_divisibility = 1
    while num_major_elements % (best_divisibility * 2) == 0:
        best_divisibility *= 2
    return best_divisibility


@dataclass
class TensorAttributes:
    """
    Description of a single tensor. This includes the data type, stride, and divisibility.

    :param dtype: The data type of the tensor.
    :type dtype: cutlass.Numeric
    :param stride: The stride of the tensor.
    :type stride: tuple[int, ...]
    :param divisibility: The divisibility requirement on a tensor's stride & shape elements
    :type divisibility: int
    :param ptr_alignment_bytes: The alignment of the tensor's data pointer, in bytes.
                          By default, it matches the number of bytes in stride/shape alignment.
    :type ptr_alignment_bytes: int
    """

    dtype: cutlass.Numeric  # F32, F16, etc.
    stride: tuple[int, ...]
    divisibility: int
    ptr_alignment_bytes: int

    def __init__(
        self,
        dtype: cutlass.Numeric,
        stride: tuple[int, ...],
        divisibility: int,
        ptr_alignment_bytes: int | None = None,
    ):
        self.dtype = dtype
        self.stride = stride
        self.divisibility = divisibility
        self.ptr_alignment_bytes = ptr_alignment_bytes or (
            (divisibility * dtype.width) // 8
        )

    def supports(self, operand: TensorWrapper | Self) -> Status:
        """
        Checks whether the provided args satisfy the properties described by
        these TensorAttributes.

        :param operand: The operand to check support for.
        :type operand: TensorWrapper | Self

        :return: Whether the provided operand satisfies the properties described by
        these TensorAttributes.
        :rtype: Status
        """
        if isinstance(operand, TensorWrapper):
            if operand.element_type != self.dtype:
                return Status.fail(
                    f"Expected element type {self.dtype}, got {operand.element_type}"
                )
        elif operand.dtype != self.dtype:
            return Status.fail(
                f"Expected element type {self.dtype}, got {operand.dtype}"
            )

        # Normalize the operand stride to have 0's where operand.shape is 1
        normalized_operand_stride = _convert_stride(operand.shape, operand.stride)

        # If the operand is batched, the expected stride is the same as the self.stride
        if len(self.stride) == len(normalized_operand_stride):
            expected_stride = self.stride
        # We can try if strides match without the batch mode
        elif len(self.stride) - 1 == len(normalized_operand_stride):
            expected_stride = self.stride[1:]
        else:
            return Status.fail(
                f"Expected tensor with strides of rank {len(self.stride)} (batched) or {len(self.stride) - 1} (unbatched), got {len(normalized_operand_stride)} ({normalized_operand_stride})"
            )

        # Strides are considered compatible if:
        #  1. They have the same rank (checked above)
        #  2. The leading mode is the same (or both are all 0)
        all_zeros = all(x == 0 for x in expected_stride) and all(
            x == 0 for x in normalized_operand_stride
        )

        # When setting stride from args, any modes of stride 1 and shape 1
        # are changed to have stride 0. Thus, there will only be one mode
        # with stride 1.
        contiguous_dim = expected_stride.index(1)
        if not all_zeros and normalized_operand_stride[contiguous_dim] != 1:
            return Status.fail(
                f"Expected stride[{contiguous_dim}] to be 1, got "
                f"{normalized_operand_stride[contiguous_dim]} "
                f"(strides: {normalized_operand_stride})"
            )

        # Check that divisibility constraints are met
        if isinstance(operand, TensorWrapper):
            if not _is_tuple_aligned(
                normalized_operand_stride, self.divisibility, contiguous_dim
            ):
                return Status.fail(
                    f"Expected operand stride to be divisible by {self.divisibility} for"
                    f"all non-contiguous modes, got {normalized_operand_stride}"
                )
        else:
            # When comparing another TensorAttribute, ensure its divisibility is a subset
            if operand.divisibility % self.divisibility != 0:
                return Status.fail(
                    f"Expected operand divisibility {operand.divisibility} to be divisible by {self.divisibility}"
                )

        # Check data ptr alignment, if available
        if (
            isinstance(operand, TensorWrapper)
            and operand.data_ptr % self.ptr_alignment_bytes != 0
        ):
            return Status.fail(
                f"Expected data pointer to be {self.ptr_alignment_bytes}B-aligned."
            )

        return Status.success()

    @staticmethod
    def from_tensor(tensor) -> Self:
        """
        Create a TensorAttributes from a tensor.

        :param tensor: The tensor to create a TensorAttributes from.
        :type tensor: cute.Tensor

        :return: The TensorAttributes corresponding to the provided tensor.
        :rtype: TensorAttributes
        """
        stride = _convert_stride(tensor.shape, tensor.stride)
        max_divisibility = _get_max_pow2_divisibility(tensor.shape, stride)
        return TensorAttributes(
            dtype=tensor.element_type, stride=stride, divisibility=max_divisibility
        )


@dataclass
class OperandsMetadata(ABC):
    """
    Base metadata class for descriptions of operands (e.g., GEMM A, B, out).
    """

    @abstractmethod
    def supports(self, args: RuntimeArguments) -> Status:
        """
        Checks whether the provided args satisfy the properties described by
        the operands in this metadata.

        :param args: The arguments to check support for.
        :type args: RuntimeArguments

        :return: Whether the provided args satisfy the properties described by
        the operands in this metadata.
        :rtype: Status
        """


@dataclass
class DesignMetadata(ABC):
    """
    Base metadata class for descriptions of design parameters for an operation
    (e.g., tile shape, cluster shape, etc.).
    """

    @abstractmethod
    def supports(self, args: RuntimeArguments) -> Status:
        """
        Checks whether the provided args satisfy the properties described by
        the design in this metadata.

        :param args: The arguments to check support for.
        :type args: RuntimeArguments

        :return: Whether the provided args satisfy the properties described by
        the design in this metadata.
        :rtype: Status
        """


@dataclass
class BLASDesignMetadata(DesignMetadata):
    """
    Design metadata for a basic-linear algebra subprogram (BLAS) operation.

    These include fields for tiling-related parameters (e.g., tile shape and cluster shape).
    """

    tile_shape: tuple[int, ...]
    cluster_shape: tuple[int, ...]

    def supports(self, args: RuntimeArguments) -> Status:
        """
        Checks whether the provided args satisfy the properties described by
        the design in this metadata.

        :param args: The arguments to check support for.
        :type args: RuntimeArguments

        :return: Whether the provided args satisfy the properties described by
        the design in this metadata.
        :rtype: Status
        """
        if args.performance is not None:
            return Status.fail(
                "BLASDesignMetadata does not yet support performance controls"
            )
        return Status.success()


@dataclass
class Sm100DesignMetadata(BLASDesignMetadata):
    """
    Design metadata for kernels in the SM100 architecture family.
    """

    # Whether to use a 2CTA MMA instruction
    use_2cta_mma: bool

    # Whether to use TMA to store the results of the operation
    use_tma_store: bool

@dataclass
class GemmOperandsMetadata(OperandsMetadata):
    """
    Metadata for the operands of a GEMM operation.

    :param A: Metadata for the input tensor A.
    :type A: TensorAttributes
    :param B: Metadata for the input tensor B.
    :type B: TensorAttributes
    :param out: Metadata for the output tensor.
    :type out: TensorAttributes
    :param accumulator_type: The data type of the accumulator tensor.
    :type accumulator_type: cutlass.Numeric
    """

    A: TensorAttributes
    B: TensorAttributes
    out: TensorAttributes
    accumulator_type: cutlass.Numeric

    def supports(self, other: GemmArguments | Self) -> Status:
        """
        Checks whether the provided args satisfy the properties described by
        the operands in this metadata.

        :param other: The arguments to check support for.
        :type other: GemmArguments | Self

        :return: Whether the provided args satisfy the properties described by
        the operands in this metadata.
        :rtype: Status
        """
        if isinstance(other, RuntimeArguments) and not isinstance(other, GemmArguments):
            return Status.fail(f"Expected GemmArguments, got {type(other)}")

        if not (status := self.A.supports(other.A)):
            return Status.fail(f"Operand `A` is unsupported: {status.error}")

        if not (status := self.B.supports(other.B)):
            return Status.fail(f"Operand `B` is unsupported: {status.error}")

        if not (status := self.out.supports(other.out)):
            return Status.fail(f"Operand `out` is unsupported: {status.error}")

        if self.accumulator_type != other.accumulator_type:
            return Status.fail(
                f"Expected accumulator type {self.accumulator_type}, got {other.accumulator_type}"
            )

        return Status.success()

    @staticmethod
    def from_args(args: GemmArguments) -> Self:
        """
        Create a GemmOperandsMetadata from a GemmArguments.

        :param args: The GemmArguments to create a GemmOperandsMetadata from.
        :type args: GemmArguments

        :return: The GemmOperandsMetadata corresponding to the provided GemmArguments.
        :rtype: GemmOperandsMetadata
        """
        return GemmOperandsMetadata(
            A=TensorAttributes.from_tensor(args.A),
            B=TensorAttributes.from_tensor(args.B),
            out=TensorAttributes.from_tensor(args.out),
            accumulator_type=args.accumulator_type,
        )


@dataclass
class ElementwiseOperandsMetadata(OperandsMetadata):
    """
    Metadata for the operands of an elementwise operation.

    :param A: Metadata for the input tensor A.
    :type A: TensorAttributes
    :param B: Metadata for the input tensor B.
    :type B: TensorAttributes
    :param out: Metadata for the output tensor.
    :type out: TensorAttributes
    """

    A: TensorAttributes
    B: TensorAttributes
    out: TensorAttributes

    def supports(self, other: ElementwiseArguments | Self) -> Status:
        """
        Checks whether the provided args satisfy the properties described by
        the operands in this metadata.

        :param other: The arguments to check support for.
        :type other: ElementwiseArguments | Self

        :return: Whether the provided args satisfy the properties described by
        the operands in this metadata.
        :rtype: Status
        """
        if isinstance(other, RuntimeArguments) and not isinstance(
            other, ElementwiseArguments
        ):
            return Status.fail(f"Expected ElementwiseArguments, got {type(other)}")

        if not (status := self.A.supports(other.A)):
            return Status.fail(f"Operand `A` is unsupported: {status.error}")

        if not (status := self.B.supports(other.B)):
            return Status.fail(f"Operand `B` is unsupported: {status.error}")

        if not (status := self.out.supports(other.out)):
            return Status.fail(f"Operand `out` is unsupported: {status.error}")

        return Status.success()

    @staticmethod
    def from_args(args: ElementwiseArguments) -> Self:
        """
        Create a ElementwiseOperandsMetadata from a ElementwiseArguments.

        :param args: The ElementwiseArguments to create a ElementwiseOperandsMetadata from.
        :type args: ElementwiseArguments

        :return: The ElementwiseOperandsMetadata corresponding to the provided ElementwiseArguments.
        :rtype: ElementwiseOperandsMetadata
        """
        return ElementwiseOperandsMetadata(
            A=TensorAttributes.from_tensor(args.A),
            B=TensorAttributes.from_tensor(args.B),
            out=TensorAttributes.from_tensor(args.out),
        )


class EpilogueMetadata:
    def __init__(self, epilogue_args: EpilogueArguments):
        self.traced_epilogue = epilogue_args.traced_epilogue
        self.tensors = epilogue_args.tensors
        self.epilogue_fn = epilogue_args.epilogue_fn

    @staticmethod
    def from_args(args: EpilogueArguments) -> Self:
        # For now, EpilogueArguments and EpilogueMetadata are the same
        return EpilogueMetadata(args)

    @property
    def parameters(self) -> list[cute.Tensor | cutlass.Numeric]:
        return list(self.tensors.values())

    @property
    def parameter_names(self) -> list[str]:
        return list(self.tensors.keys())

    def supports(self, args: RuntimeArguments) -> Status:
        return Status.success()


@dataclass
class KernelMetadata:
    """
    Metadata describing the operands and design of a kernel.

    In addition to information about operands, this metadata also contains
    the properties of the kernel that are independent of the specific arguments
    that are passed to the kernel (e.g., tile shape, cluster shape, etc.).
    :param kernel_name: The name of the kernel.
    :type kernel_name: str
    :param kernel_class: The class of the kernel.
    :type kernel_class: type["Kernel"]
    :param min_cc: The minimum compute capability of the kernel.
    :type min_cc: int
    :param operands: Metadata for the operands of the kernel.
    :type operands: OperandsT
    :param design: Metadata for the design of the kernel.
    :type design: DesignT | None
    :param epilogue: Metadata for the epilogue of the kernel.
    :type epilogue: EpilogueT | None
    """

    kernel_name: str
    kernel_class: type["Kernel"]
    min_cc: int
    operands: OperandsMetadata
    design: DesignMetadata | None = None
    epilogue: EpilogueMetadata | None = None

    def supports(self, args: RuntimeArguments) -> Status:
        """
        Checks whether the provided args satisfy the properties described by
        the operands, design, and epilogue metadata.

        :param args: The arguments to check support for.
        :type args: RuntimeArguments

        :return: Whether the provided args satisfy the properties described by
        the operands, design, and epilogue metadata.
        :rtype: Status
        """

        def supports_or_none(member, corresponding_arg, name: str) -> Status:
            # If metadata is absent, accept only when the corresponding argument is also absent.
            if member is None:
                if corresponding_arg is None:
                    return Status.success()
                return Status.fail(
                    f"{name} metadata is absent but argument is provided"
                )
            return member.supports(args)

        if not (status := self.operands.supports(args)):
            return status

        if not (status := supports_or_none(self.design, args.performance, "design")):
            return status

        if not (status := supports_or_none(self.epilogue, args.epilogue, "epilogue")):
            return status

        return Status.success()
