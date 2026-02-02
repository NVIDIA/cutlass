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

from typing import Type, Optional, Sequence, Union, Callable, Any, TypeVar
import sys
import ctypes
import math
import inspect
from dataclasses import dataclass, field
from functools import partial, reduce
from operator import mul
from itertools import chain
from typing import Annotated

import cuda.bindings.driver as cuda

import jax
import jax.numpy as jnp

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack as _from_dlpack
from cutlass.cute import AddressSpace, Numeric, IntTuple
from cutlass._mlir import ir
from cutlass._mlir.dialects import llvm, arith
import cutlass._mlir.dialects.cute as _cute_ir

JAX_DTYPE_TO_CUTLASS_DTYPE = {
    jnp.bool.dtype: cutlass.Boolean,
    jnp.int8.dtype: cutlass.Int8,
    jnp.int16.dtype: cutlass.Int16,
    jnp.int32.dtype: cutlass.Int32,
    jnp.int64.dtype: cutlass.Int64,
    jnp.uint8.dtype: cutlass.Uint8,
    jnp.uint16.dtype: cutlass.Uint16,
    jnp.uint32.dtype: cutlass.Uint32,
    jnp.uint64.dtype: cutlass.Uint64,
    jnp.bfloat16.dtype: cutlass.BFloat16,
    jnp.float16.dtype: cutlass.Float16,
    jnp.float32.dtype: cutlass.Float32,
    jnp.float64.dtype: cutlass.Float64,
    jnp.float8_e8m0fnu.dtype: cutlass.Float8E8M0FNU,
    jnp.float8_e5m2.dtype: cutlass.Float8E5M2,
    jnp.float8_e4m3.dtype: cutlass.Float8E4M3,
    jnp.float8_e4m3fn.dtype: cutlass.Float8E4M3FN,
    jnp.float8_e4m3b11fnuz.dtype: cutlass.Float8E4M3B11FNUZ,
    jnp.float4_e2m1fn.dtype: cutlass.Float4E2M1FN,
}
CUTLASS_DTYPE_TO_JAX_DTYPE = {
    value: key for key, value in JAX_DTYPE_TO_CUTLASS_DTYPE.items()
}

DEFAULT_CUTLASS_DEVICE_MEMSPACE = AddressSpace.gmem
DEFAULT_CUTLASS_DEVICE_BUFFER_ALIGNMENT = 256


@jax.tree_util.register_dataclass
@dataclass(frozen=True)
class TensorSpec:
    """Provides a specification of cute.Tensor modes and additional metadata about
    dynamic/static shapes for compilation.

    Arguments:
        layout : Specifies the position of stries as they relate to the framework
                 tensor (S0, S1, ... SN)
        mode : Specifies the position of each mode in the tensor (M0, M1, ... MN)
        static : Specifies the tensor shape is represented as static constexpr.
        ptr_assumed_align: Specifies the pointer alignment.
    """

    # Specifies the layout of the Jax array. If not it will be assumed that the layout
    # is row major.
    layout: tuple[int, ...] | None = field(metadata=dict(static=True), default=None)
    # Indicates the order of modes. If unspecified the modes will match exactly with
    # the layout of the Jax tensor (e.g. row-major). Typically used to map from the
    # input layout to kernel layouts (e.g. MKL/NKL/MNL).
    mode: tuple[int, ...] | None = field(metadata=dict(static=True), default=None)
    # Indicates the shape and strides will be defined statically. Setting True ay enable
    # additional optimization. Kernels that do not support static shapes will generate
    # compile errors if this is enabled so we leave it off by default.
    static: bool = field(metadata=dict(static=True), default=None)
    # Overrides the default pointer alignment. Generally this should not be changed
    # but is left here to provide a hook.
    ptr_assumed_align: int = field(
        metadata=dict(static=True), default=DEFAULT_CUTLASS_DEVICE_BUFFER_ALIGNMENT
    )

def row_major_layout(shaped):
    """Returns a row major layout given a shaped value.

    Row major layout is (N-1, N-2, ... 1, 0) for an N-dimensional tensor.
    """
    if hasattr(shaped, "shape"):
        shaped = shaped.shape
    return tuple(reversed(range(len(shaped))))


def default_tensor_mode(shaped):
    """Returns a default tensor mode given a shaped value.

    Default mode is (0, 1, ... N-2, N-1) for an N_dimensional tensor.
    """
    if hasattr(shaped, "shape"):
        shaped = shaped.shape
    return tuple(range(len(shaped)))


def default_tensor_spec(shaped) -> TensorSpec:
    """Returns a default tensor spec given a shaped value.

    Default layout is (N-1, N-2, ... 1, 0) for an N-dimensional tensor.
    Default mode is (0, 1, ... N-2, N-1) for an N_dimensional tensor.
    """
    if hasattr(shaped, "shape"):
        shaped = shaped.shape
    return TensorSpec(layout=row_major_layout(shaped), mode=default_tensor_mode(shaped))


