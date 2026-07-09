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


from cutlass.address_space import AddressSpace
from dataclasses import is_dataclass, fields as dataclass_fields
from cutlass.base_dsl.tvm_ffi_builder import spec
from cutlass.base_dsl.jit_executor import ExecutionArgs
from cutlass.base_dsl.common import DSLRuntimeError
from cutlass.base_dsl.utils.tree_utils import is_constexpr_field
from cutlass.cutlass_dsl import is_cute_algebra_type
from .runtime import _FakeStream
from .typing import Tensor, Pointer, SymInt
from .typing import (
    Numeric,
    Boolean,
    Int4,
    Int8,
    Uint8,
    Int16,
    Uint16,
    Int32,
    Uint32,
    Int64,
    Uint64,
    Float16,
    BFloat16,
    Float32,
    TFloat32,
    Float64,
    Float6E2M3FN,
    Float6E3M2FN,
    Float8E5M2,
    Float8E4M3FN,
    Float8E8M0FNU,
    Float4E2M1FN,
    Float4E2M1FNx2,
)
import cuda.bindings.driver as cuda

from types import UnionType
from typing import (
    List,
    Dict,
    Any,
    Optional,
    Union,
    get_origin,
    get_args,
    get_type_hints,
)
import inspect

NumericToTVMFFIDtype = {
    Boolean: "bool",
    Int4: "int4",
    Int8: "int8",
    Uint8: "uint8",
    Int16: "int16",
    Uint16: "uint16",
    Int32: "int32",
    Uint32: "uint32",
    Int64: "int64",
    Uint64: "uint64",
    Float16: "float16",
    BFloat16: "bfloat16",
    Float32: "float32",
    TFloat32: "float32",
    Float64: "float64",
    Float8E5M2: "float8_e5m2",
    Float8E4M3FN: "float8_e4m3fn",
    Float8E8M0FNU: "float8_e8m0fnu",
    Float4E2M1FN: "float4_e2m1fn",
    Float6E2M3FN: "float6_e2m3fn",
    Float6E3M2FN: "float6_e3m2fn",
    # Packed FP4 maps to the tvm-ffi packed dtype (matches torch's
    # ``float4_e2m1fn_x2``; tvm-ffi spells it without the underscore).
    Float4E2M1FNx2: "float4_e2m1fnx2",
}

_UNSUPPORTED_TVM_FFI_NUMERIC_TYPES = set[Any]()

def _numeric_to_tvm_ffi_dtype(dtype: type[Numeric]) -> str:
    if dtype in _UNSUPPORTED_TVM_FFI_NUMERIC_TYPES:
        raise DSLRuntimeError(
            f"TVM-FFI does not support packed tensor dtype {dtype.__name__}. "
            "Packed FP6x4 tensors must not be passed through --enable-tvm-ffi yet."
        )
    try:
        return NumericToTVMFFIDtype[dtype]
    except KeyError as exc:
        raise DSLRuntimeError(
            f"TVM-FFI does not support tensor dtype {dtype.__name__}."
        ) from exc


# Functions which return the MLIR type for the specified CuTe type.
# The functions take a MLIRBuilder as an argument and return the MLIR type.
# Note: these are untyped below to avoid additional imports.
AlternateIrTypeFunctions: Dict[Any, Any] = {
    TFloat32: lambda builder: builder.i32_type,
}

AcceptableNumericTypesForScalar = [
    Boolean,
    Int8,
    Uint8,
    Int16,
    Uint16,
    Int32,
    Uint32,
    Int64,
    Uint64,
    Float16,
    BFloat16,
    Float32,
    TFloat32,
    Float64,
]


def _get_llvm_address_space_from_memspace(
    memspace: AddressSpace,
) -> Optional[int]:
    if memspace == AddressSpace.gmem:
        return 1
    return None


def _is_gpu_memspace(
    memspace: AddressSpace,
) -> bool:
    return memspace != AddressSpace.generic


def _native_struct_type(value: Any) -> Optional[type]:
    """Return the native_struct class represented by a value or annotation."""
    if value is None or value is inspect.Parameter.empty:
        return None
    if isinstance(value, type):
        return value if hasattr(value, "_struct_type") else None
    value_type = type(value)
    return value_type if hasattr(value_type, "_struct_type") else None


class SymIntId:
    def __init__(self, sym_int: SymInt):
        self.sym_int = sym_int

    def __hash__(self) -> int:
        return id(self.sym_int)

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, SymIntId):
            return NotImplemented
        return self.sym_int is other.sym_int


