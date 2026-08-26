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

import importlib.util
import linecache
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, List, Optional, cast

from cutlass.base_dsl.tvm_ffi_builder import (
    DynamicParamPackCallProvider,
    CallContext,
    rename_tvm_ffi_function,
    spec,
)
from cutlass.base_dsl.export import get_export_module
from cutlass._mlir import ir
from cutlass._mlir.dialects import llvm
from cutlass._mlir._mlir_libs._cutlass_ir import _aot_support
from cutlass.cutlass_dsl.cuda_jit_executor import CudaDialectJitCompiledFunction
from cutlass.base_dsl.jit_executor import JitExecutor
from cutlass.base_dsl.common import (
    DSLRuntimeError,
    DSLUserCodeError,
    DSLCudaRuntimeError,
)
from cutlass.base_dsl.diagnostics import DiagId, render_code_frame
from cutlass.base_dsl.runtime import cuda as cuda_helpers

import tvm_ffi


_CudaLaunchFields = dict[str, str]


@dataclass(frozen=True)
class _CudaLaunchViolationRule:
    reason: Callable[[_CudaLaunchFields], str]
    suggestion: Callable[[_CudaLaunchFields], str | None]


def _format_tuple3(value: str) -> str:
    parts = [part.strip() for part in value.split(",")]
    if len(parts) == 3 and all(parts):
        return f"({parts[0]}, {parts[1]}, {parts[2]})"
    return value


def _tuple3_part(value: str, index: int) -> str:
    parts = [part.strip() for part in value.split(",")]
    if 0 <= index < len(parts) and parts[index]:
        return parts[index]
    return "unknown"


def _parse_int(value: str, *, min_value: int) -> int | None:
    try:
        parsed = int(value)
    except ValueError:
        return None
    return parsed if parsed >= min_value else None


def _zero_launch_dimension_reason(_fields: _CudaLaunchFields) -> str:
    return "grid and block dimensions must be non-zero."


def _zero_launch_dimension_suggestion(_fields: _CudaLaunchFields) -> str:
    return "Use non-zero grid and block dimensions in `.launch(...)`."


def _block_threads_reason(fields: _CudaLaunchFields) -> str:
    block_threads = fields.get("block_threads", "unknown")
    max_threads = fields.get("max_threads_per_block", "unknown")
    return (
        f"block.x * block.y * block.z = {block_threads} exceeds "
        f"max threads per block = {max_threads}."
    )


def _block_threads_suggestion(fields: _CudaLaunchFields) -> str:
    block = _format_tuple3(fields.get("block", "unknown"))
    max_threads = fields.get("max_threads_per_block", "unknown")
    return (
        f"Change `.launch(..., block={block})` to use at most "
        f"{max_threads} threads per block. If the kernel only uses "
        "threadIdx.x, launch with block=(threads, 1, 1)."
    )


def _dimension_limit_reason(
    fields: _CudaLaunchFields,
    *,
    value_key: str,
    limit_key: str,
    axis: int,
    value_label: str,
    limit_label: str,
) -> str:
    return (
        f"{value_label} = {_tuple3_part(fields.get(value_key, ''), axis)} "
        f"exceeds {limit_label} = {_tuple3_part(fields.get(limit_key, ''), axis)}."
    )


def _block_dimension_suggestion(fields: _CudaLaunchFields) -> str:
    block = _format_tuple3(fields.get("block", "unknown"))
    max_block = _format_tuple3(fields.get("max_block_dim", "unknown"))
    return (
        f"Keep each block dimension within max block dim {max_block}; "
        f"current block is {block}."
    )


def _grid_dimension_suggestion(fields: _CudaLaunchFields) -> str:
    grid = _format_tuple3(fields.get("grid", "unknown"))
    max_grid = _format_tuple3(fields.get("max_grid_dim", "unknown"))
    return (
        f"Keep each grid dimension within max grid dim {max_grid}; "
        f"current grid is {grid}."
    )


def _dynamic_smem_reason(fields: _CudaLaunchFields) -> str:
    max_smem = fields.get(
        "max_shared_mem_per_block_optin_bytes",
        fields.get("max_shared_mem_per_block_bytes", "unknown"),
    )
    return (
        "dynamic shared memory = "
        f"{fields.get('dynamic_smem_bytes', 'unknown')} bytes exceeds "
        f"max opt-in shared memory per block = {max_smem} bytes."
    )


def _dynamic_smem_suggestion(fields: _CudaLaunchFields) -> str:
    max_smem = fields.get(
        "max_shared_mem_per_block_optin_bytes",
        fields.get("max_shared_mem_per_block_bytes", "unknown"),
    )
    return (
        "Reduce dynamic shared memory in `.launch(...)` to at most "
        f"{max_smem} bytes, or use a smaller launch configuration."
    )


def _invalid_launch_configuration_reason(_fields: _CudaLaunchFields) -> str:
    return (
        "check grid/block dimensions, dynamic shared memory, stream, "
        "and launch attributes."
    )


