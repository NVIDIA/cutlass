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

from cutlass.base_dsl.tvm_ffi_builder import spec
from cutlass.base_dsl.jit_executor import ExecutionArgs
from cutlass.base_dsl.common import DSLRuntimeError
from cutlass.cutlass_dsl import is_cute_algebra_type
from cutlass._mlir.dialects import cute as _cute_ir
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
)
import cuda.bindings.driver as cuda

from typing import List, Dict, Any, Optional, Tuple, get_origin, get_args
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
    Float32,
    Float64,
]


def _get_llvm_address_space_from_memspace(
    memspace: _cute_ir.AddressSpace,
) -> Optional[int]:
    if memspace == _cute_ir.AddressSpace.gmem:
        return 1
    return None

def _is_gpu_memspace(
    memspace: _cute_ir.AddressSpace,
) -> bool:
    return memspace != _cute_ir.AddressSpace.generic


class SymIntId:
    def __init__(self, sym_int: SymInt):
        self.sym_int = sym_int

    def __hash__(self):
        return id(self.sym_int)

    def __eq__(self, other) -> bool:
        return self.sym_int is other.sym_int



class ConverterContext:
    """Context for managing variable allocation during TVM FFI args conversion."""

    def __init__(self):
        self.num_dyn_shape_vars = 0
        self.num_dyn_stride_vars = 0
        self.sym_int_id_mapping = {}

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

    def alloc_or_reuse_symint_var(self, value: SymInt, name_alloc_func):
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


def _convert_single_arg(
    arg,
    arg_name: str,
    arg_type,
    ctx: ConverterContext
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
    """
    if arg is None:
        return spec.ConstNone(arg_name)
    elif (isinstance(arg, Numeric) and arg.dtype in AcceptableNumericTypesForScalar):
        return spec.Var(arg_name, NumericToTVMFFIDtype[arg.dtype])
    elif arg_type in AcceptableNumericTypesForScalar:
        return spec.Var(arg_name, NumericToTVMFFIDtype[arg_type])
    elif is_cute_algebra_type(arg_type):
        shape = []
        for i in range(len(arg)):
            if isinstance(arg[i], int):
                shape.append(arg[i])
            elif isinstance(arg[i], SymInt):
                shape.append(ctx.alloc_or_reuse_symint_var(arg[i], ctx.alloc_shape_name))
            else:
                shape.append(spec.Var(ctx.alloc_shape_name(), NumericToTVMFFIDtype[arg[i].dtype]))
        return spec.Shape(arg_name, shape)
    elif isinstance(arg, Tensor):
        shapes = []
        for i, dyn_mask in enumerate(arg.dynamic_shapes_mask):
            if not dyn_mask:
                shapes.append(arg.shape[i])
            elif isinstance(arg.shape[i], SymInt):
                shapes.append(ctx.alloc_or_reuse_symint_var(arg.shape[i], ctx.alloc_shape_name))
            else:
                shapes.append(spec.Var(ctx.alloc_shape_name(), NumericToTVMFFIDtype[Int32]))
        strides = []

        for i, dyn_mask in enumerate(arg.dynamic_strides_mask):
            if not dyn_mask:
                strides.append(arg.stride[i])
            elif isinstance(arg.stride[i], SymInt):
                strides.append(ctx.alloc_or_reuse_symint_var(arg.stride[i], ctx.alloc_stride_name))
            else:
                if hasattr(arg, "_use_32bit_stride") and arg._use_32bit_stride:
                    dtype = NumericToTVMFFIDtype[Int32]
                else:
                    dtype = NumericToTVMFFIDtype[Int64]
                strides.append(spec.Var(ctx.alloc_stride_name(), dtype))
        if hasattr(arg, "_tvm_ffi_tensor"):
            tvm_ffi_tensor = arg._tvm_ffi_tensor
            dtype = tvm_ffi_tensor.dtype
            tvm_ffi_cute_tensor = spec.Tensor(
                arg_name,
                shapes,
                arg._tvm_ffi_tensor.dtype,
                strides=strides,
                data_alignment=arg._assumed_align,
                device_type=tvm_ffi_tensor.device.type
            )
        else:
            # for FakeTensor, strictly follow the shape and stride from the cute tensor
            device_type = "cuda" if _is_gpu_memspace(arg.memspace) else "cpu"
            tvm_ffi_cute_tensor = spec.Tensor(
                arg_name,
                shapes,
                NumericToTVMFFIDtype[arg.element_type],
                strides=strides,
                data_alignment=arg._assumed_align,
                device_type=device_type,
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
    elif arg_type is not None and get_origin(arg_type) is tuple:
        # Handle Tuple[X, Y, ...] type annotations
        tuple_element_types = get_args(arg_type)
        if not isinstance(arg, (tuple, list)):
            raise DSLRuntimeError(f"Expected tuple for argument {arg_name}, got {type(arg)}")
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
    else:
        raise DSLRuntimeError(f"Unsupported argument type: {type(arg)}")


def _tvm_ffi_args_spec_converter(
    function_name: str,
    args_spec: inspect.FullArgSpec,
    full_args: List[Any],
    full_kwargs: Dict[str, Any],
):
    """Convert cute algebra args to tvm ffi spec params.

    This function converts the cute arguments specs to tvm ffi spec params.
    """
    exec_args = ExecutionArgs(args_spec, function_name)
    rectified_args = exec_args.get_rectified_args_from_original_args(full_args, full_kwargs)
    arg_names = exec_args.args_spec.args + exec_args.args_spec.kwonlyargs
    params = []
    ctx = ConverterContext()

    for arg, arg_name in zip(rectified_args, arg_names):
        arg_type = args_spec.annotations.get(arg_name, None)
        param = _convert_single_arg(arg, arg_name, arg_type, ctx)
        params.append(param)

    return params


def attach_args_spec_converter():
    """Attach TVM FFI ABI interface postprocessor to the DSL."""
    from .. import cutlass_dsl as _dsl

    _dsl.CuTeDSL._get_dsl()._tvm_ffi_args_spec_converter = _tvm_ffi_args_spec_converter
