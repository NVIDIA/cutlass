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

import ctypes
import sys
from pathlib import Path
from functools import lru_cache
import itertools
import operator
from typing import Union, Optional, Type, List

# MLIR modules imports
from cutlass._mlir import ir
from cutlass.base_dsl.env_manager import get_prefix_dsl_libs
import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cuda as _cuda_dialect

from cutlass.cutlass_dsl import JitArgAdapterRegistry, CuTeDSL as _CuTeDSL
from cutlass.base_dsl.common import DSLRuntimeError
from cutlass.base_dsl.export import ExternalBinaryModule

# Local modules imports
from .typing import (
    AddressSpace,
    Layout,
    Tensor,
    Pointer,
    Numeric,
    SymInt,
    Float32,
    TFloat32,
)
from . import core
from .tensor import _Tensor as CoreTensor


class _Pointer(Pointer):
    """Runtime representation of a pointer that can inter-operate with various data structures,
    including numpy arrays and device memory.

    :param pointer: The pointer to the data
    :type pointer: int or pointer-like object
    :param dtype: Data type of the elements pointed to
    :type dtype: Type
    :param mem_space: Memory space where the pointer resides, defaults to generic
    :type mem_space: _cute_ir.AddressSpace, optional
    :param assumed_align: Assumed alignment of input pointer in bytes, defaults to None
    :type assumed_align: int, optional

    :ivar _pointer: The underlying pointer
    :ivar _dtype: Data type of the elements
    :ivar _addr_space: Memory space of the pointer
    :ivar _assumed_align: Alignment of the pointer in bytes
    :ivar _desc: C-type descriptor for the pointer
    :ivar _c_pointer: C-compatible pointer representation
    """

    def __init__(
        self,
        pointer,
        dtype,
        mem_space: _cute_ir.AddressSpace = _cute_ir.AddressSpace.generic,
        assumed_align=None,
    ):
        self._pointer = pointer
        self._dtype = dtype
        self._addr_space = mem_space

        if assumed_align is None:
            self._assumed_align = dtype.width // 8
        else:
            self._assumed_align = assumed_align

        self._desc = ctypes.c_void_p(int(self._pointer))
        self._c_pointer = ctypes.addressof(self._desc)
        self._c_pointers_cache = [self._c_pointer]

        assert int(self._pointer) % self._assumed_align == 0, (
            f"pointer must be {self._assumed_align} bytes aligned"
        )

    def size_in_bytes(self) -> int:
        self._desc = ctypes.c_void_p(int(self._pointer))
        return ctypes.sizeof(self._desc)

    def __get_mlir_types__(self):
        return [self.mlir_type]

    def __tvm_ffi_opaque_ptr__(self):
        return self._pointer

    def __c_pointers__(self):
        return self._c_pointers_cache

    def __new_from_mlir_values__(self, values):
        assert len(values) == 1
        return values[0]

    # Move mlir Type out of __init__ to decouple with mlir Context
    @property
    def mlir_type(self) -> ir.Type:
        return _cute_ir.PtrType.get(
            self._dtype.mlir_type, self._addr_space, self._assumed_align
        )

    @property
    def dtype(self) -> Type[Numeric]:
        return self._dtype

    @property
    def memspace(self):
        return self._addr_space

    def align(self, min_align: int, *, loc=None, ip=None) -> Pointer:
        raise NotImplementedError("align is not supported in runtime")

    def __str__(self) -> str:
        return f"Ptr<0x{int(self._pointer):016x}@{self._addr_space}>"

    def __repr__(self):
        return self.__str__()


