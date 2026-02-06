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

from ._mlir._mlir_libs import _cutlass_ir

_cutlass_ir.populate(_cutlass_ir)

__version__ = "@CUTLASS_IR_WHEEL_RELEASE_VERSION@"
# Monkey patch CUDA version query function
from ._mlir._mlir_libs._cutlass_ir._base_dsl import (
    get_cuda_version as _get_cuda_version,
)
from .base_dsl import common as _common

_common._get_cuda_version = _get_cuda_version

# Import CUDA version from base_dsl
from .base_dsl.version_info import CUDA_VERSION

from .cutlass_dsl import (
    Constexpr,
    dsl_user_op,
    as_numeric,
    min,
    max,
    and_,
    or_,
    not_,
    all_,
    any_,
    select_,
    # Control-flow without AST pre-processor
    if_generate,
    for_generate,
    LoopUnroll,
    while_generate,
    yield_out,
    # Control-flow with AST pre-processor
    range,
    range_constexpr,
    range_dynamic,
    const_expr,
    dynamic_expr,
    # Data types
    dtype,  # Provides conversions to types inheriting from NumericType
    DSLRuntimeError,
    JitArgAdapterRegistry,
    # Construction utilities for user-defined classes
    extract_mlir_values,
    new_from_mlir_values,
    DSLCudaVersion,
    target_version,
)

from .cute.typing import *

# Utilities not belonging to CuTe
from . import utils as utils
from . import pipeline as pipeline

# Used as internal symbol
from . import cutlass_dsl as _dsl

# Aliases
LaunchConfig = _dsl.BaseDSL.LaunchConfig
register_jit_arg_adapter = _dsl.JitArgAdapterRegistry.register_jit_arg_adapter
gpu = _dsl.cutlass_gpu
cuda = _dsl.cuda_helpers

# Jax Framework support
from . import jax as jax
