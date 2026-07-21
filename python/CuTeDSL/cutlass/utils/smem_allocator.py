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

from enum import IntEnum
from typing import Any, Callable, Optional, Type, Union, overload
from typing_extensions import deprecated
import inspect

import cutlass.cute as cute
from cutlass.cute.tensor import _Tensor
from cutlass.address_space import AddressSpace
from cutlass.cutlass_dsl import (
    SMEM_CAPACITY_MAP,
    CuTeDSL,
    Boolean,
    Int8,
    Int32,
    Numeric,
    NumericMeta,
    dsl_user_op,
)
from cutlass._mlir import ir
from cutlass._mlir.dialects import cute as _cute_ir


def _extract_struct_fields(struct_type: cute.struct) -> list[tuple[str, int, int]]:
    """Extract (name, size_bytes, offset) for each field in a cute.struct."""
    from cutlass.cute.core import struct

    fields = []
    for name, member in struct_type._annotations.items():
        offset = struct_type._offsets[name]
        # Unwrap Align wrapper
        if isinstance(member, struct._AlignMeta):
            member = member.dtype
        # Compute size based on type
        if struct._is_scalar_type(member):
            size = max(1, member.width // 8)
        elif isinstance(member, struct._MemRangeMeta):
            size = member.size_in_bytes
        elif isinstance(member, struct):
            size = member.__sizeof__()
        else:
            continue
        fields.append((name, size, offset))
    return fields


class SmemPartition(IntEnum):
    """Shared memory partition types.

    Defines the partition ownership of a shared memory region.

    Attributes:
        RESERVED: Partition reserved for system use (value: 0).
        USER: Partition available for user allocation (value: 1).
    """

    RESERVED = 0
    USER = 1


class SmemAllocator:
    """A helper class for managing shared memory allocation on GPU.

    This class manages shared memory and provides APIs for allocation of raw bytes,
    numeric types, arrays, and tensors with specified layouts and alignments.

    .. note::
        - SmemAllocator will automatically calculate the usage upon kernel launch.
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
        x_ptr = struct_ptr.x.ptr

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
        :type compute_capability: Optional[str]
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
    def __init__(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ):
        """Initialize a new SmemAllocator instance.

        :param loc: Source location information for debugging, defaults to None
        :type loc: Optional[ir.Location]
        :param ip: Insertion point for MLIR operations, defaults to None
        :type ip: Optional[ir.InsertionPoint]
        """
        pass

    @dsl_user_op
    def calculate_partition_size(
        self,
        partition: SmemPartition,
        *,
        cumulative: bool = False,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Int32:
        """Get the size of shared memory allocation at given smem partition.

        :param partition: The smem partition to query
        :type partition: SmemPartition
        :param cumulative: Whether to return the cumulative size of all partitions up to and including the given partition
        :type cumulative: bool, optional
        :param loc: Source location information for debugging, defaults to None
        :type loc: Optional[ir.Location]
        :param ip: Insertion point for MLIR operations, defaults to None
        :type ip: Optional[ir.InsertionPoint]
        """
        return Int32(
            _cute_ir.smem_partition_size(
                partition_id=partition.value,
                cumulative=cumulative,
                loc=loc,
                ip=ip,
            )
        )

    @dsl_user_op
    def calculate_total_usage(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Int32:
        """Get total kernel smem usage calculated by allocator.

        :param loc: Source location information for debugging, defaults to None
        :type loc: Optional[ir.Location]
        :param ip: Insertion point for MLIR operations, defaults to None
        :type ip: Optional[ir.InsertionPoint]
        """
        return Int32(
            _cute_ir.smem_partition_size(
                partition_id=SmemPartition.USER.value,
                cumulative=True,
                loc=loc,
                ip=ip,
            )
        )

    @property
    @deprecated(
        "Private attribute `_allocated_bytes` is deprecated, use public API `arch.dynamic_smem_size()` instead."
    )
    def _allocated_bytes(self) -> Int32:
        return cute.arch.dynamic_smem_size()

    @dsl_user_op
    def _smem_alloca(
        self,
        layout: cute.Layout,
        dtype: NumericMeta,
        byte_alignment: int,
        swizzle: Optional[cute.Swizzle] = None,
        struct_fields: Optional[list[tuple[str, int, int]]] = None,
        *,
        partition: SmemPartition = SmemPartition.USER,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> cute.Pointer:
        """
        Allocate shared memory using cute.memref.alloca with given layout, data type, and alignment.

        Returns:
            cute.Pointer: An iterator (pointer) to the allocated shared memory.
        """
        # use init_byte_alignment for first allocation
        byte_alignment = max(byte_alignment, dtype.width // 8)
        assert byte_alignment <= 1024, "max shared memory alignment limit to 1024 bytes"
        assert cute.is_static(layout), "shared memory allocation must be static layout"
        # allocate using cute.memref.alloca
        swizzle = swizzle.type.attribute if swizzle is not None else None
        mlir_type = Int8.mlir_type if dtype is Boolean else dtype.mlir_type
        ptr_ty = _cute_ir.PtrType.get(
            mlir_type, AddressSpace.smem, byte_alignment, swizzle
        )
        res_ty = _cute_ir.MemRefType.get(ptr_ty, layout.type)
        memref = _cute_ir.memref_alloca(res_ty, layout=None, loc=loc, ip=ip)
        # Attach attributes to allocate to smem partition
        if partition is not None:
            memref.value.owner.attributes["smem.partition_id"] = ir.IntegerAttr.get(
                ir.IntegerType.get_signless(32), partition.value
            )
        # Attach struct field metadata as MLIR attributes
        if struct_fields:
            field_attrs = []
            for name, size, offset in struct_fields:
                field_attrs.append(ir.StringAttr.get(f"{name}:{size}:{offset}"))
            memref.value.owner.attributes["smem.struct_fields"] = ir.ArrayAttr.get(
                field_attrs
            )
        return _cute_ir.get_iter(memref.value, loc=loc, ip=ip)

    @overload
    def allocate(
        self,
        size_or_type: int,
        byte_alignment: int = 1,
        *,
        partition: SmemPartition = SmemPartition.USER,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> cute.Pointer: ...

    @overload
    def allocate(
        self,
        size_or_type: Type[Numeric],
        byte_alignment: int = 1,
        *,
        partition: SmemPartition = SmemPartition.USER,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> cute.Pointer: ...

    @overload
    def allocate(  # type: ignore[overload-cannot-match]
        self,
        size_or_type: cute.struct,
        byte_alignment: int = 1,
        *,
        partition: SmemPartition = SmemPartition.USER,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> cute.Pointer: ...

    @dsl_user_op
    def allocate(
        self,
        size_or_type: Any,
        byte_alignment: int = 1,
        *,
        partition: SmemPartition = SmemPartition.USER,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
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
            struct_fields = _extract_struct_fields(size_or_type)
            layout = cute.make_layout(size_in_bytes)
            base_ptr = self._smem_alloca(
                layout,
                Int8,
                alignment,
                struct_fields=struct_fields,
                partition=partition,
                loc=loc,
                ip=ip,
            )
            return size_or_type(base_ptr)
        elif isinstance(
            size_or_type,
            (
                NumericMeta,
            ),
        ):
            element_width = size_or_type.width if size_or_type is not Boolean else 8
            size_in_bytes = cute.ceil_div(element_width, 8)
            base_ptr = self.allocate(
                size_in_bytes, byte_alignment, partition=partition, loc=loc, ip=ip
            )
            return cute.recast_ptr(base_ptr, dtype=size_or_type, loc=loc, ip=ip)
        else:
            raise TypeError(
                f"Expected int, struct, or numeric type, but got {type(size_or_type)}"
            )

        if cute.is_static(size_in_bytes) and size_in_bytes < 0:
            raise ValueError("size must be non-negative")

        if byte_alignment < 1:
            raise ValueError("`byte_alignment` must be at least 1")

        layout = cute.make_layout(size_in_bytes)
        return self._smem_alloca(
            layout, Int8, byte_alignment, partition=partition, loc=loc, ip=ip
        )

    @dsl_user_op
    def allocate_array(
        self,
        element_type: Union[
            Type[Numeric],
        ],
        num_elems: int = 1,
        *,
        byte_alignment: int = 1,
        partition: SmemPartition = SmemPartition.USER,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> cute.Pointer:
        """Allocate an array of elements in shared memory.

        :param element_type: The type of elements to allocate
        :type element_type: Union[Type[Numeric]]
        :param num_elems: Number of elements to allocate, defaults to 1
        :type num_elems: int, optional
        :return: Pointer to the start of the allocated array
        :rtype: cute.Pointer
        :raises ValueError: If num_elems is less than 1
        :raises TypeError: If element_type is not a Numeric type
        """
        if cute.is_static(num_elems) and num_elems < 1:
            raise ValueError("num_elems must be at least 1")
        if not isinstance(
            element_type,
            (
                NumericMeta,
            ),
        ):
            raise TypeError(
                f"value_ty must be a type of Numeric, but got {element_type}"
            )

        element_width = element_type.width if element_type is not Boolean else 8
        byte_alignment = max(byte_alignment, element_width // 8)
        ptr = self.allocate(
            element_width * num_elems // 8,
            byte_alignment,
            partition=partition,
            loc=loc,
            ip=ip,
        )

        return cute.recast_ptr(ptr, dtype=element_type, loc=loc, ip=ip)

    @dsl_user_op
    def allocate_tensor(
        self,
        element_type: Union[Type[Numeric],],
        layout: Union[int, cute.Layout, cute.ComposedLayout],
        byte_alignment: int = 1,
        swizzle: Optional[cute.Swizzle] = None,
        *,
        partition: SmemPartition = SmemPartition.USER,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> cute.Tensor:
        """Allocate a tensor in shared memory.

        Note: Currently only supports static layouts. Dynamic layouts are not supported.

        :param element_type: The type of elements in the tensor
        :type element_type: Union[Type[Numeric]]
        :param layout: The layout specification for the tensor. Must be a static layout.
        :type layout: Union[int, cute.Layout, cute.ComposedLayout]
        :param byte_alignment: The byte alignment requirement, defaults to 1
        :type byte_alignment: int, optional
        :param swizzle: Swizzle for position-dependent swizzling, defaults to None
        :type swizzle: cute.Swizzle, optional
        :return: The allocated tensor with specified properties
        :rtype: cute.Tensor
        :raises TypeError: If element_type is not a Numeric type, or if swizzle conflicts with layout
        :raises ValueError: If allocation is not byte-aligned
        :raises NotImplementedError: If dynamic layout is specified
        """
        if not isinstance(
            element_type,
            (
                NumericMeta,
            ),
        ):
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

        assert not isinstance(layout, int)
        profile = layout(0, loc=loc, ip=ip)
        if isinstance(profile, tuple):
            raise TypeError(
                "cannot allocate a shared memory tensor with a non-integer iterator"
            )

        if not cute.is_static(layout):
            raise NotImplementedError(f"dynamic layout is not supported: {layout}")

        # At least align the allocation to the natural alignment given by the element type
        element_width = element_type.width if element_type is not Boolean else 8
        if element_width // 8 > byte_alignment:
            byte_alignment = element_width // 8

        # Relevant only for sub-byte data types: verify that the entire allocation is byte-aligned
        cosize_in_bits = cute.cosize(layout, loc=loc, ip=ip) * element_width
        assert isinstance(cosize_in_bits, int)
        if cosize_in_bits % 8 != 0:
            raise ValueError("invalid allocation that is not byte-aligned")

        num_bytes = cosize_in_bits // 8
        ptr = self.allocate(
            num_bytes, byte_alignment, partition=partition, loc=loc, ip=ip
        )
        ptr = cute.recast_ptr(ptr, swizzle, dtype=element_type, loc=loc, ip=ip)
        tensor = cute.make_tensor(ptr, layout, loc=loc, ip=ip)
        return _Tensor(tensor, dtype=element_type, loc=loc, ip=ip)


# Set explicit signature for Sphinx documentation to avoid issues with @dsl_user_op decorator
SmemAllocator.__init__.__signature__ = inspect.Signature(  # type: ignore[attr-defined]
    [
        inspect.Parameter("self", inspect.Parameter.POSITIONAL_OR_KEYWORD),
    ]
)

get_smem_capacity_in_bytes = SmemAllocator.capacity_in_bytes


@dsl_user_op
def get_kernel_smem_size(
    kernel: Callable,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> int:
    """Get the total static shared memory allocation in bytes for a kernel.

    Uses ``cute.kernel_smem_size`` to query the total smem bytes that will be
    allocated by a kernel.  The result is lowered to a compile-time constant by
    ``InferKernelSmemUsagePass``.

    Must be called from within a ``@cute.jit`` body after the kernel's
    ``.launch()`` has been called, which triggers tracing and registers the
    kernel's MLIR symbol.

    :param kernel: A ``@cute.kernel``-decorated function.  The MLIR symbol is
        retrieved automatically from state stored by the DSL after ``.launch()``.
    :type kernel: Callable
    :return: Total shared memory allocated by the kernel, in bytes.
    :rtype: int (i64 MLIR value during tracing)
    """
    if not callable(kernel):
        raise TypeError(
            f"get_kernel_smem_size: expected a @cute.kernel-decorated function, "
            f"got {type(kernel)}"
        )

    # The DSL stores the MLIR SymbolRefAttr on the underlying funcBody
    # (accessible via __wrapped__) after each .launch() call.
    func_body = getattr(kernel, "__wrapped__", kernel)
    sym = getattr(func_body, "_dsl_kernel_sym", None)
    if sym is None:
        raise ValueError(
            f"get_kernel_smem_size: kernel '{kernel.__name__}' has not been "
            "traced yet — call .launch() before get_kernel_smem_size()."
        )
    return _cute_ir.kernel_smem_size(kernel_name=sym, loc=loc, ip=ip)
