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

"""``cutlass.compiler`` backend for CuTe DSL."""

from __future__ import annotations

import importlib.util
import inspect
import io
import os.path
from typing import Any, cast

import cutlass.compiler as cutlass_compiler
from cutlass.base_dsl.common import DSLRuntimeError
from cutlass.base_dsl.compile_backend import (
    CompileCacheState,
    CompileContext,
    CompilerBackend,
)
from cutlass.base_dsl.compiler import DeviceTarget
from cutlass.base_dsl.jit_executor import JitCompiledFunction
from cutlass.cute.metadata import build_function_metadata
from cutlass.cutlass_dsl.compile_options_adapter import (
    configure_cute_compiler,
    configure_cute_compiler_with_pipeline,
)
from cutlass.cutlass_dsl.cutlass import CutlassBaseDSL, _CompilerPipeline
from cutlass.cutlass_dsl.cutlass_function import (
    CallableFunction,
    CutlassCallJitCompiledFunction,
)


def _build_precompiled_mlir_artifact(
    module: Any,
    *,
    function_name: str,
    signature: Any,
    args: tuple[Any, ...],
    kwonlyargs: dict[str, Any],
    display_name: str,
    adapted_args: list[Any] | None = None,
    target_kind: Any = cutlass_compiler.TargetKind.Heterogeneous,
) -> cutlass_compiler.PreCompiledMlirArtifact:
    """Serialize traced MLIR and attach CutlassCall metadata."""
    buf = io.BytesIO()
    module.operation.write_bytecode(buf)
    artifact = cutlass_compiler.PreCompiledMlirArtifact.from_bitcode(
        buf.getvalue(), target_kind
    )
    artifact.metadata.append(
        build_function_metadata(
            function_name=function_name,
            signature=signature,
            args=args,
            kwonlyargs=kwonlyargs,
            display_name=display_name,
            adapted_args=adapted_args,
        )
    )
    return artifact


def _get_tvm_ffi_libs() -> list[str]:
    """Get the paths to the TVM-FFI shared libraries."""
    tvm_ffi_spec = importlib.util.find_spec("tvm_ffi")
    libs = []
    if tvm_ffi_spec is not None:
        for path in tvm_ffi_spec.submodule_search_locations or []:
            lib_path = os.path.join(path, "lib", "libtvm_ffi.so")
            if os.path.exists(lib_path):
                libs.append(lib_path)
    return libs


class CutlassCompilerBackend(CompilerBackend):
    """Artifact-driven compilation via ``cutlass.compiler``."""

    @property
    def name(self) -> str:
        return "cutlass"

    def _validate_compile(self, ctx: CompileContext) -> None:
        if ctx.funcBody is None:
            raise DSLRuntimeError(
                "cutlass compiler backend requires funcBody for metadata generation."
            )

    def _validate_execution_target(self, compile_gpu_arch: str) -> None:
        dsl = self._dsl
        if dsl.num_kernels > 0 and not dsl._runtime_can_run_compiled(
            dsl.envar.arch, compile_gpu_arch
        ):
            raise DSLRuntimeError(
                f"Cannot execute on this machine a binary built for {compile_gpu_arch!r}.",
                suggestion=(
                    "Cross-compile with legacy backend and export_to_c, or match "
                    f"{dsl.envar.prefix}_ARCH to the compile target."
                ),
            )

    def _build_compiled_function(
        self,
        ctx: CompileContext,
        compile_gpu_arch: str,
        cache_state: CompileCacheState,
    ) -> JitCompiledFunction:
        dsl = cast(CutlassBaseDSL, self._dsl)
        full_args = ctx.full_args if ctx.full_args is not None else ()
        full_kwargs = ctx.full_kwargs if ctx.full_kwargs is not None else {}
        assert ctx.funcBody is not None

        target_kind = (
            cutlass_compiler.TargetKind.Device
            if dsl.compile_options.options[DeviceTarget].value
            else cutlass_compiler.TargetKind.Heterogeneous
        )
        precompiled = _build_precompiled_mlir_artifact(
            cache_state.module,
            function_name=ctx.function_name,
            signature=ctx.sig,
            args=full_args,
            kwonlyargs=full_kwargs,
            display_name=ctx.funcBody.__name__,
            adapted_args=ctx.adapted_args,
            target_kind=target_kind,
        )

        compiler = cutlass_compiler.CuteCompiler()
        use_extension_pipeline = (
            _CompilerPipeline.CUTE_EXT in dsl._active_compiler_pipelines()
        )
        if use_extension_pipeline:
            # We're going to develop a more robust pipeline options system
            # that can handle options for the different pipeline stages
            # used by extension compilation. Until then, pass the full
            # Python-resolved pipeline to the C++ compiler.
            pipeline = dsl.preprocess_pipeline(
                dsl._get_pipeline(ctx.pipeline) or "",
                compile_gpu_arch,
            )
            configure_cute_compiler_with_pipeline(
                compiler,
                compile_options=dsl.compile_options,
                compile_gpu_arch=compile_gpu_arch,
                pipeline=pipeline,
            )
        else:
            configure_cute_compiler(
                compiler,
                compile_options=dsl.compile_options,
                compile_gpu_arch=compile_gpu_arch,
                allow_device_target=target_kind == cutlass_compiler.TargetKind.Device,
            )

        object_artifact = compiler.compile_to(
            precompiled, cutlass_compiler.ArtifactType.Object
        )

        if target_kind == cutlass_compiler.TargetKind.Device:
            executor = None
            cutlass_call = None
        else:
            shared_libraries = dsl.get_shared_libs(
                ctx.extra_link_libs + tuple(_get_tvm_ffi_libs())
            )

            executor = cutlass_compiler.Executor.from_object_artifact(
                object_artifact,
                shared_libraries,
            )
            symbol_name = object_artifact.metadata[0].symbol_name
            executable = executor.get_executable_function(symbol_name)
            python_defaults = {
                name: param.default
                for name, param in ctx.sig.parameters.items()
                if param.default is not inspect.Parameter.empty
            }
            cutlass_call = CallableFunction(executable, python_defaults)

        # ``CutlassCallJitCompiledFunction`` is a structural ``JitCompiledFunction``
        # surface (composition + ``__getattr__`` forwarding) rather than a nominal
        # subclass, so cast to satisfy the backend's declared return type.
        return cast(
            JitCompiledFunction,
            CutlassCallJitCompiledFunction(
                ir_module=cache_state.module,
                cutlass_call=cutlass_call,
                executor=executor,
                signature=ctx.sig,
                function_name=ctx.function_name,
                kernel_info=dsl.kernel_info,
                jit_time_profiling=dsl.envar.jit_time_profiling,
                jit_function_artifacts=self._build_jit_function_artifacts(),
                compile_time_args=full_args,
                compile_time_kwargs=full_kwargs,
                dynamic_args=ctx.dynamic_args or tuple(),
                dynamic_kwargs=ctx.dynamic_kwargs or {},
                has_gpu_module=dsl.num_kernels > 0,
                host_target=dsl.compile_options.host_target,
            ),
        )
