# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from typing import Type, Union, overload

from cutlass.cutlass_dsl import Int8, Numeric, NumericMeta

import cutlass.cute as cute
from cutlass.cute.arch import get_dyn_smem


class SmemAllocator:
    """
    A class for managing shared memory allocation on GPU.

    This class manages a chunk of shared memory and provide APIs for sub-allocation
    inside the chunk.

    Attributes
    ----------
    _base : cute.Pointer as i8 typed dynamic value
        The current base address of the shared memory.

    _allocated_bytes:
        The bytes allocated in shared memory.

    Methods
    -------
    allocate(num_bytes, alignment)
        Allocates num_bytes in the shared memory with the given byte alignment.

    allocate_value(value_ty, num_elems)
        Allocates num_elems of value_ty values in the shared memory.

    allocate_tensor(value_ty, layout, alignment)
        Allocates a tensor in the shared memory with given layout and byte alignment.

    Notes
    -----
    This class is responsible for managing the allocation of tensors in shared memory.
    """

    def __init__(self):
        """
        Initializes the SmemAllocator instance with dynamic smem base ptr,
        which is i8 type and aligned to 1024.

        """
        self._base = get_dyn_smem(Int8, alignment=1024)
        self._allocated_bytes = 0

    @overload
    def allocate(self, size_or_type: int, byte_alignment: int): ...

    @overload
    def allocate(self, size_or_type: cute.struct, byte_alignment: int): ...

    def allocate(self, size_or_type, byte_alignment: int = 1) -> int:
        """
        Allocates a block of memory with the specified size and byte alignment.

        This method adjusts the base cute.Pointer to ensure that the allocated memory
        is aligned according to the specified byte alignment. It updates the internal
        state to reflect the new base cute.Pointer and the total allocated bytes.

        Parameters
        ----------
        size_or_type : int or struct
            The number of bytes to allocate or struct class.
        byte_alignment : int
            The byte alignment requirement for the allocation. Defaults to 1 (no alignment).

        Returns
        ----------
        A cute.Pointer to the start of the allocated memory block or struct instance.

        Raises
        ----------
        ValueError
            If num_bytes is negative or if byte_alignmemt is less than 1.
        """

        if isinstance(size_or_type, cute.struct):
            alignment = max(byte_alignment, size_or_type.__alignof__())
            base_ptr = self.allocate(size_or_type.__sizeof__(), alignment)
            return size_or_type(base_ptr)

        num_bytes = size_or_type
        if num_bytes < 0:
            raise ValueError("num_bytes must be non-negative")
        if byte_alignment < 1:
            raise ValueError("byte_alignment must be at least 1")

        self._base = self._base.align(byte_alignment)
        ptr = self._base
        self._base += num_bytes
        if self._allocated_bytes % byte_alignment != 0:
            self._allocated_bytes += (
                byte_alignment - self._allocated_bytes % byte_alignment
            )
        self._allocated_bytes += num_bytes
        return ptr

    def allocate_array(self, element_type: Type[Numeric], num_elems: int = 1):
        """
        Allocates num_elems values of element_type in shared memory.

        This method calls allocate() to return a byte ptr, pointing to start of shared
        memory. Then calls cute.recast_ptr() to recast this byte cute.Pointer to element_type.

        Parameters
        ----------
        element_type : Type[Numeric]
            The type of the values in the tensor.
        num_elems : int, optional
            The number of elements for each allocation. Defaults to 1.

        Returns
        ----------
        A value_type cute.Pointer to the start of the allocated memory block.

        Raises
        ----------
        ValueError
            If num_elems is less than 1.
        """
        if num_elems < 1:
            raise ValueError("num_elems must be at least 1")
        if not isinstance(element_type, NumericMeta):
            raise TypeError(
                f"value_ty must be a type of Numeric, but got {element_type}"
            )

        ptr = self.allocate(
            element_type.width // 8 * num_elems, element_type.width // 8
        )

        return cute.recast_ptr(ptr, dtype=element_type)

    def allocate_tensor(
        self,
        element_type: Type[Numeric],
        layout: Union[int, cute.Layout, cute.ComposedLayout],
        byte_alignment: int = 1,
        swizzle: cute.Swizzle = None,
    ):
        """
        Allocates a tensor in the shared memory with value type, layout and byte alignment.

        Parameters
        ----------
        element_type : Type[Numeric]
            The type of the values in the tensor.
        layout : int | DynamicInt | cute.Layout | cute.ComposedLayout
            The layout of the tensor.
        byte_alignment : int, optional
            The byte alignment requirement for the allocation. Defaults to 1 (no alignment).
        swizzle : cute.Swizzle
            A swizzle for the iterator (for position-dependent swizzling).

        Returns
        -------
        tensor : cute.Tensor
            The allocated tensor with specified value type, layout and byte alignment.

        Notes
        -----
        The base address is updated to point to the next available memory location.
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
                f"Invalid tensor type: cannot be both iterator swizzle (PDSL) and swizzle layout(PISL) at the same time."
            )

        if isinstance(layout, int):
            layout = cute.make_layout(layout)

        profile = layout(0)
        if isinstance(profile, tuple):
            raise TypeError(
                f"cannot allocate a shared memory tensor with a non-integer iterator"
            )

        if not cute.is_static(layout.type):
            raise NotImplementedError(f"dynamic layout is not supported: {layout.type}")

        # At least align the allocation to the natural alignment given by the element type
        if element_type.width // 8 > byte_alignment:
            byte_alignment = element_type.width // 8

        # Relevant only for sub-byte data types: verify that the entire allocation is byte-aligned
        cosize_in_bits = cute.cosize(layout) * element_type.width
        assert isinstance(cosize_in_bits, int)
        if cosize_in_bits % 8 != 0:
            raise ValueError("invalid allocation that is not byte-aligned")

        num_bytes = cosize_in_bits // 8
        ptr = self.allocate(num_bytes, byte_alignment)
        ptr = cute.recast_ptr(ptr, swizzle, dtype=element_type)
        res = cute.make_tensor(ptr, layout)
        return res