def _no_suggestion(_fields: _CudaLaunchFields) -> str | None:
    return None


# Each preflight violation id maps to both the detail reason and the shared
# diagnostic suggestion. Adding a launch check should only require another rule.
_CUDA_LAUNCH_VIOLATION_RULES: dict[str, _CudaLaunchViolationRule] = {
    "zero_launch_dimension": _CudaLaunchViolationRule(
        reason=_zero_launch_dimension_reason,
        suggestion=_zero_launch_dimension_suggestion,
    ),
    "block_threads_exceeds_max_threads_per_block": _CudaLaunchViolationRule(
        reason=_block_threads_reason,
        suggestion=_block_threads_suggestion,
    ),
    "block_dim_x_exceeds_limit": _CudaLaunchViolationRule(
        reason=lambda fields: _dimension_limit_reason(
            fields,
            value_key="block",
            limit_key="max_block_dim",
            axis=0,
            value_label="blockDim.x",
            limit_label="max block dim x",
        ),
        suggestion=_block_dimension_suggestion,
    ),
    "block_dim_y_exceeds_limit": _CudaLaunchViolationRule(
        reason=lambda fields: _dimension_limit_reason(
            fields,
            value_key="block",
            limit_key="max_block_dim",
            axis=1,
            value_label="blockDim.y",
            limit_label="max block dim y",
        ),
        suggestion=_block_dimension_suggestion,
    ),
    "block_dim_z_exceeds_limit": _CudaLaunchViolationRule(
        reason=lambda fields: _dimension_limit_reason(
            fields,
            value_key="block",
            limit_key="max_block_dim",
            axis=2,
            value_label="blockDim.z",
            limit_label="max block dim z",
        ),
        suggestion=_block_dimension_suggestion,
    ),
    "grid_dim_x_exceeds_limit": _CudaLaunchViolationRule(
        reason=lambda fields: _dimension_limit_reason(
            fields,
            value_key="grid",
            limit_key="max_grid_dim",
            axis=0,
            value_label="gridDim.x",
            limit_label="max grid dim x",
        ),
        suggestion=_grid_dimension_suggestion,
    ),
    "grid_dim_y_exceeds_limit": _CudaLaunchViolationRule(
        reason=lambda fields: _dimension_limit_reason(
            fields,
            value_key="grid",
            limit_key="max_grid_dim",
            axis=1,
            value_label="gridDim.y",
            limit_label="max grid dim y",
        ),
        suggestion=_grid_dimension_suggestion,
    ),
    "grid_dim_z_exceeds_limit": _CudaLaunchViolationRule(
        reason=lambda fields: _dimension_limit_reason(
            fields,
            value_key="grid",
            limit_key="max_grid_dim",
            axis=2,
            value_label="gridDim.z",
            limit_label="max grid dim z",
        ),
        suggestion=_grid_dimension_suggestion,
    ),
    "dynamic_smem_exceeds_limit": _CudaLaunchViolationRule(
        reason=_dynamic_smem_reason,
        suggestion=_dynamic_smem_suggestion,
    ),
    "invalid_launch_configuration": _CudaLaunchViolationRule(
        reason=_invalid_launch_configuration_reason,
        suggestion=_no_suggestion,
    ),
}

# The renderer table above must cover every violation id that the base_dsl
# preflight emitter can produce (``_CUDA_LAUNCH_PREFLIGHT_VIOLATIONS`` in
# ``cutlass.base_dsl.tvm_ffi_builder.tvm_ffi_builder``). The emitter bakes each
# id into a global symbol and ``address_of``-es it; this table maps that same id
# to a human-readable reason/suggestion. A missing entry here would render an
# unhelpful generic error at launch time, so assert coverage at import time to
# fail loudly on drift instead of silently at runtime.
from cutlass.base_dsl.tvm_ffi_builder.tvm_ffi_builder import (
    _CUDA_LAUNCH_PREFLIGHT_VIOLATIONS as _EMITTED_LAUNCH_VIOLATIONS,
)

_missing = set(_EMITTED_LAUNCH_VIOLATIONS) - set(_CUDA_LAUNCH_VIOLATION_RULES)
assert not _missing, (
    "cutlass_dsl launch-violation renderer is missing ids that base_dsl emits: "
    f"{sorted(_missing)}. Add a matching _CudaLaunchViolationRule entry for each."
)


