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

import io
from typing import Any, cast

import cutlass.compiler as cutlass_compiler
from cutlass._mlir._mlir_libs import _cutlass_ir
from cutlass.base_dsl.common import DSLRuntimeError
from cutlass.base_dsl.compile_backend import (
    CompileCacheState,
    CompileContext,
    CompilerBackend,
)
from cutlass.base_dsl.jit_executor import JitCompiledFunction
from cutlass.cute.metadata import build_function_metadata
from cutlass.cutlass_dsl.compile_options_adapter import configure_cute_compiler
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
) -> cutlass_compiler.PreCompiledMlirArtifact:
    """Serialize traced MLIR and attach CutlassCall metadata."""
    buf = io.BytesIO()
    module.operation.write_bytecode(buf)
    artifact = _cutlass_ir.PreCompiledMlirArtifact.from_bitcode(buf.getvalue())
    artifact.metadata.append(
        build_function_metadata(
            function_name=function_name,
            signature=signature,
            args=args,
            kwonlyargs=kwonlyargs,
            display_name=display_name,
        )
    )
    return artifact


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
        dsl = self._dsl
        full_args = ctx.full_args if ctx.full_args is not None else ()
        full_kwargs = ctx.full_kwargs if ctx.full_kwargs is not None else {}
        assert ctx.funcBody is not None

        precompiled = _build_precompiled_mlir_artifact(
            cache_state.module,
            function_name=ctx.function_name,
            signature=ctx.sig,
            args=full_args,
            kwonlyargs=full_kwargs,
            display_name=ctx.funcBody.__name__,
        )

        compiler = cutlass_compiler.CuteCompiler()
        configure_cute_compiler(
            compiler,
            compile_options=dsl.compile_options,
            compile_gpu_arch=compile_gpu_arch,
        )

        object_artifact = compiler.compile_to(
            precompiled, cutlass_compiler.ArtifactType.Object
        )
        shared_libraries = dsl.get_shared_libs()
        executor = cutlass_compiler.Executor.from_object_artifact(
            object_artifact, shared_libraries
        )
        symbol_name = object_artifact.metadata[0].symbol_name
        executable = executor.get_executable_function(symbol_name)
        cutlass_call = CallableFunction(executable)

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
