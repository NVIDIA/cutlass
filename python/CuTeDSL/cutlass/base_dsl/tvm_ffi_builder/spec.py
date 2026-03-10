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

"""Kernel specification classes for TVM-FFI function parameters."""

from abc import ABC

from collections.abc import Sequence
from typing import Optional, Union

try:
    import tvm_ffi
except ModuleNotFoundError:
    pass


class DefaultConfig:
    """Default configuration with context manager support."""

    _current: Optional["DefaultConfig"] = None
    _old_current: Optional["DefaultConfig"] = None
    device_type: str

    def __init__(self, *, device_type: Optional[str] = None) -> None:
        """Initialize a default configuration.

        Parameters
        ----------
        device_type : str, optional
            The device type (e.g., "cpu", "cuda", "metal"). If None, copies from current config.
        """
        if device_type is None:
            device_type = DefaultConfig.current().device_type  # type: ignore[union-attr]
        self.device_type = device_type

    def __enter__(self) -> "DefaultConfig":
        """Enter the context manager."""
        self._old_current = DefaultConfig._current
        DefaultConfig._current = self
        return self

    def __exit__(
        self,
        exc_type: Optional[type],
        exc_val: Optional[BaseException],
        exc_tb: Optional[object],
    ) -> None:
        """Exit the context manager."""
        DefaultConfig._current = self._old_current

    @classmethod
    def current(cls) -> Optional["DefaultConfig"]:
        """Get the current default configuration.

        Returns
        -------
        Optional[DefaultConfig]
            The current default configuration.
        """
        return cls._current

    @classmethod
    def _set_init_default_config(cls) -> None:
        """Set the initial default configuration."""
        current = cls.__new__(cls)
        current.device_type = "cuda"
        cls._current = current


# Initialize the default config to cuda
DefaultConfig._set_init_default_config()


class Param(ABC):
    """Base class for all parameters."""


class Var(Param):
    """variables: pointer, integer, floating-point, boolean, etc.

    Parameters
    ----------
    name : str
        The parameter name.
    dtype : str | tvm_ffi.dtype
        The data type of the parameter.
    divisibility: Optional[int]
        The divisibility of the parameter, by default None.

    """

    name: str
    dtype: "tvm_ffi.dtype"
    divisibility: Optional[int]

    def __init__(
        self,
        name: str,
        dtype: Union[str, "tvm_ffi.dtype"],
        *,
        divisibility: Optional[int] = None,
    ) -> None:
        """Initialize a Var parameter.

        Parameters
        ----------
        name : str
            The parameter name.
        dtype : str | tvm_ffi.dtype
            The data type of the parameter.

        """
        self.name = name
        self.dtype = tvm_ffi.dtype(dtype)
        self.divisibility = divisibility


class Shape(Param):
    """Shape parameter.

    Parameters
    ----------
    name : str
        The parameter name.
    shape: list[int | Var]
        The shape of the parameter.

    """

    name: str
    shape: list[Union[int, Var]]

    def __init__(
        self,
        name: str,
        shape: list[Union[int, Var]],
    ) -> None:
        """Initialize a Shape parameter.

        Parameters
        ----------
        name : str
            The parameter name.
        shape : list[int | Var]
            The shape of the parameter.

        unpack_shape: bool
            Whether to unpack the shape into list of arguments when calling
            the call provider function.
        """
        self.name = name
        self.shape = shape