class _Tensor(Tensor):
    def __init__(
        self,
        tensor,
        assumed_align=None,
        use_32bit_stride=False,
        *,
        enable_tvm_ffi=False,
    ):
        # If tensor is already a DLPack object, use it directly
        if hasattr(tensor, "__dlpack_device__") and not hasattr(tensor, "__dlpack__"):
            self._dlpack_data = tensor.__dlpack_device__()
        elif enable_tvm_ffi:
            import tvm_ffi

            self._tvm_ffi_tensor = tvm_ffi.from_dlpack(tensor)
            self._dlpack_data = self._tvm_ffi_tensor.__dlpack__()
        else:
            try:
                # we expect no stream sync. Because torch has different default behavior
                # for stream parameter on different version.
                # we need to explicitly pass -1 to achieve no sync effects.
                self._dlpack_data = tensor.__dlpack__(stream=-1)
            except Exception:
                self._dlpack_data = tensor.__dlpack__()

        self._dltensor_wrapper = None
        self._assumed_align = assumed_align
        self._is_dynamic = False
        self._memref_desc = None
        self._dtype = None
        self._use_32bit_stride = use_32bit_stride
        self._c_pointers_cache = None

    @property
    def __class__(self) -> Type[Tensor]:
        # Cheat to let `type(_Tensor())` to return cute.Tensor
        return Tensor

    def load_dltensor(self):
        """Lazily load the DLTensorWrapper.

        This function loads the DLTensorWrapper when needed,
        avoiding overhead in the critical path of calling JIT functions.
        """
        if self._dltensor_wrapper is None:
            self._dltensor_wrapper = _cute_ir.DLTensorWrapper(
                self._dlpack_data, self._use_32bit_stride
            )

    def mark_layout_dynamic(self, leading_dim: Optional[int] = None):
        """Marks the tensor layout as dynamic based on the leading dimension.

        :param leading_dim: The leading dimension of the layout, defaults to None
        :type leading_dim: int, optional

        When ``leading_dim`` is None, automatically deduces the leading dimension from the tensor layout.
        The layout can be deduced only when exactly one dimension has a stride of 1. Raises an error
        if the layout cannot be automatically deduced.

        When ``leading_dim`` is explicitly specified, marks the layout as dynamic while setting the
        stride at ``leading_dim`` to 1. Also validates that the specified ``leading_dim`` is consistent
        with the existing layout by checking that the corresponding stride of that dimension is 1.

        Limitation: only support flat layout for now. Will work on supporting nested layout in the future.

        :return: The tensor with dynamic layout
        :rtype: _Tensor
        """
        self.load_dltensor()
        self._dltensor_wrapper.mark_layout_dynamic(leading_dim)
        return self

    def mark_compact_shape_dynamic(
        self,
        mode: int,
        stride_order: Optional[tuple[int, ...]] = None,
        divisibility: int = 1,
    ):
        """Marks the tensor shape as dynamic and propagates dynamic and divisibility information to the corresponding strides.

        :param mode: The mode of the compact shape, defaults to 0
        :type mode: int
        :param stride_order: Consistent with `torch.Tensor.dim_order`. Defaults to None.

        Indicates the order of the modes (dimensions) if the current layout were converted to row-major order.
        It starts from the outermost to the innermost dimension.
        :type stride_order: tuple[int, ...], optional
        :param divisibility: The divisibility constraint for the compact shape, defaults to 1
        :type divisibility: int, optional
        :return: The tensor with dynamic compact shape
        :rtype: _Tensor

        If ``stride_order`` is not provided, the stride ordering will be automatically deduced from the layout.
        Automatic deduction is only possible when exactly one dimension has a stride of 1 (compact layout).
        An error is raised if automatic deduction fails.

        If ``stride_order`` is explicitly specified, it does the consistency check with the layout.

        For example:
        - Layout: (4,2):(1,4) has stride_order: (1,0) indicates the innermost dimension is 0(`4:1`), the outermost dimension is 1(`2:4`)
        - Layout: (5,3,2,4):(3,1,15,30) has stride_order: (3,2,0,1) indicates the innermost dimension is 1(`3:1`), the outermost dimension is 3(`4:30`).

        Using `torch.Tensor.dim_order()` to get the stride order of the torch tensor.
        .. code-block:: python
        a = torch.empty(3, 4)
        t = cute.runtime.from_dlpack(a)
        t = t.mark_compact_shape_dynamic(mode=0, stride_order=a.dim_order())
        """
        self.load_dltensor()
        self._dltensor_wrapper.mark_compact_shape_dynamic(
            mode, stride_order, divisibility
        )
        return self
    @property
    def element_type(self) -> Type[Numeric]:
        self.load_dltensor()
        if self._dtype is None:
            self._dtype = self._dltensor_wrapper.dtype
        return self._dtype

    @element_type.setter
    def element_type(self, new_type):
        """Set the element type of the tensor.

        :warning: This API is added for narrow precision before we have a clean `recast_tensor` story.

        :note: It is only used for the case that frameworks don't natively support narrow precision but we get tensor
              from frameworks with storage type like uint8.

        **Example**:

        .. code-block:: python

            # Create a tensor from a numpy array
            import numpy as np
            from cutlass.cute import from_dlpack

            # Create a tensor with Float32 elements
            a = np.zeros(shape, dtype=np.uint8)
            tensor = from_dlpack(a)

            # Change the element type to Float4E2M1FN even storage type is uint8
            tensor.element_type = cutlass.Float4E2M1FN

            src = from_dlpack(... data tensor ...)
            # convert and initialize narrow precision tensor
            cute.testing.convert(src, tensor)
        """
        self._dtype = new_type

    @property
    def memspace(self):
        self.load_dltensor()
        return self._dltensor_wrapper.address_space

    @property
    def size_in_bytes(self) -> int:
        self.load_dltensor()
        return self._dltensor_wrapper.size_in_bytes()

    @property
    def mlir_type(self) -> ir.Type:
        self.load_dltensor()
        return self._dltensor_wrapper.get_type(
            self.element_type.mlir_type, self._assumed_align
        )

    def __str__(self) -> str:
        self.load_dltensor()
        return f"Tensor<0x{self._dltensor_wrapper.str}>"

    def __repr__(self):
        return self.__str__()

    def __setitem__(self, crd, value):
        raise TypeError("runtime._Tensor is not indexable")

    def __getitem__(self, crd):
        raise TypeError("runtime._Tensor is not indexable")

    @property
    def iterator(self):
        self.load_dltensor()
        return _Pointer(
            self._dltensor_wrapper.data_ptr,
            self.element_type,
            self.memspace,
            self._assumed_align,
        )

    @property
    def layout(self):
        raise NotImplementedError(
            "layout property is not supported in runtime, support in future"
        )

    @property
    def shape(self):
        self.load_dltensor()
        return self._dltensor_wrapper.shape

    @property
    def stride(self):
        self.load_dltensor()
        strides = self._dltensor_wrapper.stride
        if strides is None:
            strides = itertools.accumulate(
                reversed(self.shape), func=operator.mul, initial=1
            )
            strides = tuple(reversed(list(strides)[:-1]))

        return strides

    @property
    @lru_cache(maxsize=128, typed=True)
    def leading_dim(self):
        """Get the leading dimension of this Tensor.

        :return: The leading dimension index or indices
        :rtype: int or tuple or None

        The return value depends on the tensor's stride pattern:

        * If a single leading dimension is found, returns an integer index
        * If nested leading dimensions are found, returns a tuple of indices
        * If no leading dimension is found, returns None
        """
        return core.leading_dim(self.shape, self.stride)

    def fill(self, value: Numeric):
        raise TypeError("fill function is not supported in runtime")

    @property
    def data_ptr(self):
        self.load_dltensor()
        return self._dltensor_wrapper.data_ptr

    @property
    def dynamic_shapes_mask(self):
        """Get the mask of dynamic shapes in the tensor."""
        self.load_dltensor()
        return self._dltensor_wrapper.get_dynamic_shapes_mask()

    @property
    def dynamic_strides_mask(self):
        """Get the mask of dynamic strides in the tensor."""
        self.load_dltensor()
        return self._dltensor_wrapper.get_dynamic_strides_mask()

    def __c_pointers__(self):
        if self._c_pointers_cache is None:
            self.load_dltensor()
            self._memref_desc = self._dltensor_wrapper.build_memref_desc(
                self._assumed_align
            )
            self._c_pointers_cache = [_cute_ir.pycapsule_get_pointer(self._memref_desc)]
        return self._c_pointers_cache

    def __get_mlir_types__(self):
        return [self.mlir_type]

    def __new_from_mlir_values__(self, values):
        assert len(values) == 1
        assert isinstance(values[0], CoreTensor)
        return CoreTensor(values[0].value, self._dtype)

    def __tvm_ffi_object__(self):
        try:
            return self._tvm_ffi_tensor
        except AttributeError:
            raise DSLRuntimeError(
                (
                    "runtime._Tensor is not a TVM-FFI tensor. "
                    "Enable TVM-FFI with `from_dlpack(..., enable_tvm_ffi=True)` "
                    "or `CUTE_DSL_ENABLE_TVM_FFI=1`."
                )
            )