@tvm_ffi.register_error
class CUDADialectError(DSLCudaRuntimeError):
    """TVM-FFI error kind for CUDA dialect runtime failures."""

    PREFIX = "CUDA Error Code: "

    def __init__(self, message: str) -> None:
        self.raw_tvm_ffi_message = message
        error_code, raw_runtime_detail = CUDADialectError._parse_cuda_dialect_message(
            message
        )
        runtime_detail, runtime_suggestion = CUDADialectError._format_cuda_runtime(
            raw_runtime_detail
        )
        super().__init__(
            error_code,
            cuda_helpers.get_cuda_error_name_from_code(
                error_code, cuda_helpers.cudart.cudaError_t
            ),
            runtime_detail=runtime_detail,
            suggestion=runtime_suggestion,
        )

    @staticmethod
    def _parse_cuda_dialect_error_code(message: str) -> int:
        error_code, _ = CUDADialectError._parse_cuda_dialect_message(message)
        return error_code

    @staticmethod
    def _parse_cuda_dialect_message(message: str) -> tuple[int, str]:
        match = re.fullmatch(
            rf"{re.escape(CUDADialectError.PREFIX)}(?P<code>\d+)(?P<detail>.*)",
            message,
            flags=re.DOTALL,
        )
        if match is not None:
            return int(match.group("code")), match.group("detail").strip()

        if not message.startswith(CUDADialectError.PREFIX):
            raise ValueError(
                "CUDADialectError expects a message beginning with "
                f"{CUDADialectError.PREFIX!r}, got {message!r}"
            )
        if not message[len(CUDADialectError.PREFIX) :].strip():
            raise ValueError(
                f"CUDADialectError message has no numeric code: {message!r}"
            )
        raise ValueError(
            f"CUDADialectError message has unexpected payload: {message!r}"
        )

    @staticmethod
    def _format_cuda_runtime(detail: str) -> tuple[str, str | None]:
        fields = CUDADialectError._parse_cuda_runtime_detail_fields(detail)
        if fields.get("kind") != "cuda_launch":
            return detail, None
        return (
            CUDADialectError._format_cuda_launch_detail(fields),
            CUDADialectError._format_cuda_launch_suggestion(fields),
        )

    @staticmethod
    def _parse_cuda_runtime_detail_fields(detail: str) -> dict[str, str]:
        fields: dict[str, str] = {}
        for item in re.split(r"[\n;]+", detail):
            item = item.strip()
            if not item or "=" not in item:
                continue
            key, value = item.split("=", 1)
            fields[key.strip()] = value.strip()
        return fields

    @staticmethod
    def _format_cuda_launch_source_frame(fields: dict[str, str]) -> list[str]:
        source_file = fields.get("source_file", "")
        source_line = _parse_int(fields.get("source_line", ""), min_value=1)
        if not source_file or source_line is None:
            return []

        source_text = linecache.getline(source_file, source_line).rstrip("\n")
        source_col = _parse_int(fields.get("source_col", ""), min_value=0)
        source_end_col = _parse_int(fields.get("source_end_col", ""), min_value=0)

        launch_token_index = source_text.find(".launch")
        if launch_token_index >= 0:
            source_col = launch_token_index + 1
            source_end_col = source_col + len("launch")

        try:
            display_filename = str(Path(source_file).resolve())
        except OSError:
            display_filename = source_file

        frame = render_code_frame(
            source_file,
            source_line,
            source_col,
            source_end_col,
            display_filename=display_filename,
        )
        return [] if frame is None else frame.splitlines()

    @staticmethod
    def _format_cuda_launch_detail(fields: dict[str, str]) -> str:
        api = fields.get("api", "cudaLaunchKernelExC")
        error_name = fields.get("error_name", "unknown")
        error_string = fields.get("error_string", "unknown")
        grid = _format_tuple3(fields.get("grid", "unknown"))
        block = _format_tuple3(fields.get("block", "unknown"))
        block_threads = fields.get("block_threads", "unknown")
        dynamic_smem = fields.get("dynamic_smem_bytes", "unknown")
        stream = fields.get("stream", "unknown")
        device = fields.get("device", "unknown")
        lines = CUDADialectError._format_cuda_launch_source_frame(fields)
        if lines:
            lines.append("")

        lines.extend(
            [
                "CUDA rejected the launch configuration before running the kernel.",
                "",
            ]
        )

        lines.extend(
            [
                "launch:",
                f"  API: {api}",
                f"  CUDA result: {error_name} ({error_string})",
                f"  grid: {grid}",
                f"  block: {block}",
                f"  threads per block: {block_threads}",
                f"  dynamic shared memory: {dynamic_smem} bytes",
                f"  stream: {stream}",
            ]
        )

        limits = CUDADialectError._format_cuda_launch_limit_lines(fields)
        if limits:
            lines.append("")
            if device == "unknown":
                lines.append("device limits:")
            else:
                lines.append(f"device {device} limits:")
            lines.extend(limits)

        reason = CUDADialectError._format_cuda_launch_violation(fields)
        if reason:
            lines.extend(["", f"  reason: {reason}"])

        return "\n".join(lines)

    @staticmethod
    def _format_cuda_launch_limit_lines(fields: dict[str, str]) -> list[str]:
        limits = []
        max_threads = fields.get("max_threads_per_block")
        if max_threads and max_threads != "0":
            limits.append(f"  max threads per block: {max_threads}")
        max_block = fields.get("max_block_dim")
        if max_block and max_block != "0,0,0":
            limits.append(f"  max block dim: {_format_tuple3(max_block)}")
        max_grid = fields.get("max_grid_dim")
        if max_grid and max_grid != "0,0,0":
            limits.append(f"  max grid dim: {_format_tuple3(max_grid)}")
        max_smem = fields.get("max_shared_mem_per_block_bytes")
        if max_smem and max_smem != "0":
            limits.append(f"  max shared memory per block: {max_smem} bytes")
        max_smem_optin = fields.get("max_shared_mem_per_block_optin_bytes")
        if max_smem_optin and max_smem_optin != "0":
            limits.append(
                f"  max opt-in shared memory per block: {max_smem_optin} bytes"
            )
        return limits

    @staticmethod
    def _format_cuda_launch_violation(fields: dict[str, str]) -> str:
        rule = _CUDA_LAUNCH_VIOLATION_RULES.get(fields.get("violation", ""))
        return "" if rule is None else rule.reason(fields)

    @staticmethod
    def _format_cuda_launch_suggestion(fields: dict[str, str]) -> str | None:
        rule = _CUDA_LAUNCH_VIOLATION_RULES.get(fields.get("violation", ""))
        return None if rule is None else rule.suggestion(fields)


