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

from .export import object_file_version as _object_file_version
from .export import CuteArgsSpecProcessor as _CuteArgsSpecProcessor

from ...base_dsl.jit_executor import ExportProvider as _ExportProvider
from ...cutlass_dsl import CuTeDSL as _CuTeDSL
from ...cutlass_dsl.cuda_jit_executor import (
    CudaDialectJitCompiledFunction as _CudaDialectJitCompiledFunction,
)
from ..._mlir._mlir_libs._cutlass_ir import _mlirExecutionEngine

_CudaDialectJitCompiledFunction.export_provider = _ExportProvider(
    dsl=_CuTeDSL,
    arg_spec_processor=_CuteArgsSpecProcessor(),
    c_header_generator=CuteCHeaderGenerator(),
    object_file_version=_object_file_version,
    mlirExecutionEngine=_mlirExecutionEngine,
)

from ...base_dsl.export import ExternalBinaryModule as _ExternalBinaryModule
from ...base_dsl.export import LoadProvider as _LoadProvider
from .load import version_checker as _version_checker
from ..._mlir._mlir_libs._cutlass_ir._execution_engine import (
    BinaryExecutionEngine as _BinaryExecutionEngine,
)

_ExternalBinaryModule.load_provider = _LoadProvider(
    dsl=_CuTeDSL,
    args_spec_processor=_CuteArgsSpecProcessor(),
    version_checker=_version_checker,
    execution_engine_constructor=_BinaryExecutionEngine,
    jit_function_constructor=_CudaDialectJitCompiledFunction,
)

__all__ = [
    "CuteCHeaderGenerator",
]