def _get_cute_type_str(inp):
    def _convert_dyn_elem(e):
        return f"?{{i{e.width} div={e.divisibility}}}"

    elems = [_convert_dyn_elem(e) if isinstance(e, SymInt) else str(e) for e in inp]
    return "(" + ",".join(elems) + ")"


class _FakeCompactTensor(Tensor):
    def __init__(
        self,
        dtype,
        shape,
        stride_order,
        memspace=None,
        assumed_align=None,
        use_32bit_stride=False,
    ):
        self._dtype = dtype
        self._shape = shape
        self._stride_order = stride_order or tuple(range(len(shape)))
        # cannot use memspace or AddressSpace.gmem because AddressSpace.generic is 0
        self._memspace = memspace if memspace is not None else AddressSpace.gmem
        self._assumed_align = assumed_align or -(-dtype.width // 8)
        self._use_32bit_stride = use_32bit_stride

    def __str__(self) -> str:
        return f"FakeTensorOrdered<{self._dtype}, {self._shape}, {self._stride_order}>"

    def __repr__(self):
        return self.__str__()

    @property
    def mlir_type(self) -> ir.Type:
        shape_ty = ir.Type.parse(
            '!cute.shape<"' + _get_cute_type_str(self._shape) + '">'
        )
        layout_ty = _cute_ir.LayoutType.get_ordered(
            shape_ty, self._stride_order, self._use_32bit_stride
        )
        self._stride = layout_ty.stride
        ptr_ty = _cute_ir.PtrType.get(
            self._dtype.mlir_type, self._memspace, self._assumed_align
        )
        return _cute_ir.MemRefType.get(ptr_ty, layout_ty)

    def __get_mlir_types__(self):
        return [self.mlir_type]

    def __new_from_mlir_values__(self, values):
        assert len(values) == 1
        assert isinstance(values[0], CoreTensor)
        return CoreTensor(values[0].value, self._dtype)

    def __setitem__(self, crd, value):
        raise DSLRuntimeError("runtime._FakeCompactTensor is not indexable")

    def __getitem__(self, crd):
        raise DSLRuntimeError("runtime._FakeCompactTensor is not indexable")

    @property
    def element_type(self) -> Type[Numeric]:
        return self._dtype

    @property
    def memspace(self):
        return self._memspace

    @property
    def iterator(self):
        raise DSLRuntimeError("runtime._FakeTensor has dummy iterator")

    @property
    def shape(self):
        return self._shape

    @property
    def stride(self):
        return self._stride

    @property
    def leading_dim(self):
        for dim, order in enumerate(self._stride_order):
            if order == 0:
                return dim

    @property
    def dynamic_shapes_mask(self):
        return tuple(1 if isinstance(e, SymInt) else 0 for e in self._shape)

    @property
    def dynamic_strides_mask(self):
        return tuple(1 if isinstance(e, SymInt) else 0 for e in self._stride)

    def fill(self, value: Numeric):
        raise DSLRuntimeError("runtime._FakeCompactTensor is not writable")


class _FakeTensor(Tensor):
    """Fake Tensor implementation as a placeholder.
    It mimics the interface of Tensor, but does not hold real data or allow indexing.
    Used for compilation or testing situations where only shape/type/layout information is needed.
    All attempts to access or mutate data will raise errors.
    """

    """
    Create a fake tensor with the given shape, type, and layout.

    :param dtype: Data type of the tensor elements
    :type dtype: Type[Numeric]
    :param shape: Shape of the tensor, consists of int (static) or SymInt (dynamic)
    :type shape: tuple[int, ...]
    :param stride: Stride of the tensor, defaults to None, consists of int (static) or SymInt (dynamic)
    :type stride: tuple[int, ...], optional
    :param assumed_align: Assumed alignment of the tensor (bytes), defaults to None. If None, uses the element size bytes as the assumed alignment.
    :type assumed_align: int, optional
    :param use_32bit_stride: Whether to use 32-bit stride. Defaults to False. When True, the dynamic stride bitwidth
        will be set to 32 for small problem sizes (cosize(layout) <= Int32_max) for better performance. This is only applied
        when the dimension is dynamic.
    :type use_32bit_stride: bool, optional


    """

    def __init__(self, dtype, shape, *, stride, memspace=None, assumed_align=None):
        self._dtype = dtype
        self._shape = shape
        self._stride = stride
        # cannot use memspace or AddressSpace.generic because AddressSpace.generic is 0
        self._memspace = memspace if memspace is not None else AddressSpace.gmem
        self._assumed_align = assumed_align
        if assumed_align is None:
            # use the bytes width of the element dtype. The alignment is at least one byte align.
            self._assumed_align = (self._dtype.width + 7) // 8

        if not isinstance(shape, (tuple, list)):
            raise ValueError(f"Expected tuple or list but got {type(shape)}")

        if not all(isinstance(s, (int, SymInt)) for s in self._shape):
            raise ValueError("All shape elements must be int or SymInt")

        if stride is not None and not all(
            isinstance(s, (int, SymInt)) for s in self._stride
        ):
            raise ValueError("All stride elements must be int or SymInt")
    @property
    def mlir_type(self) -> ir.Type:
        shape_str = _get_cute_type_str(self._shape)
        stride_str = _get_cute_type_str(self._stride)
        layout_ty = ir.Type.parse(f'!cute.layout<"{shape_str}:{stride_str}">')
        ptr_ty = _cute_ir.PtrType.get(
            self._dtype.mlir_type, self._memspace, self._assumed_align
        )
        return _cute_ir.MemRefType.get(ptr_ty, layout_ty)

    def __get_mlir_types__(self):
        return [self.mlir_type]

    def __new_from_mlir_values__(self, values):
        assert len(values) == 1
        assert isinstance(values[0], CoreTensor)
        return CoreTensor(values[0].value, self._dtype)

    def __str__(self) -> str:
        return f"FakeTensor<{self._dtype}, {self._shape}, {self._stride}>"

    def __repr__(self):
        return self.__str__()

    def __setitem__(self, crd, value):
        raise DSLRuntimeError("runtime._FakeTensor is not indexable")

    def __getitem__(self, crd):
        raise DSLRuntimeError("runtime._FakeTensor is not indexable")

    @property
    def element_type(self) -> Type[Numeric]:
        return self._dtype

    @property
    def memspace(self):
        return self._memspace

    @property
    def iterator(self):
        raise DSLRuntimeError("runtime._FakeTensor has dummy iterator")

    @property
    def shape(self):
        return self._shape

    @property
    def stride(self):
        return self._stride

    @property
    def dynamic_shapes_mask(self):
        return tuple(1 if isinstance(e, SymInt) else 0 for e in self._shape)

    @property
    def dynamic_strides_mask(self):
        return tuple(1 if isinstance(e, SymInt) else 0 for e in self._stride)

    def fill(self, value: Numeric):
        raise DSLRuntimeError("runtime._FakeTensor is not writable")


def make_fake_compact_tensor(
    dtype,
    shape,
    *,
    stride_order=None,
    memspace=None,
    assumed_align=None,
    use_32bit_stride=False,
):
    """
    Create a fake tensor with the specified shape, element type, and a compact memory layout.

    :param dtype: Data type of the tensor elements.
    :type dtype: Type[Numeric]
    :param shape: Shape of the tensor.
    :type shape: tuple[int, ...]
    :param stride_order: Order in which strides (memory layout) are assigned to the tensor dimensions.
        If None, the default layout is left-to-right order (known as column-major order for flatten layout).
        Otherwise, it should be a permutation order of the dimension indices.
    :type stride_order: tuple[int, ...], optional
    :param memspace: Memory space where the fake tensor resides. Optional.
    :type memspace: str, optional
    :param assumed_align: Assumed byte alignment for the tensor data. If None, the default alignment is used.
    :type assumed_align: int, optional
    :param use_32bit_stride: Whether to use 32-bit stride for dynamic dimensions. If True and the total size of the
        layout (cosize(layout)) fits within int32, then dynamic strides will use 32-bit integers for improved performance.
        Only applies when dimensions are dynamic. Defaults to False.
    :type use_32bit_stride: bool, optional
    :return: An instance of a fake tensor with the given properties and compact layout.
    :rtype: _FakeCompactTensor

    **Examples:**

    .. code-block:: python

        @cute.jit
        def foo(x: cute.Tensor):
            ...

        x = make_fake_compact_tensor(
            cutlass.Float32, (100, cute.sym_int32(divisibility=8)), stride_order=(1, 0)
        )

        # Compiled function will take a tensor with the type:
        #   tensor<ptr<f32, generic> o (100,?{div=8}):(?{i32 div=8},1)>
        compiled_foo = cute.compile(foo, x)

        # Default stride order is left-to-right order: (1, 8)
        y = make_fake_compact_tensor(cutlass.Float32, (8, 3))
    """

    return _FakeCompactTensor(
        dtype,
        shape,
        stride_order=stride_order,
        memspace=memspace,
        assumed_align=assumed_align,
        use_32bit_stride=use_32bit_stride,
    )


def make_fake_tensor(dtype, shape, stride, *, memspace=None, assumed_align=None):
    """
    Create a fake tensor with the specified element type, shape, and stride.

    :param dtype: Data type of the tensor elements.
    :type dtype: Type[Numeric]
    :param shape: Shape of the tensor.
    :type shape: tuple[int, ...]
    :param stride: Stride of the tensor.
    :type stride: tuple[int, ...]
    :param assumed_align: Assumed byte alignment for the tensor data. If None, the default alignment is used. Defaults to None.
    :type assumed_align: int, optional
    :return: An instance of a fake tensor with the given properties.
    :rtype: _FakeTensor
    """
    return _FakeTensor(
        dtype, shape, stride=stride, memspace=memspace, assumed_align=assumed_align
    )


class _FakeStream:
    """A fake stream that can be used as a placeholder for a stream in compilation.

    When use_tvm_ffi_env_stream is True and the function is compiled with TVM-FFI,
    the argument will be skipped from the function signature and we pass in
    this value through the environment stream obtained from caller context
    (e.g. torch.cuda.current_stream()).
    """

    use_tvm_ffi_env_stream: bool

    def __init__(self, *, use_tvm_ffi_env_stream: bool = False):
        self.use_tvm_ffi_env_stream = use_tvm_ffi_env_stream

    def __str__(self) -> str:
        return f"FakeStream"

    def __repr__(self):
        return self.__str__()

    def __new_from_mlir_values__(self, values):
        assert len(values) == 1
        return values[0]

    def __c_pointers__(self):
        return [0]

    def __get_mlir_types__(self):
        return [_cuda_dialect.StreamType.get()]


def make_fake_stream(*, use_tvm_ffi_env_stream: bool = False):
    """Create a fake stream that can be used as a placeholder for a stream in compilation.

    When use_tvm_ffi_env_stream is True and the function is compiled with TVM-FFI,
    the argument will be skipped from the function signature and we pass in
    this value through the environment stream obtained from caller context
    (e.g. torch.cuda.current_stream()). This can speedup the calling process
    since we no longer need to do stream query in python.

    :param use_tvm_ffi_env_stream: Whether to skip this parameter use environment stream instead.
    :type use_tvm_ffi_env_stream: bool
    """
    return _FakeStream(use_tvm_ffi_env_stream=use_tvm_ffi_env_stream)


def from_dlpack(
    tensor_dlpack,
    assumed_align=None,
    use_32bit_stride=False,
    *,
    enable_tvm_ffi=False,
    force_tf32=False,
) -> Tensor:
    """Convert from tensor object supporting __dlpack__() to a CuTe Tensor.

    :param tensor_dlpack: Tensor object that supports the DLPack protocol
    :type tensor_dlpack: object
    :param assumed_align: Assumed alignment of the tensor (bytes), defaults to None,
      if None, will use the element size bytes as the assumed alignment.
    :type assumed_align: int, optional
    :param use_32bit_stride: Whether to use 32-bit stride, defaults to False. When True, the dynamic
      stride bitwidth will be set to 32 for small problem size (cosize(layout) <= Int32_max) for better performance.
      This is only applied when the dimension is dynamic.
    :type use_32bit_stride: bool, optional
    :param enable_tvm_ffi: Whether to enable TVM-FFI, defaults to False. When True, the tensor will be converted to
      a TVM-FFI function compatible tensor.
    :type enable_tvm_ffi: bool, optional
    :param force_tf32: Whether to force the element type to TFloat32 if the element type is Float32.
    :type force_tf32: bool, optional
    :return: A CuTe Tensor object
    :rtype: Tensor

    **Examples:**

    .. code-block:: python

        import torch
        from cutlass.cute.runtime import from_dlpack
        x = torch.randn(100, 100)
        y = from_dlpack(x)
        y.shape
        # (100, 100)
        type(y)
        # <class 'cutlass.cute.Tensor'>
    """
    # If the environment variable `CUTE_DSL_ENABLE_TVM_FFI` is set to True, the tensor will be converted to
    # a TVM-FFI function compatible tensor.
    enable_tvm_ffi = enable_tvm_ffi or _CuTeDSL._get_dsl().envar.enable_tvm_ffi
    res = _Tensor(
        tensor_dlpack,
        assumed_align=assumed_align,
        use_32bit_stride=use_32bit_stride,
        enable_tvm_ffi=enable_tvm_ffi,
    )
    if force_tf32 and res.element_type == Float32:
        res.element_type = TFloat32
    return res


def make_ptr(
    dtype: Type[Numeric],
    value: Union[int, ctypes._Pointer],
    mem_space: AddressSpace = AddressSpace.generic,
    assumed_align=None,
) -> Pointer:
    """Create a pointer from a memory address

    :param dtype: Data type of the pointer elements
    :type dtype: Type[Numeric]
    :param value: Memory address as integer or ctypes pointer
    :type value: Union[int, ctypes._Pointer]
    :param mem_space: Memory address space, defaults to AddressSpace.generic
    :type mem_space: AddressSpace, optional
    :param align_bytes: Alignment in bytes, defaults to None
    :type align_bytes: int, optional
    :return: A pointer object
    :rtype: Pointer

    .. code-block:: python

        import numpy as np
        import ctypes

        from cutlass import Float32
        from cutlass.cute.runtime import make_ptr

        # Create a numpy array
        a = np.random.randn(16, 32).astype(np.float32)

        # Get pointer address as integer
        ptr_address = a.ctypes.data_as(ctypes.POINTER(ctypes.c_float))

        # Create pointer from address
        y = make_ptr(cutlass.Float32, ptr_address)

        # Check properties
        print(y.element_type)
        print(type(y))  # <class 'cutlass.cute.Pointer'>
    """
    # check if value is int or ctypes.POINTER
    if isinstance(value, int):
        address_value = value
    elif isinstance(value, ctypes._Pointer):
        # get address value
        address_value = ctypes.cast(value, ctypes.c_void_p).value
        assert address_value is not None, "Pointer address is None"
    else:
        raise TypeError(
            f"Expect int or ctypes.POINTER for value but got {type(value)=}"
        )

    return _Pointer(address_value, dtype, mem_space, assumed_align=assumed_align)


def nullptr(
    dtype: Type[Numeric],
    mem_space: AddressSpace = AddressSpace.generic,
    assumed_align=None,
) -> Pointer:
    """Create a null pointer which is useful for compilation

    :param dtype: Data type of the pointer elements
    :type dtype: Type[Numeric]
    :param mem_space: Memory address space, defaults to AddressSpace.generic
    :type mem_space: AddressSpace, optional
    :return: A null pointer object
    :rtype: Pointer
    """
    return make_ptr(dtype, 0, mem_space, assumed_align=assumed_align)


class TensorAdapter:
    """
    Convert a DLPack protocol supported tensor/array to a cute tensor.
    """

    def __init__(self, arg):
        self._arg = from_dlpack(arg).mark_layout_dynamic()
        self._c_pointers_cache = None
        self._mlir_types_cache = None

    def __new_from_mlir_values__(self, values):
        return self._arg.__new_from_mlir_values__(values)

    def __c_pointers__(self):
        if self._c_pointers_cache is None:
            self._c_pointers_cache = self._arg.__c_pointers__()
        return self._c_pointers_cache

    def __get_mlir_types__(self):
        if self._mlir_types_cache is None:
            self._mlir_types_cache = self._arg.__get_mlir_types__()
        return self._mlir_types_cache


def find_runtime_libraries(*, enable_tvm_ffi: bool = True) -> List[str]:
    """
    Find the runtime libraries that needs to be available for loading modules.

    :param enable_tvm_ffi: Whether to enable TVM-FFI.
    :type enable_tvm_ffi: bool, optional
    :return: A list of runtime libraries that needs to be available for loading modules.
    :rtype: list
    """

    def _get_cute_dsl_runtime_path():
        libs = get_prefix_dsl_libs("CUTE_DSL")
        if libs is None:
            return None

        # check if the separator is ; for windows
        if sys.platform.startswith("win32") and ";" in libs:
            libs = libs.split(";")
        else:
            libs = libs.split(":")

        for path in libs:
            if path.endswith("libcute_dsl_runtime.so"):
                return path

        return None

    libs = []
    cute_dsl_runtime_path = _get_cute_dsl_runtime_path()
    if cute_dsl_runtime_path:
        libs.append(cute_dsl_runtime_path)

    if enable_tvm_ffi:
        import tvm_ffi

        libs.append(tvm_ffi.libinfo.find_libtvm_ffi())

    return libs

# cache to load runtime libraries so they can be found by the DSO loader
_LOAD_MODULE_LIBS_CACHE = []


def load_module(file_path: str, *, enable_tvm_ffi: bool = False):
    """Load a module from a file path.

    :param file_path: The path to the module file
    :type file_path: str
    :param enable_tvm_ffi: Whether to enable TVM-FFI, defaults to True. When True, the module will be loaded as a TVM-FFI module.
    :type enable_tvm_ffi: bool, optional
    :return: A module object
    :rtype: module
    """
    if len(_LOAD_MODULE_LIBS_CACHE) == 0:
        # ensure the runtime libraries are loaded so they can be found by the DSO loader
        # no need to load tvm_ffi library here since it will be loaded by tvm_ffi package.
        for path in find_runtime_libraries(enable_tvm_ffi=False):
            if Path(path).exists():
                _LOAD_MODULE_LIBS_CACHE.append(ctypes.CDLL(path))

    if enable_tvm_ffi:
        import tvm_ffi

        try:
            # keep_module_alive=False means the module will be unloaded
            # after the returned module goes out of scope, this is useful
            # for frequent loading and unloading of modules. The only requirement
            # is that the module do not return object that have deleter in the module
            # and the returned object lives longer than the module.
            # DSL functions to not have such issue so it is desirable to set this to False.
            return tvm_ffi.load_module(file_path, keep_module_alive=False)
        except TypeError:
            # compatible with tvm-ffi < 0.1.6
            return tvm_ffi.load_module(file_path)
    else:
        return ExternalBinaryModule(file_path)

# -------------------------------------------------------------------------
# Try to register_jit_arg_adapter for TensorAdapter
# -------------------------------------------------------------------------

try:  # Register for numpy.ndarray
    import numpy

    JitArgAdapterRegistry.register_jit_arg_adapter(numpy.ndarray)(TensorAdapter)
except ImportError:
    pass  # silent attempt, suppress error
try:  # Register for torch.Tensor
    import torch

    JitArgAdapterRegistry.register_jit_arg_adapter(torch.Tensor)(TensorAdapter)
except ImportError:
    pass  # silent attempt, suppress error