class TVMFFICuteCallProvider(DynamicParamPackCallProvider):
    """Cute call provider that uses cute call convention."""

    cuda_device_index: Optional[ir.Value]
    cuda_error_handle_block: Optional[ir.Block]

    def __init__(self, target_func: str, has_gpu_module: bool = True):
        super().__init__(target_func, struct_call=True)
        self.cuda_global_state_symbol = f"__{target_func}_cuda_state"
        self.cuda_device_index = None
        self.cuda_error_handle_block = None
        self.has_gpu_module = has_gpu_module

    def get_callee_struct_for_param_tensor(
        self,
        param: spec.Tensor,
        current_block: ir.Block,
        data: ir.Value,
        shape: list[ir.Value],
        strides: list[ir.Value],
        flatten_struct: ir.Type,
    ) -> ir.Type:
        """Routine used to override the tensor passing struct convention"""
        with ir.InsertionPoint(current_block):
            if param.dlpack_device_type == tvm_ffi.DLDeviceType.kDLCPU:
                data_type = self.ptr_type
            else:
                data_type = self.gpu_ptr_type
            strides_type = (
                self.struct_type(fields=[x.type for x in strides])
                if len(strides) != 1
                else strides[0].type
            )
            shape_type = (
                self.struct_type(fields=[x.type for x in shape])
                if len(shape) != 1
                else shape[0].type
            )
            shape_stride_tuple_type = self.struct_type(
                fields=[shape_type, strides_type]
            )
            tensor_type = self.struct_type(fields=[data_type, shape_stride_tuple_type])
            return tensor_type

    def pack_param_shape(
        self, current_block: ir.Block, context: CallContext, param: spec.Shape
    ) -> tuple[tuple[ir.Type], tuple[ir.Value]]:
        """Pack a shape parameter to a struct."""
        allocas: list[ir.Value] = []
        arg_types: list[ir.Type] = []
        for dim in param.shape:
            if isinstance(dim, spec.Var):
                allocas.append(
                    self.pack_values_to_alloca(
                        current_block,
                        context.entry_block,
                        [context.matched_var_binding[dim]],
                    )[1]
                )
                arg_types.append(context.matched_var_binding[dim].type)
        return tuple(arg_types), tuple(allocas)

    def declare_extern_funcs(
        self, current_block: ir.Block, context: CallContext
    ) -> ir.Block:
        """Append the error handling function to the current block."""
        assert context.builder is not None
        with ir.InsertionPoint(context.module.body):
            context.builder.find_or_declare_extern_func(
                "cuda_dialect_get_error_name",
                [self.i32_type],
                self.ptr_type,
            )
            context.builder.find_or_declare_extern_func(
                "_cudaGetDevice",
                [self.ptr_type],
                self.i32_type,
            )
            context.builder.find_or_declare_extern_func(
                "_cudaSetDevice",
                [self.i32_type],
                self.i32_type,
            )
            context.builder.find_or_declare_extern_func(
                "cuda_dialect_init_library_once",
                [self.ptr_type, self.ptr_type, self.ptr_type, self.ptr_type],
                self.i32_type,
            )
            context.builder.find_or_declare_extern_func(
                "cuda_dialect_unload_library_once",
                [self.ptr_type],
                self.void_type,
            )
            context.builder.find_or_declare_extern_func(
                "TVMFFIErrorSetRaisedFromCStrParts",
                [self.ptr_type, self.ptr_type, self.i32_type],
                self.void_type,
            )
            context.builder.find_or_declare_extern_func(
                "CuteDSLRT_TVMFFISetRaisedCudaError",
                [self.ptr_type, self.i32_type],
                self.void_type,
            )
        return current_block

    def insert_lazy_init_cuda(
        self, current_block: ir.Block, context: CallContext
    ) -> ir.Block:
        """Insert the lazy init cuda function."""
        assert context.builder is not None
        # create global private static that is initialized to nullptr
        with ir.InsertionPoint(context.module.body):
            parsed_op = ir.Operation.parse(
                f"llvm.mlir.global private @{self.cuda_global_state_symbol}(0 : i64) : i64"
            )
            context.module.body.append(parsed_op)

        with ir.InsertionPoint(current_block):
            cuda_global_state_ptr = self.address_of(
                self.cuda_global_state_symbol, self.ptr_type
            )

        with ir.InsertionPoint(current_block):
            cuda_init_ptr = self.address_of("cuda_init", self.ptr_type)
            cuda_load_to_device_ptr = self.address_of(
                "cuda_load_to_device", self.ptr_type
            )
            set_error_ptr = self.address_of(
                "TVMFFIErrorSetRaisedFromCStr", self.ptr_type
            )

        with ir.InsertionPoint(current_block):
            # Call the callback function with the loaded ptr value
            init_result = llvm.call(
                result=self.i32_type,  # function returns i32
                callee="cuda_dialect_init_library_once",
                callee_operands=[
                    cuda_global_state_ptr,
                    cuda_init_ptr,
                    cuda_load_to_device_ptr,
                    set_error_ptr,
                ],
                op_bundle_sizes=[],
                op_bundle_operands=[],
            )
            # Create blocks for conditional branching
            error_block = current_block.create_after()
            success_block = error_block.create_after()
            # Check if initialization failed (non-zero return code)
            llvm.cond_br(
                self.equal(init_result, self.i32(0)),
                true_dest_operands=[],
                false_dest_operands=[],
                true_dest=success_block,
                false_dest=error_block,
            )
        # Error block: return the error code
        # error is already set by cuda_dialect_init_library_once
        with ir.InsertionPoint(error_block):
            llvm.return_(arg=self.i32(-1))

        # Continue with success block
        return success_block

    def append_unload_to_global_dtors(
        self, current_block: ir.Block, context: CallContext
    ) -> ir.Block:
        """Append the cuda_dialect_unload_library_once function to the global destructor list."""
        unload_func_symbol = "cuda_dialect_unload_library_once"
        # define a private function to call the extern function, we need this wrapper function
        # since llvm.mlir.global_dtors require the dtor defined in the module
        unload_func_wrapper_symbol = f"__dtor_{unload_func_symbol}"
        with ir.InsertionPoint(context.module.body):
            params, entry_block = self.function(
                name=unload_func_wrapper_symbol,
                params_type=[],
                ret_type=self.void_type,
                internal=True,
            )
            with ir.InsertionPoint(entry_block):
                llvm.call(
                    result=None,
                    callee=unload_func_symbol,
                    callee_operands=[
                        self.address_of(self.cuda_global_state_symbol, self.ptr_type)
                    ],
                    op_bundle_sizes=[],
                    op_bundle_operands=[],
                )
                llvm.return_()

        # find or create the global destructors
        global_dtors_list: list[ir.Operation] = self.find_operations_in_module(
            context.module, "llvm.mlir.global_dtors"
        )
        if len(global_dtors_list) == 0:
            # create the global destructors
            with ir.InsertionPoint(context.module.body):
                global_dtors = llvm.mlir_global_dtors(
                    dtors=[],
                    priorities=[],
                    data=[],
                )
        else:
            # use the existing global destructors
            global_dtors = global_dtors_list[0]

        # append the unload function to the global destructors
        global_dtors.attributes["dtors"] += [
            ir.FlatSymbolRefAttr.get(unload_func_wrapper_symbol)
        ]
        global_dtors.attributes["priorities"] += [
            ir.IntegerAttr.get(self.i32_type, 65535)
        ]  # the default priority
        global_dtors.attributes["data"] += [
            ir.FlatSymbolRefAttr.get(unload_func_wrapper_symbol)
        ]  # the data will not be used, but we need to pass something to satisfy the llvm.mlir.global_dtors op

        return current_block

    def check_cuda_error(
        self, code: ir.Value, current_block: ir.Block, context: CallContext
    ) -> ir.Block:
        """Check if the CUDA error is raised and return the error string if so.

        Uses a shared error handling block to avoid code duplication. The error code
        is passed as a block argument to the shared error handler.
        """
        assert self.cuda_error_handle_block is not None
        with ir.InsertionPoint(current_block):
            success_block = current_block.create_after()
            nonzero_block = success_block.create_after()
            self.cond_br(
                cond=self.equal(code, self.i32(0)),
                true_block=success_block,
                false_block=nonzero_block,
                branch_weights=self.BRANCH_WEIGHTS_LIKELY,
            )

        with ir.InsertionPoint(nonzero_block):
            already_raised_block = nonzero_block.create_after()
            self.cond_br(
                cond=self.equal(code, self.i32(-1)),
                true_block=already_raised_block,
                false_block=self.cuda_error_handle_block,
                branch_weights=self.BRANCH_WEIGHTS_UNLIKELY,
                false_dest_operands=[code],  # Pass error code to shared error block
            )

        with ir.InsertionPoint(already_raised_block):
            llvm.return_(arg=self.i32(-1))

        return success_block

    def set_cuda_device_if_mismatch(
        self,
        current_block: ir.Block,
        context: CallContext,
        current_device: Optional[ir.Value],
        target_device: Optional[ir.Value],
    ) -> ir.Block:
        """Set the CUDA device index if it differs from the target device."""
        # If either device is None, no switching needed
        if current_device is None:
            assert target_device is None
            return current_block

        with ir.InsertionPoint(current_block):
            # Check if devices are different
            devices_differ = self.not_equal(current_device, target_device)

            # Create blocks for conditional device switching
            switch_device_block = current_block.create_after()
            continuation_block = switch_device_block.create_after()
            # For this specific case, avoid branch weights for now
            # mainly to avoid too drastic reordering of the code
            self.cond_br(
                cond=devices_differ,
                true_block=switch_device_block,
                false_block=continuation_block,
            )

        # Switch device block: call cudaSetDevice
        with ir.InsertionPoint(switch_device_block):
            result = llvm.call(
                result=self.i32_type,
                callee="_cudaSetDevice",
                callee_operands=[target_device],
                op_bundle_sizes=[],
                op_bundle_operands=[],
            )

        # Check for errors and branch to continuation
        switch_device_block = self.check_cuda_error(
            result, switch_device_block, context
        )
        with ir.InsertionPoint(switch_device_block):
            self.br(continuation_block)

        return continuation_block

    def generate_llvm_call(
        self,
        current_block: ir.Block,
        call_operands: list[ir.Value],
        context: CallContext,
    ) -> ir.Block:
        """Generate the LLVM call operation and check if the call is successful."""
        assert context.builder is not None
        old_cuda_device_index: Optional[ir.Value] = None

        # If we need to manage CUDA device context
        if self.cuda_device_index is not None:
            # Create an alloca in the entry block to store the current device index
            device_index_alloca = context.builder.create_alloca(
                context.entry_block, self.i32_type, array_size=1
            )

            # Get the current device
            with ir.InsertionPoint(current_block):
                get_device_result = llvm.call(
                    result=self.i32_type,
                    callee="_cudaGetDevice",
                    callee_operands=[device_index_alloca],
                    op_bundle_sizes=[],
                    op_bundle_operands=[],
                )
            current_block = self.check_cuda_error(
                get_device_result, current_block, context
            )

            # Load the current device index from the alloca
            with ir.InsertionPoint(current_block):
                old_cuda_device_index = llvm.load(self.i32_type, device_index_alloca)

            # Switch to target device if different
            current_block = self.set_cuda_device_if_mismatch(
                current_block, context, old_cuda_device_index, self.cuda_device_index
            )

        # Execute the main call
        with ir.InsertionPoint(current_block):
            result = llvm.call(
                result=self.i32_type,
                callee=self.target_func,
                callee_operands=call_operands,
                op_bundle_sizes=[],
                op_bundle_operands=[],
            )

        # Restore the original device BEFORE checking for errors
        # This ensures device is restored even if the main call failed
        current_block = self.set_cuda_device_if_mismatch(
            current_block, context, self.cuda_device_index, old_cuda_device_index
        )

        # Now check for errors from the main call
        current_block = self.check_cuda_error(result, current_block, context)

        return current_block

    def find_cuda_device_index_from_params(
        self, context: CallContext
    ) -> Optional[ir.Value]:
        """Find the CUDA device index from tensor parameters."""
        for param in context.params:
            if (
                isinstance(param, spec.Tensor)
                and param.dlpack_device_type != tvm_ffi.DLDeviceType.kDLCPU
            ):
                return context.matched_var_binding[param.device_id]
        return None

    def create_shared_cuda_error_block(
        self, current_block: ir.Block, context: CallContext
    ) -> ir.Block:
        """Create a shared error handling block for all CUDA errors."""
        assert context.builder is not None
        # Create the shared error block after the current block (setup phase)
        # This block will be branched to from multiple error checking sites
        # It accepts the error code as a block argument
        error_block = current_block.create_after()
        error_code = error_block.add_argument(self.i32_type, ir.Location.unknown())

        # Populate the error block
        with ir.InsertionPoint(error_block):
            # Raise error and return -1
            context.builder.raise_cuda_error_and_return(error_code)

        return error_block

    def __call__(self, current_block: ir.Block, context: CallContext) -> ir.Block:
        current_block = self.declare_extern_funcs(current_block, context)
        if self.has_gpu_module:
            current_block = self.insert_lazy_init_cuda(current_block, context)
            current_block = self.append_unload_to_global_dtors(current_block, context)
        # Create shared CUDA error handling block after the setup blocks
        # This reduces code duplication - all CUDA errors branch to this single block
        self.cuda_error_handle_block = self.create_shared_cuda_error_block(
            current_block, context
        )
        # setup device index, will be set around the call to the target function
        self.cuda_device_index = self.find_cuda_device_index_from_params(context)
        current_block = super().__call__(current_block, context)
        self.cuda_device_index = None
        self.cuda_error_handle_block = None
        # reset the device index and error block
        return current_block