class ConverterContext:
    """Context for managing variable allocation during TVM FFI args conversion."""

    def __init__(self) -> None:
        self.num_dyn_shape_vars: int = 0
        self.num_dyn_stride_vars: int = 0
        self.num_device_id_vars: int = 0
        self.sym_int_id_mapping: Dict[SymIntId, spec.Var] = {}
        self.vdevice_to_device_id_mapping: Dict[tuple, spec.Var] = {}

    def alloc_shape_name(self) -> str:
        """Allocate a new dynamic shape variable name."""
        name = f"n{self.num_dyn_shape_vars}"
        self.num_dyn_shape_vars += 1
        return name

    def alloc_stride_name(self) -> str:
        """Allocate a new dynamic stride variable name."""
        name = f"s{self.num_dyn_stride_vars}"
        self.num_dyn_stride_vars += 1
        return name

    def alloc_or_reuse_symint_var(
        self, value: SymInt, name_alloc_func: Any
    ) -> spec.Var:
        """Allocate or reuse a symbolic integer variable."""
        sym_int_id = SymIntId(value)
        if sym_int_id in self.sym_int_id_mapping:
            return self.sym_int_id_mapping[sym_int_id]
        name = name_alloc_func()
        if value.width == 32:
            dtype = NumericToTVMFFIDtype[Int32]
        else:
            dtype = NumericToTVMFFIDtype[Int64]
        var = spec.Var(name, dtype, divisibility=value.divisibility)
        self.sym_int_id_mapping[sym_int_id] = var
        return var

    def alloc_or_reuse_device_id(
        self, device_type: str, vdevice_id: int
    ) -> Optional[spec.Var]:
        """Allocate or reuse a device_id variable for a given virtual device.

        This function returns None for CPU tensors.
        """
        # Don't allocate device_id for CPU tensors
        if device_type == "cpu":
            return None

        vdevice_key = (device_type, vdevice_id)
        if vdevice_key in self.vdevice_to_device_id_mapping:
            return self.vdevice_to_device_id_mapping[vdevice_key]

        name = f"device_id{self.num_device_id_vars}"
        self.num_device_id_vars += 1
        device_id_var = spec.Var(name, "int32")
        self.vdevice_to_device_id_mapping[vdevice_key] = device_id_var
        return device_id_var


def _shape_elem_to_spec(elem: Any, ctx: ConverterContext) -> Any:
    """Convert one element of a CuTe shape to its spec representation.

    Returns int (static constant), spec.Var (dynamic scalar), or spec.Shape
    (nested tuple that TVM FFI will see as an Array of ints).
    """
    if isinstance(elem, int):
        return elem
    elif isinstance(elem, SymInt):
        return ctx.alloc_or_reuse_symint_var(elem, ctx.alloc_shape_name)
    elif isinstance(elem, tuple):
        inner = [_shape_elem_to_spec(e, ctx) for e in elem]
        return spec.Shape(ctx.alloc_shape_name(), inner)
    elif isinstance(elem, Numeric):
        return spec.Var(ctx.alloc_shape_name(), _numeric_to_tvm_ffi_dtype(elem.dtype))
    else:
        raise DSLRuntimeError(f"Unexpected element type in cute shape: {type(elem)}")


def _convert_cute_shape_arg(
    arg: Any, arg_name: str, ctx: ConverterContext
) -> spec.Param:
    """Convert a CuTe shape/stride/coord argument to a spec.Param.

    Flat shapes map to spec.Shape. Nested shapes map to spec.TupleParam so
    the spec mirrors the TVM FFI Array structure TVM produces
    when the Python tuple is passed at runtime.
    """
    converted_elements = [_shape_elem_to_spec(e, ctx) for e in arg]
    has_nested = any(isinstance(e, tuple) for e in arg)
    if has_nested:
        return spec.TupleParam(arg_name, converted_elements)
    else:
        return spec.Shape(arg_name, converted_elements)


