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

from .c_header_generator import CuteCHeaderGenerator

from ...base_dsl.export import (
    get_export_module,
    dump_to_object as _dump_to_object,
    export_to_c as _export_to_c,
)
from ...cutlass_dsl import CuTeDSL
from functools import partial as _partial
from ...cutlass_dsl.cuda_jit_executor import CudaDialectJitCompiledFunction

dump_to_object = _partial(
    _dump_to_object,
    dsl=CuTeDSL._get_dsl(),
)
export_to_c = _partial(
    _export_to_c,
    dsl=CuTeDSL._get_dsl(),
    c_header_generator=CuteCHeaderGenerator(),
    use_gpu_dialect=False,
)
__all__ = [
    "CuteCHeaderGenerator",
    "get_export_module",
    "dump_to_object",
    "export_to_c",
]