def _inplace_hide_symbols(
    ir_module: ir.Module, hide_check: Callable[[str], bool]
) -> None:
    """Walk through the IRModule, hide functions that do not yet have linkage set.

    @param ir_module: The ir module to hide the symbols.
    @param hide_check: The callback to check if the symbol should be hidden.
    @return: The ir module with the symbols hidden.
    """
    defined_symbols: set[str] = set()

    def walk_llvm_func_op(op: ir.Operation) -> ir.WalkResult:
        # not a declaration
        if (
            op.name == "llvm.func"
            and len(op.opview.operation.regions) > 0
            and len(op.opview.operation.regions[0].blocks) > 0
        ):
            func_name = op.attributes["sym_name"].value
            defined_symbols.add(func_name)

        return ir.WalkResult.ADVANCE

    def walk_and_hide_symbols(op: ir.Operation) -> ir.WalkResult:
        # Handle llvm.func operations
        if op.name == "llvm.func":
            func_name = op.attributes["sym_name"].value
            # Only set linkage if it doesn't already have one
            if func_name in defined_symbols and hide_check(func_name):
                # Set to internal linkage to hide the symbol
                op.attributes["linkage"] = ir.Attribute.parse("#llvm.linkage<internal>")
        return ir.WalkResult.ADVANCE

    with ir_module.context:
        ir_module.operation.walk(walk_llvm_func_op)
        ir_module.operation.walk(walk_and_hide_symbols)


