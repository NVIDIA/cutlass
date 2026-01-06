
#
# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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


"""
Copies of enum types from cutlass_library that are used in the fusion frontend.
"""

import enum
from enum import auto as enum_auto

import cutlass

from cutlass_api.utils import (
    is_numpy_available,
    is_numpy_tensor,
    is_torch_available,
    is_torch_tensor,
)


class DataType(enum.Enum):
    void = enum_auto()  # primarily used to disable C tensor for epilogues
    b1 = enum_auto()
    u2 = enum_auto()
    u4 = enum_auto()
    u8 = enum_auto()
    u16 = enum_auto()
    u32 = enum_auto()
    u64 = enum_auto()
    s2 = enum_auto()
    s4 = enum_auto()
    s8 = enum_auto()
    s16 = enum_auto()
    s32 = enum_auto()
    s64 = enum_auto()
    e4m3 = enum_auto()
    e5m2 = enum_auto()
    f8 = enum_auto()
    f6 = enum_auto()
    f4 = enum_auto()
    e3m2 = enum_auto()
    e2m3 = enum_auto()
    e2m1 = enum_auto()
    ue8m0 = enum_auto()
    ue4m3 = enum_auto()
    f16 = enum_auto()
    bf16 = enum_auto()
    f32 = enum_auto()
    tf32 = enum_auto()
    f64 = enum_auto()
    cf16 = enum_auto()
    cbf16 = enum_auto()
    cf32 = enum_auto()
    ctf32 = enum_auto()
    cf64 = enum_auto()
    cs2 = enum_auto()
    cs4 = enum_auto()
    cs8 = enum_auto()
    cs16 = enum_auto()
    cs32 = enum_auto()
    cs64 = enum_auto()
    cu2 = enum_auto()
    cu4 = enum_auto()
    cu8 = enum_auto()
    cu16 = enum_auto()
    cu32 = enum_auto()
    cu64 = enum_auto()
    invalid = enum_auto()


DataTypeSize = {
    DataType.void: 0,
    DataType.b1: 1,
    DataType.u2: 2,
    DataType.u4: 4,
    DataType.u8: 8,
    DataType.u16: 16,
    DataType.u32: 32,
    DataType.u64: 64,
    DataType.s2: 2,
    DataType.s4: 4,
    DataType.s8: 8,
    DataType.s16: 16,
    DataType.s32: 32,
    DataType.s64: 64,
    DataType.e4m3: 8,
    DataType.e5m2: 8,
    DataType.f8: 8,
    DataType.f6: 6,
    DataType.f4: 4,
    DataType.e2m3: 6,
    DataType.e3m2: 6,
    DataType.e2m1: 4,
    DataType.ue8m0: 8,
    DataType.ue4m3: 8,
    DataType.f16: 16,
    DataType.bf16: 16,
    DataType.f32: 32,
    DataType.tf32: 32,
    DataType.f64: 64,
    DataType.cf16: 32,
    DataType.cbf16: 32,
    DataType.cf32: 64,
    DataType.ctf32: 32,
    DataType.cf64: 128,
    DataType.cu2: 4,
    DataType.cu4: 8,
    DataType.cu8: 16,
    DataType.cu16: 32,
    DataType.cu32: 64,
    DataType.cu64: 128,
    DataType.cs2: 4,
    DataType.cs4: 8,
    DataType.cs8: 16,
    DataType.cs16: 32,
    DataType.cs32: 64,
    DataType.cs64: 128,
}


class LayoutType(enum.Enum):
    ColumnMajor = enum_auto()
    RowMajor = enum_auto()
    ColumnMajorInterleaved2 = enum_auto()
    RowMajorInterleaved2 = enum_auto()
    ColumnMajorInterleaved32 = enum_auto()
    RowMajorInterleaved32 = enum_auto()
    ColumnMajorInterleaved64 = enum_auto()
    RowMajorInterleaved64 = enum_auto()
    TensorNWC = enum_auto()
    TensorNHWC = enum_auto()
    TensorNDHWC = enum_auto()
    TensorNCHW = enum_auto()
    TensorNGHWC = enum_auto()
    TensorNC32HW32 = enum_auto()
    TensorNC64HW64 = enum_auto()
    TensorC32RSK32 = enum_auto()
    TensorC64RSK64 = enum_auto()
    TensorKCS = enum_auto()
    TensorKCSR = enum_auto()
    TensorKCSRT = enum_auto()


