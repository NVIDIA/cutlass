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
    DeviceTarget,
    FlattenLocsOutputJsonPath,
)


_OptionType = TypeVar("_OptionType", bound=CompileOption)


def _option_value(
    compile_options: CompileOptions, option_type: type[_OptionType]
) -> Any:
    """Return the stored value for ``option_type``, or ``None`` if absent."""
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
    """Raise if ``option_type`` is set to a value that ``predicate`` rejects.

    Used by ``validate_cutlass_compile_options`` to fail fast on options the
    cutlass backend cannot honor yet.
    """
    value = _option_value(compile_options, option_type)
    if value is not None and predicate(value):
        raise DSLRuntimeError(
            f"{option_label} is not supported by the cutlass compiler backend yet.",
            suggestion="Use CUTE_DSL_COMPILER_BACKEND=legacy or disable the option.",
        )


def validate_cutlass_compile_options(
    compile_options: CompileOptions, *, allow_device_target: bool = False
) -> None:
    """Fail fast on ``CompileOptions`` the cutlass backend cannot honor yet.

    ``allow_device_target`` accepts the standalone device-function options
    (``DeviceTarget`` and its ABI options) for staged ``cute.compile_to`` Device
    compilation, which emits no host wrapper. The JIT backend keeps rejecting
    them because the Executor cannot load a Device object.
    """
    if compile_options.has_pipeline_options:
        raise DSLRuntimeError(
            "Scoped pipeline options are not supported by the cutlass "
            "compiler backend yet.",
            suggestion=(
                "Use CUTE_DSL_COMPILER_BACKEND=legacy or remove the scoped "
                "pipeline options."
            ),
        )
    if not allow_device_target:
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


def _apply_compile_options(compiler: Any, compile_options: CompileOptions) -> None:
    """Apply the given options to the compiler via ``add_compile_option``."""
    # Run derived-option finalization (e.g. ptxas diagnostics) before reading
    # serialized tokens.
    compile_options.to_str()
    for option in compile_options.options.values():
        name = type(option)._option_name
        if not name:
            continue
        token = option.serialize().strip()
        if not token:
            continue
        _, _, value = token.partition("=")
        # ``serialize()`` may wrap string values in quotes for MLIR pipeline
        # text (e.g. ``ptx-options='--verbose'``). ``add_compile_option`` wants
        # the semantic value only; C++ re-quotes when rebuilding the pipeline
        # string. Strip a matching leading/trailing quote pair when present.
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
            value = value[1:-1]
        compiler.add_compile_option(name, value)


def _configure_target(
    compiler: Any,
    compile_options: CompileOptions,
    compile_gpu_arch: str,
) -> None:
    """Map GPU arch, host triple, and ABI onto ``compiler``."""
    import cutlass.compiler

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
        compiler.set_host_target(
            host_target.triple, cpu=host_target.cpu, features=host_target.features
        )

    if compile_options.enable_tvm_ffi:
        compiler.set_abi(cutlass.compiler.Abi.TvmFfi)
    else:
        compiler.set_abi(cutlass.compiler.Abi.CutlassCall)


def configure_cute_compiler(
    compiler: Any,
    *,
    compile_options: CompileOptions,
    compile_gpu_arch: str,
    allow_device_target: bool = False,
) -> None:
    """Apply DSL compile options to a ``CuteCompiler`` (or compatible) instance.

    Pipeline tokens are pushed with ``add_compile_option`` (which rebuilds the
    PreCompiledMlir pipelines from the fixed base envelopes). Also maps GPU
    arch, host triple, and ABI. Does not call ``set_pipeline`` directly.
    ``allow_device_target`` is forwarded to ``validate_cutlass_compile_options``.
    """
    validate_cutlass_compile_options(
        compile_options, allow_device_target=allow_device_target
    )
    _apply_compile_options(compiler, compile_options)
    _configure_target(compiler, compile_options, compile_gpu_arch)


def _strip_builtin_module_wrapper(pipeline: str) -> str:
    """Strip a single top-level ``builtin.module(...)`` wrapper, if present."""
    # The _get_pipeline() and preprocess_pipeline() methods produce a
    # pipeline string that is wrapped in a builtin.module() op. This is not
    # what the C++-based compiler expects. Trim it here.
    trimmed = pipeline.strip()
    prefix = "builtin.module("
    if not trimmed.startswith(prefix) or not trimmed.endswith(")"):
        return pipeline
    return trimmed[len(prefix) : -1]


def configure_cute_compiler_with_pipeline(
    compiler: Any,
    *,
    compile_options: CompileOptions,
    compile_gpu_arch: str,
    pipeline: str,
) -> None:
    """Push a fully-formed pipeline string straight to ``compiler``."""
    import cutlass.compiler

    _configure_target(compiler, compile_options, compile_gpu_arch)

    compiler.set_pipeline(
        cutlass.compiler.ArtifactType.PreCompiledMlir,
        _strip_builtin_module_wrapper(pipeline),
        cutlass.compiler.TargetKind.Heterogeneous,
    )