def jax_to_cutlass_dtype(dtype):
    """Gets the corresponding cutlass dtype given a jax dtype."""
    dtype = jnp.dtype(dtype)
    if dtype not in JAX_DTYPE_TO_CUTLASS_DTYPE:
        raise ValueError(f"Jax dtype [{dtype}] has no equivalent cutlass dtype.")
    return JAX_DTYPE_TO_CUTLASS_DTYPE[dtype]


def cutlass_to_jax_dtype(dtype):
    """Gets the corresponding cutlass dtype given a jax dtype."""
    if dtype not in CUTLASS_DTYPE_TO_JAX_DTYPE:
        raise ValueError(f"Cutlass dtype [{dtype}] has no equivalent jax dtype.")
    return CUTLASS_DTYPE_TO_JAX_DTYPE[dtype]


def from_dlpack(array, assumed_align: int = DEFAULT_CUTLASS_DEVICE_BUFFER_ALIGNMENT):
    """Convert jax.Array to a DL pack tensor."""
    return _from_dlpack(array, assumed_align=assumed_align)


class JaxArray:
    """Base class for JaxArray argument type.

    JaxArray provides glue between XLA/JAX FFI tensors and cute.Tensor.

    The following fields/properties provide control over the conversion
    to cute.Tensor as part of jax.jit lowering. These properties are
    constexpr and compiled into the kernel.

    1. dtype: The tensor data type defined by the jax array.
    2. shape: The tensor shape defined at jit tracing time. This shape
              can be concrete or symbolic in the case of jax.export.
    3. mem_space: The memory space of the tensor. Defaults to gmem.
    4. assumed_align: The alignment of the tensor. Defaults to XLA alignment.
    5. order: Specifies the order of the shape to determine strides.
    6. mode: Specifies how to map ordered elements to the modes od a cute.Layout.
    7. static: If True, tensor shapes and strides are compiled statically.
    """

    def __init__(
        self,
        dtype,
        shape,
        mem_space,
        assumed_align,
        order=None,
        mode=None,
        static=False,
    ):
        self.dtype = dtype
        self.shape = tuple(shape)
        self.ndim = len(self.shape)
        self.mem_space = mem_space
        self.assumed_align = assumed_align
        if order is None:
            order = row_major_layout(shape)
        if mode is None:
            mode = default_tensor_mode(shape)

        if len(order) != len(shape):
            raise ValueError(f"layout must be same length as shape", order, shape)
        for s in order:
            if s < 0 or s >= len(shape):
                raise ValueError(f"Invalid index {s} in stride order", order, shape)
        if len(tuple(set(order))) != len(order):
            raise ValueError(f"layout has duplicate indices", order)

        if len(mode) != len(shape):
            raise ValueError(f"mode must be same length as shape", mode, shape)
        for s in mode:
            if s < 0 or s >= len(shape):
                raise ValueError(f"Invalid index {s} in stride order", mode, shape)
        if len(tuple(set(mode))) != len(mode):
            raise ValueError(f"mode has duplicate indices", mode)

        self.order = tuple(order)
        self.mode = tuple(mode)

        if any([jax.export.is_symbolic_dim(s) for s in self.shape]) and static:
            raise ValueError(
                f"{self.shape} contains one or more symbolic dimensions requires static=False"
            )
        self.static = static


