# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from typing import Optional, Type, Union, overload
import inspect

import cutlass.cute as cute
from cutlass.cute.arch import get_dyn_smem, get_dyn_smem_size
from cutlass.cutlass_dsl import CuTeDSL, Int8, Numeric, NumericMeta, dsl_user_op


SMEM_CAPACITY_MAP = {
    "sm_120": (100 - 1) * 1024,
    "sm_103": (228 - 1) * 1024,
    "sm_100": (228 - 1) * 1024,
    "sm_90": (228 - 1) * 1024,
    "sm_80": (164 - 1) * 1024,
    "sm_86": (100 - 1) * 1024,
    "sm_89": (100 - 1) * 1024,
}


class SmemAllocator:
    """A helper class for managing shared memory allocation on GPU.

    This class manages shared memory and provides APIs for allocation of raw bytes,
    numeric types, arrays, and tensors with specified layouts and alignments.

    .. note::
        - The base pointer is aligned to 1024 bytes upon initialization.
        - There is no need to explicitly specify shared memory size in kernel launch.
        - Currently only supports static layouts. Dynamic layouts are not supported.

    **Examples**:

    .. code-block:: python

        smem = SmemAllocator()

        # Allocate raw bytes
        buf_ptr = smem.allocate(100)  # 100 bytes

        # Allocate numeric type
        int8_ptr = smem.allocate(Int8)  # 1 byte

        # Define a struct
        @cute.struct
        class SharedStorage:
            alpha: cutlass.Float32
            x: cutlass.Int32

        # Allocate struct
        struct_ptr = smem.allocate(SharedStorage)  # 8 bytes

        # use of struct members
        struct_ptr.alpha = 1.0
        struct_ptr.x = 2

        # Allocate array
        int8_array = smem.allocate_array(Int8, 10)  # 10 bytes

        # Allocate tensor
        layout = cute.make_layout((16, 16))
        tensor = smem.allocate_tensor(Int8, layout)  # 256 bytes
    """

    @staticmethod
    def capacity_in_bytes(compute_capability: Optional[str] = None) -> int:
        """Get the shared memory capacity in bytes for a given compute capability.

        Returns the maximum shared memory capacity in bytes available for the specified
        GPU compute capability.

        :param compute_capability: The compute capability string (e.g. "70", "75", "80")
        :type compute_capability: str
        :return: The shared memory capacity in bytes
        :rtype: int
        :raises ValueError: If the compute capability is not supported
        """
        if compute_capability is None:
            arch = CuTeDSL._get_dsl().get_arch_enum()
            compute_capability = f"sm_{arch.major}{arch.minor}"
        if compute_capability not in SMEM_CAPACITY_MAP:
            raise ValueError(f"Unsupported compute capability: {compute_capability}")
        return SMEM_CAPACITY_MAP[compute_capability]

    @dsl_user_op
    def __init__(self, *, loc=None, ip=None):
        """Initialize a new SmemAllocator instance.

        Creates a new shared memory allocator with a base pointer aligned to 1024 bytes.
        Tracks the allocator instance for memory management.

        :param loc: Source location information for debugging, defaults to None
        :type loc: Optional[ir.Location]
        :param ip: Insertion point for MLIR operations, defaults to None
        :type ip: Optional[ir.InsertionPoint]
        """
        self._base = get_dyn_smem(Int8, alignment=1024, loc=loc, ip=ip)
        self._allocated_bytes = 0
        CuTeDSL.track_smem_allocator(self, lambda cls: cls._allocated_bytes)

    @overload
    def allocate(
        self, size_or_type: int, byte_alignment: int, *, loc=None, ip=None
    ) -> cute.Pointer: ...

    @overload
    def allocate(
        self, size_or_type: Type[Numeric], byte_alignment: int, *, loc=None, ip=None
    ) -> cute.Pointer: ...

    @overload
    def allocate(
        self, size_or_type: cute.struct, byte_alignment: int, *, loc=None, ip=None
    ) -> cute.Pointer: ...

    @dsl_user_op
    def allocate(
        self, size_or_type, byte_alignment: int = 1, *, loc=None, ip=None
    ) -> cute.Pointer:
        """Allocate a block of memory with specified size and alignment.

        This method allocates a block of shared memory with the specified size and alignment requirements.
        It supports allocating raw bytes, numeric types(as scalar value), and struct types.

        :param size_or_type: The allocation specification, which can be:
            - An integer specifying the number of bytes to allocate
            - A Numeric type (e.g., Int8, Float32) to allocate space for one element
            - A struct type to allocate space for the entire struct
        :type size_or_type: Union[int, Type[Numeric], cute.struct]
        :param byte_alignment: The minimum byte alignment requirement for the allocation, defaults to 1
        :type byte_alignment: int, optional
        :param loc: Source location information for debugging, defaults to None
        :type loc: Optional[ir.Location]
        :param ip: Insertion point for MLIR operations, defaults to None
        :type ip: Optional[ir.InsertionPoint]
        :return: For raw bytes and numeric types, returns a pointer to the allocated memory.
                For struct types, returns an initialized struct instance at the allocated location.
        :rtype: cute.Pointer
        :raises ValueError: If size is negative or alignment is less than 1
        :raises TypeError: If size_or_type is not an integer, Numeric type, or struct
        :raises RuntimeError: If allocation would exceed available shared memory
        """

        if cute.is_integer(size_or_type):
            size_in_bytes = size_or_type
        elif isinstance(size_or_type, cute.struct):
            size_in_bytes = size_or_type.__sizeof__()
            alignment = max(byte_alignment, size_or_type.__alignof__())
            base_ptr = self.allocate(size_in_bytes, alignment, loc=loc, ip=ip)
            return size_or_type(base_ptr)
        elif isinstance(size_or_type, NumericMeta):
            size_in_bytes = cute.ceil_div(size_or_type.width, 8)
            base_ptr = self.allocate(size_in_bytes, byte_alignment, loc=loc, ip=ip)
            return cute.recast_ptr(base_ptr, dtype=size_or_type, loc=loc, ip=ip)
        else:
            raise TypeError(
                f"Expected int, struct, or numeric type, but got {type(size_or_type)}"
            )

        if cute.is_static(size_in_bytes) and size_in_bytes < 0:
            raise ValueError("size must be non-negative")

        if byte_alignment < 1:
            raise ValueError("`byte_alignment` must be at least 1")

        self._base = self._base.align(byte_alignment)
        ptr = self._base
        self._base += size_in_bytes
        if self._allocated_bytes % byte_alignment != 0:
            self._allocated_bytes += (
                byte_alignment - self._allocated_bytes % byte_alignment
            )
        self._allocated_bytes += size_in_bytes

        # Check bounds against available dynamic shared memory
        cute.testing.assert_(
            self._allocated_bytes <= get_dyn_smem_size(loc=loc, ip=ip),
            f"Allocation failed: shared memory allocation exceeds available memory set in kernel launch. "
            f"Allocated bytes: {self._allocated_bytes} bytes. "
            f"Please reduce the allocation or set a larger smem size in kernel launch.",
            loc=loc,
            ip=ip,
        )
        return ptr

    @dsl_user_op
    def allocate_array(
        self, element_type: Type[Numeric], num_elems: int = 1, *, loc=None, ip=None
    ):
        """Allocate an array of elements in shared memory.

        :param element_type: The type of elements to allocate
        :type element_type: Type[Numeric]
        :param num_elems: Number of elements to allocate, defaults to 1
        :type num_elems: int, optional
        :return: Pointer to the start of the allocated array
        :rtype: cute.Pointer
        :raises ValueError: If num_elems is less than 1
        :raises TypeError: If element_type is not a Numeric type
        """
        if num_elems < 1:
            raise ValueError("num_elems must be at least 1")
        if not isinstance(element_type, NumericMeta):
            raise TypeError(
                f"value_ty must be a type of Numeric, but got {element_type}"
            )

        ptr = self.allocate(
            element_type.width // 8 * num_elems, element_type.width // 8, loc=loc, ip=ip
        )

        return cute.recast_ptr(ptr, dtype=element_type, loc=loc, ip=ip)

    @dsl_user_op
    def allocate_tensor(
        self,
        element_type: Type[Numeric],
        layout: Union[int, cute.Layout, cute.ComposedLayout],
        byte_alignment: int = 1,
        swizzle: Optional[cute.Swizzle] = None,
        *,
        loc=None,
        ip=None,
    ):
        """Allocate a tensor in shared memory.

        Note: Currently only supports static layouts. Dynamic layouts are not supported.

        :param element_type: The type of elements in the tensor
        :type element_type: Type[Numeric]
        :param layout: The layout specification for the tensor. Must be a static layout.
        :type layout: Union[int, cute.Layout, cute.ComposedLayout]
        :param byte_alignment: The byte alignment requirement, defaults to 1
        :type byte_alignment: int, optional
        :param swizzle: Swizzle for position-dependent swizzling, defaults to None
        :type swizzle: cute.Swizzle, optional
        :return: The allocated tensor with specified properties
        :rtype: cute.Tensor
        :raises TypeError: If element_type is not a Numeric type or if swizzle conflicts with layout
        :raises ValueError: If allocation is not byte-aligned
        :raises NotImplementedError: If dynamic layout is specified
        """
        if not isinstance(element_type, NumericMeta):
            raise TypeError(
                f"value_ty must be a type of Numeric, but got {element_type}"
            )

        if (
            isinstance(layout, cute.ComposedLayout)
            and isinstance(layout.inner, cute.Swizzle)
        ) and (swizzle is not None):
            raise TypeError(
                "Invalid tensor type: cannot be both iterator swizzle (PDSL) and swizzle layout(PISL) at the same time."
            )

        if isinstance(layout, int):
            layout = cute.make_layout(layout)

        profile = layout(0, loc=loc, ip=ip)
        if isinstance(profile, tuple):
            raise TypeError(
                "cannot allocate a shared memory tensor with a non-integer iterator"
            )

        if not cute.is_static(layout):
            raise NotImplementedError(f"dynamic layout is not supported: {layout}")

        # At least align the allocation to the natural alignment given by the element type
        if element_type.width // 8 > byte_alignment:
            byte_alignment = element_type.width // 8

        # Relevant only for sub-byte data types: verify that the entire allocation is byte-aligned
        cosize_in_bits = cute.cosize(layout, loc=loc, ip=ip) * element_type.width
        assert isinstance(cosize_in_bits, int)
        if cosize_in_bits % 8 != 0:
            raise ValueError("invalid allocation that is not byte-aligned")

        num_bytes = cosize_in_bits // 8
        ptr = self.allocate(num_bytes, byte_alignment, loc=loc, ip=ip)
        ptr = cute.recast_ptr(ptr, swizzle, dtype=element_type, loc=loc, ip=ip)
        return cute.make_tensor(ptr, layout, loc=loc, ip=ip)


# Set explicit signature for Sphinx documentation to avoid issues with @dsl_user_op decorator
SmemAllocator.__init__.__signature__ = inspect.Signature(
    [
        inspect.Parameter("self", inspect.Parameter.POSITIONAL_OR_KEYWORD),
    ]
)

get_smem_capacity_in_bytes = SmemAllocator.capacity_in_bytes