def _get_format_from_object_file_path(object_file_path: str) -> str:
    format = object_file_path.split(".")[-1]
    if format not in ("o", "ll", "bc"):
        return "o"
    return format


class TVMFFIJitCompiledFunctionBase(CudaDialectJitCompiledFunction):
    """Base class for TVM FFI compiled function."""

    engine: Any

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)

    # use direct call to the tvm_ffi.Function.__call__
    # to avoid most of python overhead
    __call__ = tvm_ffi.Function.__call__

    def to(self, device: Optional[int] = None) -> JitExecutor:
        """TVM FFI function itself is already support all devices."""
        return cast(JitExecutor, self)

    def run_compiled_program(self, exe_args: list[Any]) -> int | None:
        """Run the compiled program. This override is needed for implicit compile and execution."""
        return cast(int | None, self.__call__(*exe_args))  # type: ignore[misc]

    def export_to_c(  # type: ignore[override]
        self,
        object_file_path: str,
        function_name: Optional[str] = None,
        *,
        enable_pic: bool = True,
        export_only_tvm_ffi_symbols: bool = False,
    ) -> None:
        """Export the TVM FFI function to an object file.

        :param object_file_path: The path to the object file.
        :param function_name: The name of the function to export.
        :param enable_pic: Whether to enable PIC relocation needed for shared library loading.
        :param export_only_tvm_ffi_symbols: Only export TVM FFI symbols (hide all others).
        """
        if self.host_target.value:
            raise DSLUserCodeError(DiagId.CONFIG_INCOMPATIBLE_FLAGS)
        assert function_name is not None
        internal_symbol_prefix = "__cute_internal_" + function_name
        mod = self.ir_module
        mod = get_export_module(
            self.ir_module,
            internal_symbol_prefix,
            preserve_symbols={f"__tvm_ffi_{self.function_name}"},
        )

        rename_tvm_ffi_function(mod, self.function_name, function_name)
        if export_only_tvm_ffi_symbols:
            _inplace_hide_symbols(mod, lambda x: not x.startswith("__tvm_ffi"))

        format = _get_format_from_object_file_path(object_file_path)
        out_bytes = _aot_support.export_module_to_bytes(
            mod, format=format, opt_level=3, enable_pic=enable_pic
        )

        with open(object_file_path, "wb") as f:
            f.write(out_bytes)

    def _create_tvm_ffi_function(self) -> Optional["tvm_ffi.Function"]:
        """Create the tvm_ffi.Function from the current execution engine.

        When the base class hands us an MlirExecutionEngine (MCJIT), we
        replace it with a BinaryExecutionEngine (JITLink) to avoid
        non-deterministic SIGSEGV with duplicate .text ELF sections in
        multi-process torchrun workloads.
        """
        if self.engine is not None:
            from cutlass._mlir._mlir_libs._cutlass_ir._execution_engine import (
                BinaryExecutionEngine,
            )
            from cutlass.base_dsl.env_manager import get_prefix_dsl_libs

            obj = _aot_support.export_module_to_bytes(
                self.ir_module, format="o", opt_level=3, enable_pic=True
            )
            libs_str = get_prefix_dsl_libs("CUTE_DSL")
            # os.pathsep, not ":" -- on Windows ":" tears "C:\\..." apart.
            shared_libs = libs_str.split(os.pathsep) if libs_str else []
            self.engine = BinaryExecutionEngine(
                obj,
                shared_libs,
                True,  # useJitLink
            )

            tvm_ffi_function_ptr = self.engine.lookup("__tvm_ffi_" + self.function_name)
            tvm_ffi_function = tvm_ffi.Function.__from_extern_c__(
                tvm_ffi_function_ptr, keep_alive_object=self.engine
            )
            return tvm_ffi_function
        return None