class Tensor(Param):
    """Tensor parameter.

    Parameters
    ----------
    name : str
        The parameter name.
    dtype : str | tvm_ffi.dtype
        The data type of the parameter.
    shape : Sequence[int | Var]
        The shape of the parameter.
    device_type : int
        The device type of the parameter.
    device_id : Var
        The device id of the parameter.
    strides : Optional[Sequence[Var]], optional
        The strides of the parameter, by default None.
    """

    name: str
    shape: list[Union[int, Var]]
    dtype: "tvm_ffi.dtype"
    strides: Optional[list[Var]]
    dlpack_device_type: int
    device_id: Var
    map_tensor_dtype_f4x2_to_f4: bool
    data_alignment: Optional[int]

    def __init__(
        self,
        name: str,
        shape: Sequence[Union[int, Var]],
        dtype: Union[str, "tvm_ffi.dtype"],
        *,
        device_type: Optional[str] = None,
        device_id: Optional[Var] = None,
        strides: Optional[Sequence[Var]] = None,
        map_tensor_dtype_f4x2_to_f4: bool = False,
        data_alignment: Optional[int] = None,
    ) -> None:
        """Initialize a Tensor parameter.

        Parameters
        ----------
        name : str
            The parameter name.
        device_type : str
            The device type of the parameter.
        shape : Sequence[int | Var]
            The shape of the parameter.
        dtype : str | tvm_ffi.dtype
            The data type of the parameter.
        strides : Optional[Sequence[Var]], optional
            The strides of the parameter, by default None.
        map_tensor_dtype_f4x2_to_f4: bool
            Whether to map tensor dtype float4x2 to float4 for internal use.
        data_alignment: Optional[int], optional
            The data alignment of the parameter, by default None.
        """
        self.name = name
        self.data = Var(name + ".data", tvm_ffi.dtype("handle"))
        self.shape: list[Union[int, Var]] = list(shape)
        self.dtype = tvm_ffi.dtype(dtype)
        self.strides: Optional[list[Var]] = (
            list(strides) if strides is not None else None
        )
        self.data_alignment = data_alignment

        # Use default device type if none specified
        if device_type is None:
            device_type = DefaultConfig.current().device_type  # type: ignore[union-attr]

        example_device = tvm_ffi.device(device_type, 0)
        self.dlpack_device_type = example_device.dlpack_device_type()
        self.device_type_name = example_device.type
        if device_id is None:
            self.device_id = Var(name + ".device.index", tvm_ffi.dtype("int32"))
        else:
            self.device_id = device_id
        self.map_tensor_dtype_f4x2_to_f4 = map_tensor_dtype_f4x2_to_f4


class Stream(Param):
    """Stream parameter."""

    name: str
    var: Var

    def __init__(self, name: str) -> None:
        """Initialize a Stream parameter.

        Parameters
        ----------
        name : str
            The parameter name.
        """
        self.name = name
        self.var = Var(name, tvm_ffi.dtype("handle"))


class EnvStream(Param):
    """EnvStream parameter.

    Note
    ----
    This parameter spec indicates that we expect
    to call the function with TVMFFIEnvGetStream to get the stream
    and it is not part of the FFI function signature.
    """

    name: str
    var: Var

    def __init__(self, name: str) -> None:
        """Initialize a EnvStream parameter.

        Parameters
        ----------
        name : str
            The parameter name.
        """
        self.name = name
        self.var = Var(name, tvm_ffi.dtype("handle"))


class DataPointer(Param):
    """Data pointer parameter.

    The main difference between DataPointer and Var with handle type
    is that DataPointer can contain address space information.
    We also allow passing in int as data pointer, so it can
    conveniently support torch.Tensor.data_ptr() as input.

    Parameters
    ----------
    name : str
        The parameter name.
    """

    name: str
    var: Var
    address_space: Optional[int]

    def __init__(self, name: str, address_space: Optional[int] = None) -> None:
        """Initialize a DataPointer parameter.

        Parameters
        ----------
        name : str
            The parameter name.
        """
        self.name = name
        self.var = Var(name, tvm_ffi.dtype("handle"))
        self.address_space = address_space


class ConstNone(Param):
    """ConstNone parameter.

    Parameters
    ----------
    name : str
        The parameter name.
    """

    name: str

    def __init__(self, name: str) -> None:
        """Initialize a ConstExpr parameter.

        Parameters
        ----------
        name : str
            The parameter name.
        """
        self.name = name


class TupleParam(Param):
    """Tuple parameter.

    Parameters
    ----------
    name : str
        The parameter name.
    """

    name: str
    params: list[Param]

    def __init__(self, name: str, params: list[Param]) -> None:
        """Initialize a TupleParam parameter.

        Parameters
        ----------
        name : str
            The parameter name.
        params : list[Param]
            The parameters of the tuple.
        """
        self.name = name
        self.params = params