def _convert_single_arg(
    arg: Any,
    arg_name: str,
    arg_type: Any,
    ctx: ConverterContext,
    *,
    is_constexpr: bool = False,
) -> spec.Param:
    """Convert a single argument to a spec.Param.

    Parameters
    ----------
    arg : Any
        The argument value to convert.
    arg_name : str
        The name of the argument.
    arg_type : type
        The type annotation of the argument.
    ctx : ConverterContext
        The converter context for managing variable allocation.

    Returns
    -------
    spec.Param
        The converted parameter specification.

    When ``is_constexpr=True`` the arg is captured as a compile-time literal
    via a ``Const*`` param (asserted at runtime by the tvm-ffi wrapper, not
    forwarded into the llvm.call). Otherwise it takes the normal runtime
    path — e.g. a bare ``int`` becomes ``spec.Var(..., int32)``.
    """
    if is_constexpr:
        if arg is None:
            return spec.ConstNone(arg_name)
        # bool must be checked before int (bool is a subclass of int)
        if isinstance(arg, bool):
            return spec.ConstBool(arg_name, arg)
        if isinstance(arg, int):
            return spec.ConstInt(arg_name, arg)
        if isinstance(arg, float):
            return spec.ConstFloat(arg_name, arg)
        raise DSLRuntimeError(
            f"Unsupported Constexpr value for {arg_name!r}: {type(arg).__name__}. "
            f"Supported: None, int, bool, float."
        )
    if arg is None:
        return spec.ConstNone(arg_name)
    elif isinstance(arg, Numeric) and arg.dtype in AcceptableNumericTypesForScalar:
        param = spec.Var(
            arg_name,
            _numeric_to_tvm_ffi_dtype(arg.dtype),
            alternate_ir_type_fetch_func=AlternateIrTypeFunctions.get(arg.dtype, None),
        )
        return param
    elif arg_type in AcceptableNumericTypesForScalar:
        param = spec.Var(
            arg_name,
            _numeric_to_tvm_ffi_dtype(arg_type),
            alternate_ir_type_fetch_func=AlternateIrTypeFunctions.get(arg_type, None),
        )
        return param
    elif (native_struct_type := _native_struct_type(arg_type)) is not None or (
        native_struct_type := _native_struct_type(arg)
    ) is not None:
        param = spec.Var(arg_name, "handle")
        setattr(param, spec.NATIVE_STRUCT_TYPE_ATTR, native_struct_type)
        return param
    elif is_cute_algebra_type(arg_type):
        return _convert_cute_shape_arg(arg, arg_name, ctx)
    elif isinstance(arg, SymInt):
        if arg.width == 32:
            dtype = NumericToTVMFFIDtype[Int32]
        else:
            dtype = NumericToTVMFFIDtype[Int64]
        return spec.Var(arg_name, dtype, divisibility=arg.divisibility)
    elif isinstance(arg, Tensor):
        arg_shape = arg.shape
        arg_stride = arg.stride
        assert isinstance(arg_shape, tuple)
        assert isinstance(arg_stride, tuple)
        shapes: List[Any] = []
        for i, dyn_mask in enumerate(arg.dynamic_shapes_mask):
            if not dyn_mask:
                shapes.append(arg_shape[i])
            elif isinstance(arg_shape[i], SymInt):
                shapes.append(
                    ctx.alloc_or_reuse_symint_var(arg_shape[i], ctx.alloc_shape_name)  # type: ignore[arg-type]
                )
            else:
                shapes.append(
                    spec.Var(ctx.alloc_shape_name(), NumericToTVMFFIDtype[Int32])
                )
        strides: List[Any] = []

        for i, dyn_mask in enumerate(arg.dynamic_strides_mask):
            if not dyn_mask:
                strides.append(arg_stride[i])
            elif isinstance(arg_stride[i], SymInt):
                strides.append(
                    ctx.alloc_or_reuse_symint_var(arg_stride[i], ctx.alloc_stride_name)  # type: ignore[arg-type]
                )
            else:
                if hasattr(arg, "_use_32bit_stride") and arg._use_32bit_stride:
                    dtype = NumericToTVMFFIDtype[Int32]
                else:
                    dtype = NumericToTVMFFIDtype[Int64]
                strides.append(spec.Var(ctx.alloc_stride_name(), dtype))
        if hasattr(arg, "_tvm_ffi_tensor"):
            tvm_ffi_tensor = arg._tvm_ffi_tensor
            dtype = tvm_ffi_tensor.dtype
            device_type = tvm_ffi_tensor.device.type

            # Allocate device_id (returns None for CPU tensors)
            vdevice_id = tvm_ffi_tensor.device.index
            device_id = ctx.alloc_or_reuse_device_id(device_type, vdevice_id)

            tvm_ffi_cute_tensor = spec.Tensor(
                arg_name,
                shapes,
                arg._tvm_ffi_tensor.dtype,
                strides=strides,
                data_alignment=arg._assumed_align,  # type: ignore[attr-defined]
                device_type=device_type,
                device_id=device_id,
            )
        else:
            # for FakeTensor, strictly follow the shape and stride from the cute tensor
            device_type = "cuda" if _is_gpu_memspace(arg.memspace) else "cpu"
            # Allocate device_id (returns None for CPU tensors)
            vdevice_id = 0  # For now, use vdevice_id = 0 for all GPU tensors
            device_id = ctx.alloc_or_reuse_device_id(device_type, vdevice_id)

            tvm_ffi_cute_tensor = spec.Tensor(
                arg_name,
                shapes,
                _numeric_to_tvm_ffi_dtype(arg.element_type),
                strides=strides,
                data_alignment=arg._assumed_align,  # type: ignore[attr-defined]
                device_type=device_type,
                device_id=device_id,
            )
            if arg.element_type == Float4E2M1FN:
                tvm_ffi_cute_tensor = spec.create_map_tensor_dtype_f4x2_to_f4_spec(
                    tvm_ffi_cute_tensor
                )
        return tvm_ffi_cute_tensor
    elif isinstance(arg, Pointer) or arg_type == Pointer:
        address_space = None
        if hasattr(arg, "memspace"):
            address_space = _get_llvm_address_space_from_memspace(arg.memspace)
        return spec.DataPointer(arg_name, address_space=address_space)
    elif isinstance(arg, _FakeStream):
        if arg.use_tvm_ffi_env_stream:
            return spec.EnvStream(arg_name)
        else:
            return spec.Stream(arg_name)
    elif isinstance(arg, cuda.CUstream):
        return spec.Stream(arg_name)
    elif arg_type is not inspect.Parameter.empty and hasattr(arg_type, "_fields"):
        # Handle NamedTuple - normalize to Tuple by order of fields, ignoring defaults
        # Get field types from annotations
        type_hints = get_type_hints(arg_type)
        tuple_element_types = [type_hints[field] for field in arg_type._fields]

        # NamedTuples inherit from tuple, so we can check with isinstance(arg, tuple)
        if not isinstance(arg, tuple):
            raise DSLRuntimeError(
                f"Expected namedtuple for argument {arg_name}, got {type(arg)}"
            )
        if len(arg) != len(tuple_element_types):
            raise DSLRuntimeError(
                f"NamedTuple length mismatch for argument {arg_name}: "
                f"expected {len(tuple_element_types)}, got {len(arg)}"
            )

        # Recursively convert each tuple element
        tuple_params = []
        for i, (elem, elem_type) in enumerate(zip(arg, tuple_element_types)):
            elem_name = f"{arg_name}[{i}]"
            elem_param = _convert_single_arg(elem, elem_name, elem_type, ctx)
            tuple_params.append(elem_param)

        return spec.TupleParam(arg_name, tuple_params)
    elif arg_type is not inspect.Parameter.empty and get_origin(arg_type) is tuple:
        # Handle Tuple[X, Y, ...] type annotations
        tuple_element_types = get_args(arg_type)  # type: ignore[assignment]
        if not isinstance(arg, (tuple, list)):
            raise DSLRuntimeError(
                f"Expected tuple for argument {arg_name}, got {type(arg)}"
            )
        if len(arg) != len(tuple_element_types):
            raise DSLRuntimeError(
                f"Tuple length mismatch for argument {arg_name}: "
                f"expected {len(tuple_element_types)}, got {len(arg)}"
            )

        # Recursively convert each tuple element
        tuple_params = []
        for i, (elem, elem_type) in enumerate(zip(arg, tuple_element_types)):
            elem_name = f"{arg_name}[{i}]"
            elem_param = _convert_single_arg(elem, elem_name, elem_type, ctx)
            tuple_params.append(elem_param)

        return spec.TupleParam(arg_name, tuple_params)
    elif isinstance(arg, (tuple, list)):
        # Handle plain tuple type annotation without explicit element types
        # Recursively convert each tuple element with None as elem_type (un-annotated)
        tuple_params = []
        for i, elem in enumerate(arg):
            elem_name = f"{arg_name}[{i}]"
            elem_param = _convert_single_arg(elem, elem_name, None, ctx)
            tuple_params.append(elem_param)
        return spec.TupleParam(arg_name, tuple_params)
    elif isinstance(arg, bool):
        return spec.Var(arg_name, NumericToTVMFFIDtype[Boolean])
    elif isinstance(arg, int):
        # in cute.compile, unannotated const int is converted to int32
        return spec.Var(arg_name, NumericToTVMFFIDtype[Int32])
    elif isinstance(arg, float):
        return spec.Var(arg_name, NumericToTVMFFIDtype[Float32])
    elif (
        is_dataclass(arg_type)
        if (arg_type is not None and arg_type is not inspect.Parameter.empty)
        else is_dataclass(type(arg))
    ):
        dc_type = (
            arg_type
            if (
                arg_type is not None
                and arg_type is not inspect.Parameter.empty
                and is_dataclass(arg_type)
            )
            else type(arg)
        )
        if not isinstance(arg, dc_type):
            raise DSLRuntimeError(
                f"Expected {dc_type.__name__} for argument {arg_name}, got {type(arg)}"
            )
        # ``Constexpr[...]`` fields are captured as Const* literals (asserted
        # at runtime, not forwarded into the llvm.call); other fields take
        # the normal runtime path.
        tuple_params = [
            _convert_single_arg(
                getattr(arg, f.name),
                f"{arg_name}.{f.name}",
                f.type,
                ctx,
                is_constexpr=is_constexpr_field(f),
            )
            for f in dataclass_fields(dc_type)
        ]
        return spec.TupleParam(arg_name, tuple_params)
    elif arg_type is not None and (
        get_origin(arg_type) is UnionType or get_origin(arg_type) is Union
    ):
        member_types = get_args(arg_type)
        for member_type in member_types:
            try:
                return _convert_single_arg(arg, arg_name, member_type, ctx)
            except DSLRuntimeError:
                continue
        raise DSLRuntimeError(
            f"Unsupported argument type: {type(arg)} for union type: {arg_type}. "
            f"None of the union members matched: {member_types}"
        )
    else:
        raise DSLRuntimeError(
            f"Unsupported argument type: {type(arg)} for annotated type: {get_origin(arg_type)}"
        )


