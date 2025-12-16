#################################################################################################
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
#################################################################################################

import ctypes

from cutlass_api.fusion.library import DataType
from cutlass_api.utils import is_numpy_tensor, is_torch_tensor, is_numpy_available


dtype2ctype = {
    DataType.f16: ctypes.c_uint16,
    DataType.bf16: ctypes.c_uint16,
    DataType.f32: ctypes.c_float,
    DataType.f64: ctypes.c_double,
    DataType.s8: ctypes.c_int8,
    DataType.s32: ctypes.c_int32,
}


def get_scalar(value):
    """
    Returns a scalar value from a container (e.g., np.ndarray)
    """
    if is_numpy_tensor(value) or is_torch_tensor(value):
        if value.size != 1:
            raise Exception("Scalars used in epilogue must be of size 1")
        return value.reshape(-1)[0]
    else:
        return value


def to_ctype_value(value, dtype):
    """
    Converts ``value`` to the corresponding storage needed for the ctype that
    will store ``value``.
    """
    scalar = get_scalar(value)
    if dtype == DataType.f16:
        if is_numpy_available():
            import numpy as np

            # Convert f16 value into an integer
            return int.from_bytes(np.float16(scalar).tobytes(), "little")
        else:
            raise NotImplementedError("Numpy is not available")
    else:
        return scalar



class Empty(ctypes.Structure):
    _fields_ = []

    def __init__(self, *arg) -> None:
        pass


class EmptyByte(ctypes.Structure):
    _fields_ = [("byte", ctypes.c_byte)]

    def __init__(self, *arg) -> None:
        pass


class EBO:
    def __init__(self, index: int, type) -> None:
        self.index = index
        self.type = type

    def __eq__(self, other) -> bool:
        if isinstance(other, EBO):
            return self.index == other.index and self.type == other.type
        return False

    def __hash__(self) -> int:
        return hash((self.index, self.type))

    def __ne__(self, other):
        return not self.__eq__(other)

    def __str__(self) -> str:
        return f"<{self.index}, {self.type}>"


def tuple_factory_(input_tuple, dtype, constants: list[int] = None):
    """
    The factory function generating cute::Tuple with input tuple
    :param input_tuple: the input tuple
    :type input_tuple: tuple
    :param dtype: the data type for non-constant values
    :type dtype: str, "int32_t", "int", "int64_t"
    :param constant: the values that will be treated as constants
    :type constant: list[int]

    :return: ctype structure representing the cute::Tuple
    :return: the empty base classes of the tuple
    """

    if constants is None:
        constants = [0, 1]

    # The empty base classes of the current tuple
    empty_bases = []
    # The first non empty base class
    first_non_empty_base = None
    # The ctype fields of the current tuple
    ctype_fields = []

    for idx, entry in enumerate(input_tuple):
        # For nested tuples
        if isinstance(entry, tuple):
            sub_tuple_ctype, sub_empty_bases = tuple_factory_(entry, dtype, constants)
            if ctypes.sizeof(sub_tuple_ctype) == 0:
                # The empty tuple base class is also an empty EBO
                empty_bases.append(EBO(idx, entry))
            else:
                if first_non_empty_base is None:
                    first_non_empty_base = sub_empty_bases
            ctype_fields.append((f"entry_{idx}", sub_tuple_ctype))
        else:
            if entry in constants:
                empty_bases.append(EBO(idx, entry))
                ctype_fields.append((f"entry_{idx}", Empty))
            else:
                ctype_fields.append((f"entry_{idx}", dtype))
                if first_non_empty_base is None:
                    first_non_empty_base = []

    # Create the ctype tuple
    class TupleType(ctypes.Structure):
        _fields_ = ctype_fields

        def __init__(self, args) -> None:
            fields = self._fields_

            assert len(fields) == len(args)
            for field, arg in zip(fields, args):
                name = field[0]
                field_type = field[1]
                setattr(self, name, field_type(arg))

    return TupleType, empty_bases


def tuple_factory(input_tuple, dtype: str, constants=[0, 1]):
    """
    The factory function generating cute::Tuple with input tuple
    :param input_tuple: the input tuple
    :type input_tuple: tuple
    :param dtype: the data type for non-constant values
    :type dtype: str, "int32_t", "int", "int64_t"
    :param constant: the values that will be treated as constants
    :type constant: list[int]

    :return: ctype structure representing the cute::Tuple
    :return: the empty base classes of the tuple
    """
    # Step 1: convert the dtype
    if dtype == "int64_t":
        dtype = ctypes.c_longlong
    elif dtype in ["int", "int32_t"]:
        dtype = ctypes.c_int32
    else:
        raise NotImplementedError(f"Type {dtype} is not supported")

    tuple_type, _ = tuple_factory_(input_tuple, dtype, constants)

    if ctypes.sizeof(tuple_type) == 0:
        return EmptyByte
    return tuple_type


def visitor_factory(node_types, node_names):
    """
    Creates the argument type of epilogue visitor type

    :param node_types: list of argument types under ctypes
    :param node_names: list of argument names under str

    :return: tuple type in ctypes.Structure
    """
    ctypes_field = []
    # Struct is used when number of nodes < 4
    # Because the Sm90VisitorImplBase has specification up to 4 nodes
    # in `include/cutlass/epilogue/fusion/sm90_visitor_tma_warpspecialized.hpp`
    if len(node_types) <= 4:
        for idx, node_type in enumerate(node_types):
            if ctypes.sizeof(node_type) == 0:
                # Special case for empty struct
                # 1 byte placeholder is used for correct alignment
                ctypes_field.append((node_names[idx], ctypes.c_byte))
            else:
                ctypes_field.append((node_names[idx], node_type))

        class VisitorType(ctypes.Structure):
            _fields_ = ctypes_field

            def __init__(self, kwargs) -> None:
                for field in self._fields_:
                    fname, ftype = field
                    if ftype != ctypes.c_byte:
                        setattr(self, fname, ftype(kwargs))

    # For cases with more than 4 nodes, tuple is used
    else:
        for idx, node_type in enumerate(node_types):
            ctypes_field.append((node_names[idx], node_type))

        class VisitorType(ctypes.Structure):
            _fields_ = ctypes_field

            def __init__(self, kwargs) -> None:
                for field in self._fields_:
                    fname, ftype = field
                    setattr(self, fname, ftype(kwargs))

    return VisitorType
