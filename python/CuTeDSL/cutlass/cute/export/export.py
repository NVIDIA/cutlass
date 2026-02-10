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

import os
import pickle
import copy
from ..typing import IntTuple, Shape, Stride, Coord, Tile
from inspect import FullArgSpec

from cutlass.base_dsl.export import (
    ArgsSpecProcessor,
)

cute_algebra_types_dump = {
    IntTuple: "IntTuple",
    Shape: "Shape",
    Stride: "Stride",
    Coord: "Coord",
    Tile: "Tile",
}
cute_algebra_types_load = {
    "IntTuple": IntTuple,
    "Shape": Shape,
    "Stride": Stride,
    "Coord": Coord,
    "Tile": Tile,
}


class CuteArgsSpecProcessor(ArgsSpecProcessor):
    def dumps(self, args_spec: FullArgSpec) -> bytes:
        new_args_spec = copy.deepcopy(args_spec)
        for arg, arg_type in new_args_spec.annotations.items():
            if arg_type in cute_algebra_types_dump.keys():
                new_args_spec.annotations[arg] = cute_algebra_types_dump[arg_type]
        return pickle.dumps(new_args_spec)

    def loads(self, args_spec_bytes: bytes) -> FullArgSpec:
        args_spec = pickle.loads(args_spec_bytes)
        for arg, arg_type in args_spec.annotations.items():
            if arg_type in cute_algebra_types_load.keys():
                args_spec.annotations[arg] = cute_algebra_types_load[arg_type]
        return args_spec


# This is the version of the object file. It is used to check the version of the object file is compatible with the current dsl version or not.
object_file_version = "1.1"
