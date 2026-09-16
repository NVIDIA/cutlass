# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Map ``CompileOptions`` to ``cutlass.compiler.CuteCompiler`` configuration."""

from __future__ import annotations

from typing import Any, Callable, TypeVar

from cutlass.base_dsl.common import DSLRuntimeError
from cutlass.base_dsl.compiler import (
    CompileOption,
    CompileOptions,
    EnableTVMFFI,
    DeviceTarget,
    FlattenLocsOutputJsonPath,
    OptLevel,
)


_OptionType = TypeVar("_OptionType", bound=CompileOption)


def _build_cute_ir_pipeline(compile_options: CompileOptions) -> str:
    """Build the ``cute-to-nvvm{...}`` pipeline for ``CuteCompiler``."""
    option_tokens = compile_options.to_str().strip()
    parts = [
        "cute-to-nvvm{",
        "check-inline-asm=false",
        "cubin-format=bin",
    ]
    if option_tokens:
        parts.append(option_tokens)
    parts.extend(
        [
            "enable-cuda-dialect=true",
            "cuda-dialect-external-module=true",
            "}",
        ]
    )
    return " ".join(parts)


def _option_value(
    compile_options: CompileOptions, option_type: type[_OptionType]
) -> Any:
    option = compile_options.options.get(option_type)
    if option is None:
        return None
    return option.value


def _require_unset(
    compile_options: CompileOptions,
    *,
    option_type: type[Any],
    option_label: str,
    predicate: Callable[[Any], bool],
) -> None:
    value = _option_value(compile_options, option_type)
    if value is not None and predicate(value):
        raise DSLRuntimeError(
            f"{option_label} is not supported by the cutlass compiler backend yet.",
            suggestion="Use CUTE_DSL_COMPILER_BACKEND=legacy or disable the option.",
        )


def validate_cutlass_compile_options(compile_options: CompileOptions) -> None:
    """Fail fast on ``CompileOptions`` the cutlass backend cannot honor yet."""
    _require_unset(
        compile_options,
        option_type=DeviceTarget,
        option_label="DeviceTarget",
        predicate=lambda value: bool(value),
    )
    _require_unset(
        compile_options,
        option_type=FlattenLocsOutputJsonPath,
        option_label="flatten-locs-output-json-path",
        predicate=lambda value: bool(str(value).strip()),
    )

    from cutlass.base_dsl.compiler import EnablePYIR, RemarkFilter, RemarkOutput

    _require_unset(
        compile_options,
        option_type=EnablePYIR,
        option_label="enable-pyir",
        predicate=lambda value: bool(value),
    )
    _require_unset(
        compile_options,
        option_type=RemarkFilter,
        option_label="remark-filter",
        predicate=lambda value: bool(str(value).strip()),
    )
    _require_unset(
        compile_options,
        option_type=RemarkOutput,
        option_label="remark-output",
        predicate=lambda value: bool(str(value).strip()),
    )


def configure_cute_compiler(
    compiler: Any,
    *,
    compile_options: CompileOptions,
    compile_gpu_arch: str,
) -> None:
    """Apply DSL compile options to ``compiler``."""
    import cutlass.compiler

    validate_cutlass_compile_options(compile_options)

    compiler.set_pipeline(
        cutlass.compiler.ArtifactType.PreCompiledMlir,
        _build_cute_ir_pipeline(compile_options),
    )

    device_arch = compile_gpu_arch or compile_options.gpu_arch
    if device_arch:
        try:
            compiler.set_device_target(device_arch)
        except RuntimeError as exc:
            raise DSLRuntimeError(
                f"Invalid GPU arch for cutlass compiler: {device_arch!r}"
            ) from exc

    host_target = compile_options.host_target
    if host_target.triple:
        compiler.set_host_target(host_target.triple)

    if compile_options.enable_tvm_ffi:
        compiler.set_abi(cutlass.compiler.Abi.TvmFfi)
    else:
        compiler.set_abi(cutlass.compiler.Abi.CutlassCall)

    opt_level = compile_options.options[OptLevel].value
    compiler.add_compile_option("opt-level", str(opt_level))