class EpilogueScheduleType(enum.Enum):
    ScheduleAuto = enum_auto()
    EpilogueTransposed = enum_auto()
    NoSmemWarpSpecialized = enum_auto()
    PtrArrayNoSmemWarpSpecialized = enum_auto()
    NoSmemWarpSpecialized1Sm = enum_auto()
    NoSmemWarpSpecialized2Sm = enum_auto()
    FastF32NoSmemWarpSpecialized1Sm = enum_auto()
    FastF32NoSmemWarpSpecialized2Sm = enum_auto()
    BlockwiseNoSmemWarpSpecialized1Sm = enum_auto()
    BlockwiseNoSmemWarpSpecialized2Sm = enum_auto()
    PtrArrayNoSmemWarpSpecialized1Sm = enum_auto()
    PtrArrayNoSmemWarpSpecialized2Sm = enum_auto()
    PtrArrayFastF32NoSmemWarpSpecialized1Sm = enum_auto()
    PtrArrayFastF32NoSmemWarpSpecialized2Sm = enum_auto()
    PtrArrayBlockwiseNoSmemWarpSpecialized1Sm = enum_auto()
    PtrArrayBlockwiseNoSmemWarpSpecialized2Sm = enum_auto()
    TmaWarpSpecialized = enum_auto()
    TmaWarpSpecializedCooperative = enum_auto()
    TmaWarpSpecialized1Sm = enum_auto()
    TmaWarpSpecialized2Sm = enum_auto()
    PtrArrayTmaWarpSpecialized1Sm = enum_auto()
    PtrArrayTmaWarpSpecialized2Sm = enum_auto()
    PtrArrayTmaWarpSpecializedPingpong = enum_auto()
    PtrArrayTmaWarpSpecializedCooperative = enum_auto()
    TmaWarpSpecialized1SmNvf4 = enum_auto()
    TmaWarpSpecialized2SmNvf4 = enum_auto()
    TmaWarpSpecialized1SmMxf4 = enum_auto()
    TmaWarpSpecialized2SmMxf4 = enum_auto()
    TmaWarpSpecialized1SmMxf8f6f4 = enum_auto()
    TmaWarpSpecialized2SmMxf8f6f4 = enum_auto()
    SparseTmaWarpSpecializedCooperativeSm120 = enum_auto()


class ActivationOp(enum.Enum):
    DGelu = enum_auto()
    Gelu = enum_auto()
    GeluTaylor = enum_auto()
    HardSwish = enum_auto()
    Identity = enum_auto()
    LeakyReLU = enum_auto()
    ReLU = enum_auto()
    Sigmoid = enum_auto()
    SiLU = enum_auto()
    Tanh = enum_auto()


ActivationOpTag = {
    ActivationOp.DGelu: "cutlass::epilogue::thread::dGELU",
    ActivationOp.Gelu: "cutlass::epilogue::thread::GELU",
    ActivationOp.GeluTaylor: "cutlass::epilogue::thread::GELU_taylor",
    ActivationOp.HardSwish: "cutlass::epilogue::thread::HardSwish",
    ActivationOp.Identity: "cutlass::epilogue::thread::Identity",
    ActivationOp.LeakyReLU: "cutlass::epilogue::thread::LeakyReLU",
    ActivationOp.ReLU: "cutlass::epilogue::thread::ReLu",
    ActivationOp.Sigmoid: "cutlass::epilogue::thread::Sigmoid",
    ActivationOp.SiLU: "cutlass::epilogue::thread::SiLu",
    ActivationOp.Tanh: "cutlass::epilogue::thread::Tanh",
}


class FloatRoundStyle(enum.Enum):
    ToNearest = enum_auto()
    ToNearestSatfinite = enum_auto()
    Indeterminate = enum_auto()
    TowardZero = enum_auto()
    TowardInfinity = enum_auto()
    TowardNegInfinity = enum_auto()
    HalfUlpTruncDntz = enum_auto()
    HalfUlpTruncate = enum_auto()


class FunctionalOp(enum.Enum):
    AtomicAdd = enum_auto()
    AtomicMaximum = enum_auto()
    Divides = enum_auto()
    Maximum = enum_auto()
    Minimum = enum_auto()
    Minus = enum_auto()
    Multiplies = enum_auto()
    MultiplyAdd = enum_auto()
    Plus = enum_auto()
    Exp = enum_auto()


FunctionalOpTag = {
    FunctionalOp.AtomicAdd: "cutlass::atomic_add",
    FunctionalOp.AtomicMaximum: "cutlass::atomic_maximum",
    FunctionalOp.Divides: "cutlass::divides",
    FunctionalOp.Maximum: "cutlass::maximum",
    FunctionalOp.Minimum: "cutlass::minimum",
    FunctionalOp.Minus: "cutlass::minus",
    FunctionalOp.Multiplies: "cutlass::multiplies",
    FunctionalOp.MultiplyAdd: "cutlass::multiply_add",
    FunctionalOp.Plus: "cutlass::plus",
    FunctionalOp.Exp: "cutlass::fast_exp_op",
}


def op_tag(op) -> str:
    """
    Dispatches `op` to the appropriate *Tag dictionary depending on whether
    `op` is an ActivationOp or FunctionalOp. This is useful for cases in which
    either type can be used.

    :param op: operation to emit a tag for
    :type op: ActivationOp | FunctionalOp

    :return: tag corresponding to op
    :rtype: str
    """
    if isinstance(op, ActivationOp):
        return ActivationOpTag[op]
    elif isinstance(op, FunctionalOp):
        return FunctionalOpTag[op]
    else:
        raise Exception(
            f"Unexpected op type {op}. Must be one of ActivationOp or FunctionalOp."
        )