class TVMFFIJitCompiledFunction(tvm_ffi.Function, TVMFFIJitCompiledFunctionBase):
    """TVM FFI Function that directly subclasses the tvm_ffi.Function for pos only arguments."""

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        TVMFFIJitCompiledFunctionBase.__init__(self, *args, **kwargs)
        # initialize the tvm_ffi.Function from the current execution engine
        if self.__chandle__() != 0:
            raise DSLRuntimeError("TVM FFI function is already initialized")
        tvm_ffi_function = self._create_tvm_ffi_function()
        if tvm_ffi_function is not None:
            # move the handle from the tvm_ffi.Function to the current instance
            self.__move_handle_from__(tvm_ffi_function)

    def __call__(self, *args: Any) -> Any:
        if self.__chandle__() == 0:
            raise DSLRuntimeError(
                "TVM FFI function is not initialized."
                " Was this function compiled for a different architecture?"
            )
        if self.execution_args.has_pointer_address_arg_specs:
            args, _ = self.execution_args.convert_python_pointer_args_for_tvm_ffi(
                args, {}
            )
        return tvm_ffi.Function.__call__(self, *args)


class TVMFFIJitCompiledFunctionWithKwargs(TVMFFIJitCompiledFunctionBase):
    """TVM FFI Function with kwargs wrapper support"""

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        assert "kwargs_wrapper_spec" in kwargs, "kwargs_wrapper_spec is required"
        kwargs_wrapper_spec = kwargs.pop("kwargs_wrapper_spec")
        # ``map_dataclass_to_tuple`` is a tvm-ffi concern (lists the arg
        # names whose values get unpacked via unpack_dataclass_to_tuple at
        # call time) and is intentionally kept outside KwargsWrapperSpec.
        map_dataclass_to_tuple: List[str] = kwargs.pop("map_dataclass_to_tuple", [])
        super().__init__(*args, **kwargs)
        # initialize the tvm_ffi.Function from the current execution engine
        self._tvm_ffi_function = self._create_tvm_ffi_function()
        if self._tvm_ffi_function is None:
            self._kwargs_wrapper: Optional[Callable[..., Any]] = None
            return
        # This class is instantiated when the jit signature has any of:
        #   - keyword-only parameters;
        #   - defaults on positional parameters;
        #   - a top-level @dataclass argument (needed for ``compiled(p=...)``
        #     style calls since the underlying tvm_ffi.Function is
        #     positional-only).
        # ``make_kwargs_wrapper`` handles empty kwonly/arg_defaults as no-ops,
        # so a single call covers all three triggers.
        try:
            from tvm_ffi.utils import kwargs_wrapper  # type: ignore

            self._kwargs_wrapper = kwargs_wrapper.make_kwargs_wrapper(
                self._tvm_ffi_function,
                arg_names=kwargs_wrapper_spec.arg_names,
                arg_defaults=kwargs_wrapper_spec.arg_defaults,
                kwonly_names=kwargs_wrapper_spec.kwonly_names,
                kwonly_defaults=kwargs_wrapper_spec.kwonly_defaults,
                map_dataclass_to_tuple=map_dataclass_to_tuple,
            )
        except ImportError:
            raise DSLRuntimeError(
                "install apache-tvm-ffi>=0.1.11 to enable kwargs / defaults / "
                "top-level dataclass argument support"
            )

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        """Call the TVM FFI function with kwargs wrapper."""
        if self._kwargs_wrapper is None:
            raise DSLRuntimeError(
                "TVM FFI function is not initialized."
                " Was this function compiled for a different architecture?"
            )

        if self.execution_args.has_pointer_address_arg_specs:
            args, kwargs = self.execution_args.convert_python_pointer_args_for_tvm_ffi(
                args, kwargs
            )
        return self._kwargs_wrapper(*args, **kwargs)

    def __tvm_ffi_object__(self) -> Optional["tvm_ffi.Function"]:
        return self._tvm_ffi_function


def supports_kwargs_wrapper() -> bool:
    """Check if the kwargs wrapper is supported."""
    return importlib.util.find_spec("tvm_ffi.utils.kwargs_wrapper") is not None