class JaxArrayValue(JaxArray):
    """The IR representation of the JaxArray."""

    def __init__(
        self,
        ir_value,
        dtype,
        shape,
        mem_space,
        assumed_align,
        order,
        mode,
        static,
    ):
        super().__init__(dtype, shape, mem_space, assumed_align, order, mode, static)
        self.value = ir_value

    def __str__(self):
        return f"JaxArrayValue<{self.value}:{self.dtype}:{self.shape}:{self.order}:{self.mode}:{self.static}>"

    def __repr__(self):
        return str(self)

    def _make_ordered_layout_dynamic_strides(
        self, shape, order: tuple[int, ...], *, loc=None, ip=None
    ):
        i32 = ir.IntegerType.get_signless(32)
        i64 = ir.IntegerType.get_signless(64)
        one = arith.constant(i64, 1)
        zero = arith.constant(i64, 0)
        pairs = sorted(zip(shape, order), key=lambda x: x[1])

        # Compute strides for each element in order.
        strides = [1]  # static 1 for leading
        if len(shape) > 1:
            strides.append(pairs[0][0])
        for i, idx in enumerate(range(len(pairs[:-2]))):
            strides.append(arith.muli(pairs[i][0], strides[-1]))

        # Apply the order to strides
        strides_ordered = []
        for i in range(len(shape)):
            strides_ordered.append(strides[order[i]])

        # zero out any stride for a shape of size 1 to align with make_ordered_layout
        # We ignore the leading dimension of 1
        final_stride = []
        for i in range(len(shape)):
            x = arith.cmpi(0, one, shape[i])
            s = strides_ordered[i]
            if isinstance(s, int) and s == 1:
                final_stride.append(s)
            else:
                final_stride.append(arith.select(x, zero, s))

        # Shapes are expected to be int32 so truncate to that before creating layout
        shape = tuple([arith.trunci(i32, s) for s in shape])

        return cute.make_layout(shape, stride=tuple(final_stride))

    def _load_dynamic_shapes(self, ffi_buffer, *, loc=None, ip=None):
        i64 = ir.IntegerType.get_signless(64)
        shape_array = llvm.extractvalue(
            llvm.PointerType.get(),
            ffi_buffer,
            [1],
            loc=loc,
            ip=ip,
        )

        shape_i64 = []
        for i in range(len(self.shape)):
            r = llvm.getelementptr(
                llvm.PointerType.get(),
                shape_array,
                [],
                no_wrap_flags=0,
                raw_constant_indices=ir.DenseI32ArrayAttr.get([i]),
                elem_type=i64,
                loc=loc,
                ip=ip,
            )
            shape_i64.append(llvm.load(i64, r, loc=loc, ip=ip))

        return tuple(shape_i64)

    def _load_pointer(self, ffi_buffer, *, loc=None, ip=None):
        raw_ptr = llvm.extractvalue(
            llvm.PointerType.get(),
            ffi_buffer,
            [0],
            loc=loc,
            ip=ip,
        )
        return cute.make_ptr(
            self.dtype,
            raw_ptr,
            self.mem_space,
            assumed_align=self.assumed_align,
            loc=loc,
            ip=ip,
        )

    def get_tensor(self, *, loc=None, ip=None):
        ffi_buffer_type = llvm.StructType.get_literal(
            [llvm.PointerType.get(), llvm.PointerType.get()]
        )

        ffi_buffer = llvm.load(ffi_buffer_type, self.value, loc=loc, ip=ip)
        pointer = self._load_pointer(ffi_buffer)

        if self.static:
            shape = tuple(self.shape)
            layout = cute.make_ordered_layout(shape, order=self.order, loc=loc, ip=ip)
        else:
            shape = self._load_dynamic_shapes(ffi_buffer)
            layout = self._make_ordered_layout_dynamic_strides(shape, self.order)

        # Apply mode order
        if self.mode is not None:
            layout = cute.select(layout, self.mode, loc=loc, ip=ip)

        return cute.make_tensor(pointer, layout, loc=loc, ip=ip)

    def __extract_mlir_values__(self):
        return [self.value]

    def __new_from_mlir_values__(self, values):
        return JaxArrayValue(
            values[0],
            self.dtype,
            self.shape,
            self.mem_space,
            self.assumed_align,
            self.order,
            self.mode,
            self.static,
        )


class JaxTracedArray(JaxArray):
    """Represents a traced array value that is used for cute.compile.

    Traced values are not real tensors or allocated on the device.
    """

    def __init__(
        self,
        dtype,
        shape,
        mem_space,
        assumed_align,
        order,
        mode,
        static,
    ):
        super().__init__(dtype, shape, mem_space, assumed_align, order, mode, static)

    def __str__(self):
        return f"JaxTracedArray<{self.dtype}:{self.shape}:{self.order}:{self.mode}:{self.static}>"

    def __repr__(self):
        return str(self)

    def __get_mlir_types__(self):
        # Struct passed as opaque object.
        return [llvm.PointerType.get()]

    def __new_from_mlir_values__(self, values):
        return JaxArrayValue(
            values,
            self.dtype,
            self.shape,
            self.mem_space,
            self.assumed_align,
            self.order,
            self.mode,
            self.static,
        )

    def __c_pointers__(self):
        return [0]


class JaxArrayList:
    """Holds list of JaxArray or JaxTracedArray.
    This class facilitates conversion of JaxTracedArray to JaxArray when crossing
    the jit boundary.
    """

    def __init__(self, arrays: Sequence[JaxArray]):
        self.arrays = tuple(arrays)

    def __getitem__(self, idx):
        return self.arrays[idx]

    def __len__(self):
        return len(self.arrays)

    def __iter__(self):
        return iter(self.arrays)

    def __c_pointers__(self):
        return [x.__c_pointers__()[0] for x in self.arrays]

    def __get_mlir_types__(self):
        return [x.__get_mlir_types__()[0] for x in self.arrays]

    def __extract_mlir_values__(self):
        return [x.__extract_mlir_values__()[0] for x in self.arrays]

    def __new_from_mlir_values__(self, values):
        return JaxArrayList(
            [x.__new_from_mlir_values__(v) for x, v in zip(self.arrays, values)]
        )
