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

import pickle
from ..typing import IntTuple, Shape, Stride, Coord, Tile
from inspect import Signature

from cutlass.base_dsl.export import (
    SignatureProcessor,
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


class CuteSignatureProcessor(SignatureProcessor):
    def dumps(self, signature: Signature) -> bytes:
        params = []
        for param in signature.parameters.values():
            arg_type = param.annotation
            if arg_type in cute_algebra_types_dump.keys():
                params.append(
                    param.replace(annotation=cute_algebra_types_dump[arg_type])
                )
            else:
                params.append(param)
        return pickle.dumps(signature.replace(parameters=params))

    def loads(self, signature_bytes: bytes) -> Signature:
        signature = pickle.loads(signature_bytes)
        params = []
        for param in signature.parameters.values():
            arg_type = param.annotation
            if arg_type in cute_algebra_types_load.keys():
                params.append(
                    param.replace(annotation=cute_algebra_types_load[arg_type])
                )
            else:
                params.append(param)
        return signature.replace(parameters=params)


# This is the version of the object file. It is used to check the version of the object file is compatible with the current dsl version or not.
object_file_version = "1.1"
