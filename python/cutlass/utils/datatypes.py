#################################################################################################
#
# Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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
#
#################################################################################################

"""
Utility functions for converting between frontend datatypes and CUTLASS datatypes
"""

import cutlass_bindings

import cutlass
from cutlass.backend.library import (
    DataTypeSize,
    MathInstruction,
    MathOperation,
    ShortLayoutTypeNames,
    TileDescription,
)

try:
    import numpy as np

    numpy_available = True
    _library_to_numpy_dict = {
        cutlass.DataType.f16: np.float16,
        cutlass.DataType.f32: np.float32,
        cutlass.DataType.f64: np.float64,
        cutlass.DataType.s8: np.int8,
        cutlass.DataType.s32: np.int32,
    }
except ImportError:
    numpy_available = False
    _library_to_numpy_dict = {}


def numpy_library_type(inp) -> cutlass.DataType:
    if numpy_available:
        if inp == np.float16:
            return cutlass.DataType.f16
        elif inp == np.float32:
            return cutlass.DataType.f32
        elif inp == np.float64:
            return cutlass.DataType.f64
        elif inp == np.int8:
            return cutlass.DataType.s8
        elif inp == np.int32:
            return cutlass.DataType.s32
    return None


def numpy_type(inp):
    return _library_to_numpy_dict.get(inp, None)


try:
    import cupy as cp

    cupy_available = True
    _library_to_cupy_dict = {
        cutlass.DataType.f16: cp.float16,
        cutlass.DataType.f32: cp.float32,
        cutlass.DataType.f64: cp.float64,
        cutlass.DataType.s8: cp.int8,
        cutlass.DataType.s32: cp.int32,
    }
except ImportError:
    cupy_available = False
    _library_to_cupy_dict = {}


def cupy_library_type(inp) -> cutlass.DataType:
    if cupy_available:
        if inp == cp.float16:
            return cutlass.DataType.f16
        elif inp == cp.float32:
            return cutlass.DataType.f32
        elif inp == cp.float64:
            return cutlass.DataType.f64
    return None


def cupy_type(inp):
    return _library_to_cupy_dict.get(inp, None)


try:
    import torch

    torch_available = True
    _torch_to_library_dict = {
        torch.half: cutlass.DataType.f16,
        torch.float16: cutlass.DataType.f16,
        torch.bfloat16: cutlass.DataType.bf16,
        torch.float: cutlass.DataType.f32,
        torch.float32: cutlass.DataType.f32,
        torch.double: cutlass.DataType.f64,
        torch.float64: cutlass.DataType.f64,
    }

    _library_to_torch_dict = {
        cutlass.DataType.f16: torch.half,
        cutlass.DataType.f16: torch.float16,
        cutlass.DataType.bf16: torch.bfloat16,
        cutlass.DataType.f32: torch.float,
        cutlass.DataType.f32: torch.float32,
        cutlass.DataType.f64: torch.double,
        cutlass.DataType.f64: torch.float64,
    }
except ImportError:
    torch_available = False
    _torch_to_library_dict = {}
    _library_to_torch_dict = {}


def torch_library_type(inp) -> cutlass.DataType:
    return _torch_to_library_dict.get(inp, None)


def torch_type(inp):
    return _library_to_torch_dict.get(inp, None)


try:
    import bfloat16

    bfloat16_available = True
except ImportError:
    bfloat16_available = False


def bfloat16_library_type(inp) -> cutlass.DataType:
    if bfloat16_available:
        if inp == bfloat16.bfloat16:
            return cutlass.DataType.bf16


def bfloat16_type(inp) -> bfloat16.bfloat16:
    if bfloat16_available:
        if inp == cutlass.DataType.bf16:
            return bfloat16.bfloat16


# Mapping from library data type to Python-bound CUTLASS data type
library_to_binding_dict = {
    cutlass.DataType.s8: cutlass_bindings.int8,
    cutlass.DataType.s32: cutlass_bindings.int32,
    cutlass.DataType.f16: cutlass_bindings.float16,
    cutlass.DataType.bf16: cutlass_bindings.bfloat16,
    cutlass.DataType.f32: cutlass_bindings.float32,
    cutlass.DataType.f64: cutlass_bindings.float64,
    cutlass.DataType.tf32: cutlass_bindings.tfloat32,
}

# Mapping from Python-bound CUTLASS data type to library data type
binding_to_library = {
    cutlass_bindings.int8: cutlass.DataType.s8,
    cutlass_bindings.int32: cutlass.DataType.s32,
    cutlass_bindings.float16: cutlass.DataType.f16,
    cutlass_bindings.bfloat16: cutlass.DataType.bf16,
    cutlass_bindings.float32: cutlass.DataType.f32,
    cutlass_bindings.float64: cutlass.DataType.f64,
    cutlass_bindings.tfloat32: cutlass.DataType.tf32,
}


def binding_library_type(inp):
    if inp in binding_to_library:
        return binding_to_library[inp]
    return None


def has_binding_type(inp: cutlass.DataType):
    return inp in library_to_binding_dict


def library_to_binding(inp: cutlass.DataType):
    if not has_binding_type(inp):
        raise Exception(f"No available conversion from library type {inp} to Python-bound CUTLASS type")
    return library_to_binding_dict[inp]


def library_type(inp):
    if inp in cutlass.DataTypeSize.keys():
        return inp

    for cvt_fn in [
        bfloat16_library_type,
        cupy_library_type,
        numpy_library_type,
        torch_library_type,
        binding_library_type,
    ]:
        out = cvt_fn(inp)
        if out is not None:
            return out

    raise Exception(f"No available conversion from type {inp} to a library type.")


