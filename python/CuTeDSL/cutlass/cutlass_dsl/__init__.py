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

from .cutlass import *

from ..base_dsl.ast_helpers import (
    loop_selector,
    if_selector,
    if_executor,
    while_selector,
    while_executor,
    range,
    range_constexpr,
    range_dynamic,
    const_expr,
    dynamic_expr,
    assert_executor,
    bool_cast,
    compare_executor,
    any_executor,
    all_executor,
    range_value_check,
    cf_symbol_check,
    redirect_builtin_function,
    copy_members,
    get_locals_or_none,
    closure_check,
    fstring_decompose,
    FormattedValue,
)

from ..base_dsl import *
from ..base_dsl.dsl import extract_mlir_values, new_from_mlir_values
from ..base_dsl.typing import _binary_op_type_promote
from ..base_dsl._mlir_helpers.gpu import *
from ..base_dsl._mlir_helpers.op import dsl_user_op
from ..base_dsl.runtime import *
from ..base_dsl.runtime import cuda as cuda_helpers
from ..base_dsl.compiler import (
    CompileCallable,
    OptLevel,
    PtxasOptions,
    EnableAssertions,
    GenerateLineInfo,
    KeepCUBIN,
    KeepPTX,
    GPUArch,
    LinkLibraries,
    EnableTVMFFI,
)
from ..base_dsl.runtime.jit_arg_adapters import *


from ..base_dsl.utils.logger import _init_logger_with_client_name

# Initialize logger
_init_logger_with_client_name("CUTE_DSL")