def _tvm_ffi_args_spec_converter(
    function_name: str,
    signature: inspect.Signature,
    full_args: List[Any],
    full_kwargs: Dict[str, Any],
) -> tuple[List[spec.Param], Any, List[str]]:
    """Convert cute algebra args to tvm ffi spec params.

    Returns
    -------
    (params, kwargs_wrapper_spec, map_dataclass_to_tuple)
        ``map_dataclass_to_tuple`` lists the top-level arg names whose values
        are dataclass instances. These must be unpacked to nested tuples via
        tvm-ffi's ``unpack_dataclass_to_tuple`` before the FFI call; the spec
        we just built already includes every field (with ``Const*`` for
        constexpr fields). This stays a tvm-ffi concern and intentionally
        lives outside ``KwargsWrapperSpec``.
    """
    exec_args = ExecutionArgs(signature, function_name)
    rectified_args = exec_args.get_rectified_args_from_original_args(
        full_args, full_kwargs
    )
    params = []
    ctx = ConverterContext()
    wrapper_extra_exclude_arg_names = []
    map_dataclass_to_tuple: List[str] = []

    for arg, parameter in zip(rectified_args, exec_args.signature.parameters.values()):
        arg_type = parameter.annotation
        arg_name = parameter.name
        param = _convert_single_arg(arg, arg_name, arg_type, ctx)
        params.append(param)
        if isinstance(param, spec.EnvStream):
            wrapper_extra_exclude_arg_names.append(arg_name)
        # Covers both plain ``op: AddOp`` and ``op: AddOp | MulOp`` since we
        # check the runtime type when the annotation isn't itself a dataclass.
        if (isinstance(arg_type, type) and is_dataclass(arg_type)) or is_dataclass(
            type(arg)
        ):
            map_dataclass_to_tuple.append(arg_name)
    kwargs_wrapper_spec = exec_args.get_kwargs_wrapper_spec(
        wrapper_extra_exclude_arg_names
    )
    return params, kwargs_wrapper_spec, map_dataclass_to_tuple


def attach_args_spec_converter(dsl: Any) -> None:
    """Attach TVM FFI ABI interface postprocessor to the DSL instance."""
    dsl._tvm_ffi_args_spec_converter = _tvm_ffi_args_spec_converter