def library_layout(layout):
    if layout in cutlass.LayoutTag.keys():
        return layout

    # Convert Python-bound CUTLASS layout to profiler library layout
    if layout == cutlass_bindings.RowMajor:
        return cutlass.LayoutType.RowMajor
    elif layout == cutlass_bindings.ColumnMajor:
        return cutlass.LayoutType.ColumnMajor
    elif layout == cutlass_bindings.TensorNHWC:
        return cutlass.LayoutType.TensorNHWC
    else:
        raise Exception(f"No conversion available for layout {layout} to library layout.")


def binding_type(inp):
    if inp in DataTypeSize.keys():
        return inp

    libtype = library_type(inp)
    return library_to_binding(libtype)


def binding_layout(layout):
    if layout in ShortLayoutTypeNames.keys():
        return layout
    elif layout == cutlass.LayoutType.RowMajor:
        return cutlass_bindings.RowMajor
    elif layout == cutlass.LayoutType.ColumnMajor:
        return cutlass_bindings.ColumnMajor
    elif layout == cutlass.LayoutType.TensorNHWC:
        return cutlass_bindings.TensorNHWC
    else:
        raise Exception(f"No conversion available for layout {layout} to Python-bound CUTLASS layout.")


def _tensor_from_numpy(np_tensor):
    dtype = library_type(np_tensor.dtype)
    if np_tensor.flags.c_contiguous:
        layout = cutlass.LayoutType.RowMajor
    elif np_tensor.flags.f_contiguous:
        layout = cutlass.LayoutType.ColumnMajor
    return (dtype, layout)


def _tensor_from_torch(pt_tensor):
    dtype = library_type(pt_tensor.dtype)
    return (dtype, cutlass.LayoutType.RowMajor)


def get_datatype_and_layout(tensor):
    if (numpy_available and isinstance(tensor, np.ndarray)) or (
        cupy_available and isinstance(tensor, cp.ndarray)
    ):
        return _tensor_from_numpy(tensor)
    elif torch_available and isinstance(tensor, torch.Tensor):
        return _tensor_from_torch(tensor)
    else:
        raise Exception(f"Unable to convert tensor of type {type(tensor)} to Python-bound CUTLASS datatype and layout.")

def get_tensor_shape(tensor):
    if (numpy_available and isinstance(tensor, np.ndarray)) or (
        cupy_available and isinstance(tensor, cp.ndarray)
    ):
        return tensor.shape
    elif torch_available and isinstance(tensor, torch.Tensor):
        size = tensor.size()
        return (size[0], size[2], size[3], size[1])
    else:
        raise Exception(f"Unable to convert tensor of type {type(tensor)} to Python-bound CUTLASS datatype and layout.")

def binding_opclass(opclass: cutlass.OpcodeClass):
    if opclass == cutlass.OpcodeClass.TensorOp:
        return cutlass_bindings.OpClass.TensorOp
    elif opclass == cutlass.OpcodeClass.Simt:
        return cutlass_bindings.OpClass.Simt
    else:
        raise Exception(f"Unable to convert opcode class of type {opclass} to Python-bound CUTLASS opcode class.")


_math_operation_value_map = {x.value: x for x in MathOperation}


def backend_math_operation(math_op: cutlass.MathOperation):
    if math_op.value not in _math_operation_value_map.keys():
        raise Exception(f"Unable to convert math operation of type {math_op} to backend math operation.")
    return _math_operation_value_map[math_op.value]


def construct_backend_td(td: cutlass.TileDescription,
                         kernel_schedule: cutlass.KernelScheduleType,
                         epilogue_schedule: cutlass.EpilogueScheduleType,
                         tile_scheduler: cutlass.TileSchedulerType) -> TileDescription:
    mi = td.math_instruction
    backend_mi = MathInstruction(
        mi.instruction_shape,
        binding_type(mi.element_a),
        binding_type(mi.element_b),
        binding_type(mi.element_accumulator),
        binding_opclass(mi.opcode_class),
        backend_math_operation(mi.math_operation)
    )
    cluster_shape = td.cluster_shape if hasattr(td, "cluster_shape") else [1, 1, 1]
    return TileDescription(td.threadblock_shape, td.stages, td.warp_count,
                           backend_mi, cluster_shape, kernel_schedule, epilogue_schedule, tile_scheduler)


def td_from_profiler_op(op) -> TileDescription:
    """
    Converts the profiler's TileDescription in ``op`` into the backend TileDescription

    :param op: profiler Operation

    :returns: backend TileDescription
    :rtype: cutlass.backend.TileDescription
    """
    kschedule = op.kernel_schedule if hasattr(op, 'kernel_schedule') else None
    eschedule = op.epilogue_schedule if hasattr(op, 'epilogue_schedule') else None
    tschedule = op.tile_scheduler if hasattr(op, 'tile_scheduler') else None
    return construct_backend_td(op.tile_description, kschedule, eschedule, tschedule)


def td_from_profiler_td(td: cutlass.backend.TileDescription) -> TileDescription:
    """
    Converts the profiler's TileDescription into the backend TileDescription

    :param td: profiler TileDescription
    :type td: cutlass.TileDescription

    :returns: backend TileDescription
    :rtype: cutlass.backend.TileDescription
    """
    return construct_backend_td(td, kernel_schedule=None, epilogue_schedule=None, tile_scheduler=None)

def to_camel_case(snake_str):
    return "".join(x.capitalize() for x in snake_str.lower().split("_"))


def getattr_enum(obj, attr_name):
    # The attr_name is under the snake_case
    camel_attr = to_camel_case(attr_name)
    if hasattr(obj, camel_attr):
        return getattr(obj, camel_attr)
    else:
        raise Exception(f"Invalid option: {attr_name}")
