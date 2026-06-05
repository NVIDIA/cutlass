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


import ctypes
import sys
import math
from pathlib import Path
from functools import lru_cache
import itertools
import operator
from typing import Any, Union, Optional, Type, List, NoReturn

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
    TypedTensor,
    Tensor,
    Pointer,
    Numeric,
    SymInt,
    Float32,
    TFloat32,
    Shape,
    Stride,
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
        pointer: int,
        dtype: Type[Numeric],
        mem_space: _cute_ir.AddressSpace = _cute_ir.AddressSpace.generic,
        assumed_align: Optional[int] = None,
    ) -> None:
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

    def __get_mlir_types__(self) -> List[ir.Type]:
        return [self.mlir_type]

    def __tvm_ffi_opaque_ptr__(self) -> object:
        return self._pointer

    def __c_pointers__(self) -> List[int]:
        return self._c_pointers_cache

    def __new_from_mlir_values__(self, values: List[object]) -> object:  # type: ignore[override]
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
    def memspace(self) -> AddressSpace:
        return self._addr_space

    def align(
        self,
        min_align: int,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Pointer:
        raise NotImplementedError("align is not supported in runtime")

    def __add__(self, offset: int) -> Pointer:  # type: ignore[override]
        offset_bytes = offset * self._dtype.width // 8
        assumed_align = math.gcd(offset_bytes, self._assumed_align)
        return _Pointer(
            self._pointer + offset_bytes, self._dtype, self._addr_space, assumed_align
        )

    def __sub__(self, offset: int) -> Pointer:
        return self.__add__(-offset)

    def __str__(self) -> str:
        return f"Ptr<0x{int(self._pointer):016x}@{self._addr_space}>"

    def __repr__(self) -> str:
        return self.__str__()

    @property
    def __cache_key__(self) -> tuple:
        return (self.dtype, self._addr_space, self._assumed_align)


class _Tensor(Tensor):
    def __init__(
        self,
        tensor: object,
        assumed_align: Optional[int] = None,
        use_32bit_stride: bool = False,
        *,
        enable_tvm_ffi: bool = False,
    ) -> None:
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
                self._dlpack_data = tensor.__dlpack__(stream=-1)  # type: ignore[attr-defined]
            except Exception:
                self._dlpack_data = tensor.__dlpack__()  # type: ignore[attr-defined]

        self._dltensor_wrapper: Any = None
        self._assumed_align = assumed_align
        self._is_dynamic = False
        self._memref_desc: Any = None
        self._dtype: Any = None
        self._use_32bit_stride = use_32bit_stride
        self._c_pointers_cache: Optional[List[int]] = None

    @property  # type: ignore[misc]
    def __class__(self) -> Type[Tensor]:  # type: ignore[override]
        # Cheat to let `type(_Tensor())` to return cute.Tensor
        return Tensor

    def load_dltensor(self) -> None:
        """Lazily load the DLTensorWrapper.

        This function loads the DLTensorWrapper when needed,
        avoiding overhead in the critical path of calling JIT functions.
        """
        if self._dltensor_wrapper is None:
            self._dltensor_wrapper = _cute_ir.DLTensorWrapper(
                self._dlpack_data, self._use_32bit_stride
            )

    def mark_layout_dynamic(self, leading_dim: Optional[int] = None) -> "_Tensor":
        """Marks the tensor layout as dynamic based on the leading dimension.

        :param leading_dim: The leading dimension of the layout, defaults to None
        :type leading_dim: int, optional

        When ``leading_dim`` is None, the leading dimension is deduced as follows:

        - If exactly one dimension has stride 1, that dimension is used.
        - If multiple dimensions have stride 1 but exactly one of them has size > 1,
          that dimension is used.
        - If multiple dimensions have stride 1 but none or more than one has size > 1,
          an error is raised.
        - If no dimension has stride 1, all strides remain dynamic.

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
    ) -> "_Tensor":
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
    def element_type(self, new_type: Type[Numeric]) -> None:
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
    def memspace(self) -> AddressSpace:
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

    def __repr__(self) -> str:
        return self.__str__()

    @property
    def __cache_key__(self) -> tuple:
        self.load_dltensor()
        if self._dtype is None:
            self._dtype = self._dltensor_wrapper.dtype
        return (self._dtype, self._assumed_align, self._dltensor_wrapper.cache_key())

    def __setitem__(self, crd: object, value: object) -> None:
        raise TypeError("runtime._Tensor is not indexable")

    def __getitem__(self, crd: object) -> NoReturn:
        raise TypeError("runtime._Tensor is not indexable")

    @property
    def iterator(self) -> _Pointer:
        self.load_dltensor()
        return _Pointer(
            self._dltensor_wrapper.data_ptr,
            self.element_type,
            self.memspace,
            self._assumed_align,
        )

    @property
    def layout(self) -> NoReturn:
        raise NotImplementedError(
            "layout property is not supported in runtime, support in future"
        )

    @property
    def shape(self) -> Shape:
        self.load_dltensor()
        return self._dltensor_wrapper.shape

    @property
    def stride(self) -> Stride:
        self.load_dltensor()
        strides = self._dltensor_wrapper.stride
        if strides is None:
            # support tensor created by the old numpy version
            strides = itertools.accumulate(
                reversed(self.shape),  # type: ignore[arg-type]
                func=operator.mul,
                initial=1,
            )
            strides = tuple(reversed(list(strides)[:-1]))
        return strides

    @property
    @lru_cache(maxsize=128, typed=True)
    def leading_dim(self) -> Union[int, tuple[int, ...], None]:
        """Get the leading dimension of this Tensor.

        :return: The leading dimension index or indices
        :rtype: int or tuple or None

        The return value depends on the tensor's stride pattern:

        * If a single leading dimension is found, returns an integer index
        * If nested leading dimensions are found, returns a tuple of indices
        * If no leading dimension is found, returns None
        """
        return core.leading_dim(self.shape, self.stride)

    def fill(self, value: Numeric) -> None:
        raise TypeError("fill function is not supported in runtime")

    @property
    def data_ptr(self) -> int:
        self.load_dltensor()
        return self._dltensor_wrapper.data_ptr

    @property
    def dynamic_shapes_mask(self) -> tuple[int, ...]:
        """Get the mask of dynamic shapes in the tensor."""
        self.load_dltensor()
        return self._dltensor_wrapper.get_dynamic_shapes_mask()

    @property
    def dynamic_strides_mask(self) -> tuple[int, ...]:
        """Get the mask of dynamic strides in the tensor."""
        self.load_dltensor()
        return self._dltensor_wrapper.get_dynamic_strides_mask()

    def __c_pointers__(self) -> List[int]:
        if self._c_pointers_cache is None:
            self.load_dltensor()
            self._memref_desc = self._dltensor_wrapper.build_memref_desc(
                self._assumed_align
            )
            self._c_pointers_cache = [_cute_ir.pycapsule_get_pointer(self._memref_desc)]
        return self._c_pointers_cache

    def __get_mlir_types__(self) -> List[ir.Type]:
        return [self.mlir_type]

    def __new_from_mlir_values__(self, values: List[object]) -> CoreTensor:
        assert len(values) == 1
        assert isinstance(values[0], CoreTensor)
        return CoreTensor(values[0].value, self._dtype)

    def __tvm_ffi_object__(self) -> object:
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
    :type shape: tuple[Union[int, SymInt], ...]
    :param stride: Stride of the tensor, defaults to None, consists of int (static) or SymInt (dynamic)
    :type stride: tuple[Union[int, SymInt], ...], optional
    :param memspace: Memory space where the fake tensor resides. Defaults to AddressSpace.gmem.
    :type memspace: AddressSpace, optional
    :param assumed_align: Assumed alignment of the tensor (bytes), defaults to None. If None, uses the element size bytes as the assumed alignment.
    :type assumed_align: int, optional
    :param use_32bit_stride: Whether to use 32-bit stride. Defaults to False. When True, the dynamic stride bitwidth
        will be set to 32 for small problem sizes (cosize(layout) <= Int32_max) for better performance. This is only applied
        when the dimension is dynamic.
    :type use_32bit_stride: bool, optional

    """

    def __init__(
        self,
        dtype: Type[Numeric],
        shape: tuple[Union[int, SymInt], ...],
        *,
        stride: tuple[Union[int, SymInt], ...],
        memspace: AddressSpace = AddressSpace.gmem,
        assumed_align: Optional[int] = None,
        use_32bit_stride: bool = False,
    ) -> None:
        if not isinstance(shape, (tuple, list)):
            raise ValueError(f"Expected tuple or list but got {type(shape)}")

        if isinstance(shape, list):
            shape = tuple(shape)
        if not all(isinstance(s, (int, SymInt)) for s in shape):
            raise ValueError("All shape elements must be int or SymInt")

        if isinstance(stride, list):
            stride = tuple(stride)

        if stride is not None and not all(isinstance(s, (int, SymInt)) for s in stride):
            raise ValueError("All stride elements must be int or SymInt")
        self._typed_tensor = TypedTensor(dtype, shape, stride, memspace, assumed_align)  # type: ignore[arg-type]
        self._assumed_align = self._typed_tensor._assumed_align
        self._use_32bit_stride = use_32bit_stride

    @property
    def mlir_type(self) -> ir.Type:
        return self._typed_tensor.mlir_type  # pragma: no cover

    def __get_mlir_types__(self) -> list[ir.Type]:
        return self._typed_tensor.__get_mlir_types__()

    def __new_from_mlir_values__(self, values: list[object]) -> CoreTensor:
        assert len(values) == 1
        assert isinstance(values[0], CoreTensor)
        return CoreTensor(values[0].value, self.element_type)

    def __str__(self) -> str:
        return f"FakeTensor<{self.element_type}, {self.shape}, {self.stride}>"

    @property
    def __cache_key__(self) -> tuple:
        # Use id() for SymInt elements to match TVM FFI's identity-based
        # deduplication (SymIntId). This ensures that different SymInt objects
        # produce different cache keys even if they have the same symbol name,
        # preventing incorrect cache hits when kernels have different signatures.
        def _cache_key_element(e: object) -> object:
            return id(e) if isinstance(e, SymInt) else e

        return (
            self.element_type,
            self.memspace,
            self._typed_tensor.assumed_align,
            tuple(_cache_key_element(s) for s in self.shape),  # type: ignore[union-attr]
            tuple(_cache_key_element(s) for s in self.stride),  # type: ignore[union-attr]
        )

    def __repr__(self) -> str:
        return self.__str__()

    def __setitem__(self, crd: object, value: object) -> None:
        raise DSLRuntimeError("runtime._FakeTensor is not indexable")

    def __getitem__(self, crd: object) -> NoReturn:
        raise DSLRuntimeError("runtime._FakeTensor is not indexable")

    @property  # type: ignore[misc]
    def element_type(self) -> Type[Numeric]:
        return self._typed_tensor.element_type

    @property
    def memspace(self) -> AddressSpace:
        return self._typed_tensor.memspace

    @property
    def iterator(self) -> NoReturn:
        raise DSLRuntimeError("runtime._FakeTensor has dummy iterator")

    @property
    def shape(self) -> Shape:
        return self._typed_tensor.shape

    @property
    def stride(self) -> Stride:
        return self._typed_tensor.stride

    @property
    def leading_dim(self) -> Union[int, tuple[int, ...], None]:
        return core.leading_dim(self._typed_tensor.shape, self._typed_tensor.stride)

    @property
    def dynamic_shapes_mask(self) -> tuple[int, ...]:
        return tuple(
            1 if isinstance(e, SymInt) else 0
            for e in self._typed_tensor.shape  # type: ignore[union-attr]
        )

    @property
    def dynamic_strides_mask(self) -> tuple[int, ...]:
        return tuple(
            1 if isinstance(e, SymInt) else 0
            for e in self._typed_tensor.stride  # type: ignore[union-attr]
        )

    def fill(self, value: Numeric) -> None:
        raise DSLRuntimeError("runtime._FakeTensor is not writable")


def make_fake_compact_tensor(
    dtype: Type[Numeric],
    shape: tuple[Union[int, SymInt], ...],
    *,
    stride_order: Optional[tuple[int, ...]] = None,
    memspace: AddressSpace = AddressSpace.gmem,
    assumed_align: Optional[int] = None,
    use_32bit_stride: bool = False,
) -> _FakeTensor:
    """
    Create a fake tensor with the specified shape, element type, and a compact memory layout.

    :param dtype: Data type of the tensor elements.
    :type dtype: Type[Numeric]
    :param shape: Shape of the tensor, consisting of static (int) or dynamic (SymInt) dimensions.
    :type shape: tuple[int | SymInt, ...]
    :param stride_order: Order in which strides (memory layout) are assigned to the tensor dimensions.
        If None, the default layout is left-to-right order (known as column-major order for flatten layout).
        Otherwise, it should be a permutation order of the dimension indices.
        The mode with stride_order 0 is the fastest changing (leading) dimension, and N-1 is the slowest changing.
    :type stride_order: tuple[int, ...], optional
    :param memspace: Memory space where the fake tensor resides. Defaults to AddressSpace.gmem.
    :type memspace: AddressSpace, optional
    :param assumed_align: Assumed byte alignment for the tensor data. If None, the default alignment is the dtype width, & at least 1 byte.
    :type assumed_align: int, optional
    :param use_32bit_stride: Whether to use 32-bit stride for dynamic dimensions. If True and the total size of the
        layout (cosize(layout)) fits within int32, then dynamic strides will use 32-bit integers for improved performance.
        Only applies when dimensions are dynamic. Defaults to False.
    :type use_32bit_stride: bool, optional
    :return: An instance of a fake tensor with the given properties and compact layout.
    :rtype: _FakeTensor

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

        # Default stride order is left-to-right order (0, 1, ..., n-1)
        y = make_fake_compact_tensor(cutlass.Float32, (8, 3, 2)) # y.stride == (1, 8, 24)
    """

    if stride_order is not None:
        if len(stride_order) != len(shape):
            raise ValueError(
                f"stride_order ({stride_order}) must be empty or have same length as shape ({shape})."
            )
    else:
        # Default stride order is left-to-right
        stride_order = stride_order or tuple(range(len(shape)))

    # Make compact strides (possibly symbolic) from shape & stride_order
    stride = [None] * len(stride_order)
    stride_product = 1
    for order in range(len(stride_order)):
        idx = stride_order.index(order)
        stride[idx] = stride_product  # type: ignore[call-overload]
        stride_product *= shape[idx]  # type: ignore[assignment]

    stride_width = 32 if use_32bit_stride else 64
    stride = tuple(  # type: ignore[assignment]
        SymInt(width=stride_width, divisibility=s.divisibility)
        if isinstance(s, SymInt)
        else s
        for s in stride
    )

    return _FakeTensor(
        dtype,
        shape,
        stride=stride,  # type: ignore[arg-type]
        memspace=memspace,
        assumed_align=assumed_align,
        use_32bit_stride=use_32bit_stride,
    )


def make_fake_tensor(
    dtype: Type[Numeric],
    shape: tuple[Union[int, SymInt], ...],
    stride: tuple[Union[int, SymInt], ...],
    *,
    memspace: AddressSpace = AddressSpace.gmem,
    assumed_align: int | None = None,
) -> _FakeTensor:
    """
    Create a fake tensor with the specified element type, shape, and stride.

    :param dtype: Data type of the tensor elements.
    :type dtype: Type[Numeric]
    :param shape: Shape of the tensor, consisting of static (int) or dynamic (SymInt) dimensions.
    :type shape: tuple[int | SymInt, ...]
    :param stride: Stride of the tensor, consisting of static (int) or dynamic (SymInt) values.
    :type stride: tuple[int | SymInt, ...]
    :param memspace: Memory space where the fake tensor resides. Defaults to AddressSpace.gmem.
    :type memspace: AddressSpace, optional
    :param assumed_align: Assumed byte alignment for the tensor data. If None, the default alignment is the dtype width, & at least 1 byte.
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

    def __init__(self, *, use_tvm_ffi_env_stream: bool = False) -> None:
        self.use_tvm_ffi_env_stream = use_tvm_ffi_env_stream

    def __str__(self) -> str:
        return "FakeStream"

    def __repr__(self) -> str:
        return self.__str__()

    def __new_from_mlir_values__(self, values: List[object]) -> object:
        assert len(values) == 1
        return values[0]

    def __c_pointers__(self) -> List[int]:
        return [0]

    def __get_mlir_types__(self) -> List[ir.Type]:
        return [_cuda_dialect.StreamType.get()]


def make_fake_stream(*, use_tvm_ffi_env_stream: bool = False) -> _FakeStream:
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
    tensor_dlpack: object,
    assumed_align: Optional[int] = None,
    use_32bit_stride: bool = False,
    *,
    enable_tvm_ffi: bool = False,
    force_tf32: bool = False,
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

    For packed subbyte torch dtypes such as ``torch.float4_e2m1fn_x2``,
    ``from_dlpack`` returns the logical element layout expected by CuTe instead
    of the packed storage layout. For example, a torch tensor with shape
    ``(128, 128)`` and dtype ``torch.float4_e2m1fn_x2`` is exposed as a logical
    FP4 tensor with shape ``(128, 256)``.

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
    assumed_align: Optional[int] = None,
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
        address_value = ctypes.cast(value, ctypes.c_void_p).value  # type: ignore[assignment]
        assert address_value is not None, "Pointer address is None"
    else:
        raise TypeError(
            f"Expect int or ctypes.POINTER for value but got {type(value)=}"
        )

    return _Pointer(address_value, dtype, mem_space, assumed_align=assumed_align)


def nullptr(
    dtype: Type[Numeric],
    mem_space: AddressSpace = AddressSpace.generic,
    assumed_align: Optional[int] = None,
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

    def __init__(self, arg: object) -> None:
        self._arg = from_dlpack(arg).mark_layout_dynamic()
        self._c_pointers_cache: Optional[list[int]] = None
        self._mlir_types_cache: Optional[list[ir.Type]] = None

    def __new_from_mlir_values__(self, values: list[object]) -> object:
        return self._arg.__new_from_mlir_values__(values)  # type: ignore[attr-defined]

    def __c_pointers__(self) -> list[int]:
        if self._c_pointers_cache is None:
            self._c_pointers_cache = self._arg.__c_pointers__()  # type: ignore[attr-defined]
        return self._c_pointers_cache

    def __get_mlir_types__(self) -> list[ir.Type]:
        if self._mlir_types_cache is None:
            self._mlir_types_cache = self._arg.__get_mlir_types__()  # type: ignore[attr-defined]
        return self._mlir_types_cache


def find_runtime_libraries(*, enable_tvm_ffi: bool = True) -> List[str]:
    """
    Find the runtime libraries that needs to be available for loading modules.

    :param enable_tvm_ffi: Whether to enable TVM-FFI.
    :type enable_tvm_ffi: bool, optional
    :return: A list of runtime libraries that needs to be available for loading modules.
    :rtype: list
    """

    def _get_cute_dsl_runtime_path() -> Optional[str]:
        libs = get_prefix_dsl_libs("CUTE_DSL")
        if libs is None:
            return None

        # check if the separator is ; for windows
        if sys.platform.startswith("win32") and ";" in libs:
            libs = libs.split(";")  # type: ignore[assignment]
        else:
            libs = libs.split(":")  # type: ignore[assignment]

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
_LOAD_MODULE_LIBS_CACHE: list[Any] = []


def load_module(
    file_path: str, *, enable_tvm_ffi: bool = False
) -> ExternalBinaryModule:
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

    return ExternalBinaryModule(file_path, enable_tvm_ffi=enable_tvm_ffi)

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