def format_param_type(param: Param) -> str:
    """Format a parameter type as a string, recursively handling nested types.

    Parameters
    ----------
    param : Param
        The parameter to format.

    Returns
    -------
    str
        The formatted type string.

    Raises
    ------
    TypeError
        If an unsupported parameter type is encountered.
    """
    if isinstance(param, Var):
        return str(param.dtype)
    elif isinstance(param, Tensor):
        # Format tensor shape
        shape_strs = []
        for dim in param.shape:
            if isinstance(dim, Var):
                shape_strs.append(dim.name)
            else:
                shape_strs.append(str(dim))
        shape_str = "[" + ", ".join(shape_strs) + "]"
        return f"Tensor({shape_str}, {param.dtype})"
    elif isinstance(param, Shape):
        # Format shape parameter
        shape_strs = []
        for dim in param.shape:
            if isinstance(dim, Var):
                shape_strs.append(dim.name)
            else:
                shape_strs.append(str(dim))
        shape_str = "[" + ", ".join(shape_strs) + "]"
        return f"Shape({shape_str})"
    elif isinstance(param, Stream):
        return "Stream"
    elif isinstance(param, DataPointer):
        return "DataPointer"
    elif isinstance(param, ConstNone):
        return "None"
    elif isinstance(param, TupleParam):
        # Recursively format tuple elements
        element_types = [format_param_type(p) for p in param.params]
        return f"Tuple[{', '.join(element_types)}]"
    else:
        raise TypeError(f"Unsupported parameter type: {type(param)}")


def signature(name: str, params: list[Param]) -> str:
    """Generate a function signature string from name and parameters.

    Parameters
    ----------
    name : str
        The function name.
    params : list[Param]
        List of parameter objects (Var or Tensor).

    Returns
    -------
    str
        The formatted function signature.

    Raises
    ------
    ValueError
        If an unknown parameter type is encountered.

    """
    param_strs = []

    for param in params:
        if isinstance(param, EnvStream):
            # env stream is not part of the FFI function signature
            # continue to skip append
            continue

        param_type = format_param_type(param)
        param_str = f"{param.name}: {param_type}"
        param_strs.append(param_str)

    return f"{name}({', '.join(param_strs)})"


def create_map_tensor_dtype_f4x2_to_f4_spec(f4_tensor_spec: Tensor) -> Tensor:
    """
    Create a new Tensor spec that can be translated to f4 via f4x2->f4 conversion.

    Parameters
    ----------
    f4_tensor_spec : Tensor
        The original Tensor spec that declares a f4 tensor.

    Returns
    -------
    Tensor
        The new Tensor spec that can be translated to f4 via f4x2->f4 conversion.
    """
    if f4_tensor_spec.dtype != tvm_ffi.dtype("float4_e2m1fn"):
        raise ValueError("f4_tensor_spec must be a float4 tensor")

    def find_stride_one_index() -> int:
        if f4_tensor_spec.strides is None:
            return len(f4_tensor_spec.shape) - 1
        for i, stride in enumerate(f4_tensor_spec.strides):
            if isinstance(stride, int) and stride == 1:
                return i
        raise ValueError("Cannot find dimension with stride=1")

    stride_one_index = find_stride_one_index()

    def divisibility_divide_by_2(value: Var) -> Optional[int]:
        if value.divisibility is not None:
            if value.divisibility % 2 != 0:
                raise ValueError(f"Dimension with stride=1 must be divisible by 2")
            return value.divisibility // 2
        return None

    def map_shape(index: int, value: Union[int, Var]) -> Union[int, Var]:
        if index == stride_one_index:
            if isinstance(value, int):
                if value % 2 != 0:
                    raise ValueError(f"Dimension {index} with stride=1 must be even")
                return value // 2
            # create a new var with the same name and dtype
            return Var(
                value.name, value.dtype, divisibility=divisibility_divide_by_2(value)
            )
        return value

    def map_stride(index: int, value: Union[int, Var]) -> Union[int, Var]:
        if index != stride_one_index:
            if isinstance(value, int):
                if value % 2 != 0:
                    raise ValueError(f"Dimension {index} with stride != 1 must be even")
                return value // 2
            # create a new var with the same name and dtype
            return Var(
                value.name, value.dtype, divisibility=divisibility_divide_by_2(value)
            )
        return value

    new_shape = [map_shape(i, x) for i, x in enumerate(f4_tensor_spec.shape)]
    if f4_tensor_spec.strides is not None:
        new_strides = [map_stride(i, x) for i, x in enumerate(f4_tensor_spec.strides)]
    else:
        new_strides = None

    return Tensor(
        f4_tensor_spec.name,
        new_shape,
        dtype=tvm_ffi.dtype("float4_e2m1fnx2"),
        strides=new_strides,
        map_tensor_dtype_f4x2_to_f4=True,
    )