# The current EVT frontend also contains code needed for emitting C++ EVTs.
# C++ emission is not currently supported by cutlass_api, but we still
# need many of the utilities surrounding it. These utilities make use of dictionaries
# from cutlass_library types to strings containing C++ code. We define placeholders
# for empty versions of these dictionaries that raise an error if they are used.
class _UnimplementedDict:
    def __init__(self, name):
        self.name = name

    def __getitem__(self, key):
        raise NotImplementedError(
            f"Dictionary {self.name} is not implemented. This code path should not have been reafched."
        )


DataTypeTag = _UnimplementedDict("DataTypeTag")
EpilogueScheduleTag = _UnimplementedDict("EpilogueScheduleTag")
FloatRoundStyleTag = _UnimplementedDict("FloatRoundStyleTag")
KernelScheduleSuffixes = _UnimplementedDict("KernelScheduleSuffixes")
OpcodeClassTag = _UnimplementedDict("OpcodeClassTag")


_torch_to_library_dict = None
if is_torch_available():
    import torch

    _torch_to_library_dict = {
        torch.half: DataType.f16,
        torch.float16: DataType.f16,
        torch.bfloat16: DataType.bf16,
        torch.float: DataType.f32,
        torch.float32: DataType.f32,
    }


def _tensor_from_numpy(np_tensor) -> tuple[DataType, LayoutType]:
    dtype = library_type(np_tensor.dtype)
    if np_tensor.flags.c_contiguous:
        layout = LayoutType.RowMajor
    elif np_tensor.flags.f_contiguous:
        layout = LayoutType.ColumnMajor
    return (dtype, layout)


def _tensor_from_torch(pt_tensor):
    dtype = library_type(pt_tensor.dtype)
    return (dtype, LayoutType.RowMajor)


def torch_library_type(inp) -> DataType:
    if _torch_to_library_dict is None:
        return None
    return _torch_to_library_dict.get(inp, None)


def numpy_library_type(inp) -> DataType:
    if is_numpy_available():
        import numpy as np

        if inp == np.float16:
            return DataType.f16
        elif inp == np.float32:
            return DataType.f32
        elif inp == np.float64:
            return DataType.f64
        elif inp == np.int8:
            return DataType.s8
        elif inp == np.int32:
            return DataType.s32
    return None


def cutlass_library_type(inp: cutlass.Numeric) -> DataType:
    if inp == cutlass.Float32:
        return DataType.f32
    elif inp == cutlass.Float16:
        return DataType.f16
    elif inp == cutlass.BFloat16:
        return DataType.bf16
    elif inp == cutlass.Int32:
        return DataType.s32
    elif inp == cutlass.Int8:
        return DataType.s8
    elif inp == cutlass.Uint8:
        return DataType.u8
    elif inp == cutlass.Uint16:
        return DataType.u16
    elif inp == cutlass.Uint32:
        return DataType.u32
    elif inp == cutlass.Uint64:
        return DataType.u64
    elif inp == cutlass.Int16:
        return DataType.s16
    elif inp == cutlass.Int64:
        return DataType.s64
    elif inp == cutlass.Float8E5M2:
        return DataType.e5m2
    elif inp == cutlass.Float8E4M3FN:
        return DataType.e4m3
    else:
        return None


def library_type(inp):
    if inp in DataTypeSize:
        return inp

    for cvt_fn in [
        numpy_library_type,
        torch_library_type,
        cutlass_library_type,
    ]:
        out = cvt_fn(inp)
        if out is not None:
            return out

    raise ValueError(f"No available conversion from type {inp} to a library type.")


def get_datatype_and_layout(tensor) -> tuple[DataType, LayoutType]:
    if is_numpy_tensor(tensor):
        return _tensor_from_numpy(tensor)
    elif is_torch_tensor(tensor):
        return _tensor_from_torch(tensor)
    elif isinstance(tensor, float) or isinstance(tensor, int):
        return (DataType.f32, LayoutType.RowMajor)
    else:
        raise Exception(
            f"Unable to convert tensor of type {type(tensor)} to Python-bound CUTLASS datatype and layout."
        )


def get_tensor_shape(tensor, op="GEMM") -> tuple:
    if is_numpy_tensor(tensor):
        return tensor.shape
    elif is_torch_tensor(tensor):
        size = tensor.size()
        if op == "CONV":
            # PyTorch Tensors have shape NCHW
            return (size[0], size[2], size[3], size[1])
        else:
            return tuple(tensor.size())
    elif isinstance(tensor, float) or isinstance(tensor, int):
        return (1,)
    else:
        raise Exception(
            f"Unable to convert tensor of type {type(tensor)} to Python-bound CUTLASS datatype and layout."
        )
