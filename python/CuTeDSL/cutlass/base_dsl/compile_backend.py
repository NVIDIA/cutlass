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

"""Compiler backend selection for CuTe DSL JIT compilation.

``CUTE_DSL_COMPILER_BACKEND`` selects which lowering/runtime stack executes
after shared MLIR generation:

* ``legacy`` (default) — MLIR ``ExecutionEngine`` + ``JitCompiledFunction``
* ``cutlass`` — ``cutlass.compiler`` artifact pipeline (see cutlass_dsl)
"""

from __future__ import annotations

import abc
import inspect
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import TYPE_CHECKING, Any, Callable

from .cache_helpers import (
    dump_cache_to_path,
    load_cache_from_path,
    read_bytecode_and_check_crc32,
    write_bytecode_with_crc32,
)
from .common import DSLRuntimeError
from .jit_executor import JitCompiledFunction, JitFunctionArtifacts
from .utils.logger import log
from .._mlir import ir

if TYPE_CHECKING:
    from .dsl import BaseDSL


@dataclass(frozen=True)
class CompileContext:
    """Inputs for a single host+kernel compile invocation."""

    module: ir.Module
    module_hash: str | None
    function_name: str
    pipeline: str | None
    sig: inspect.Signature
    cache_enabled: bool
    no_jit_engine: bool
    func_type: Callable[..., JitCompiledFunction]
    full_args: Any = None
    full_kwargs: Any = None
    dynamic_args: Any = None
    dynamic_kwargs: Any = None
    original_function_name: str | None = None
    funcBody: Callable[..., Any] | None = None


@dataclass(frozen=True)
class CompileCacheState:
    """Resolved MLIR module and cache metadata for a compile invocation."""

    module: ir.Module
    cache_hit: bool
    load_from_file_cache: bool


class CompilerBackend(ABC):
    """Shared compile orchestration for DSL compiler backends."""

    def __init__(self, dsl: BaseDSL) -> None:
        self._dsl = dsl

    @property
    @abstractmethod
    def name(self) -> str:
        """The name of this backend."""

    def compile(self, ctx: CompileContext) -> JitCompiledFunction:
        self._validate_compile(ctx)
        compile_gpu_arch = self._resolve_compile_gpu_arch()
        self._validate_execution_target(compile_gpu_arch)

        cache_state = self._resolve_compile_cache(ctx)
        fn = self._build_compiled_function(ctx, compile_gpu_arch, cache_state)
        self._finalize_cache(ctx, fn, cache_state.load_from_file_cache)
        return fn

    def _resolve_compile_gpu_arch(self) -> str:
        return self._dsl.compile_options.gpu_arch or self._dsl.envar.arch or ""

    def _resolve_compile_cache(self, ctx: CompileContext) -> CompileCacheState:
        dsl = self._dsl
        load_from_file_cache = False

        if ctx.cache_enabled:
            assert ctx.module_hash is not None
            fn = load_cache_from_path(
                dsl.name, ctx.module_hash, bytecode_reader=read_bytecode_and_check_crc32
            )
            if fn is not None:
                load_from_file_cache = True
                dsl.jit_cache.set(ctx.module_hash, fn, funcBody=ctx.funcBody)

        cached_jit_func = (
            None if not ctx.cache_enabled else dsl.jit_cache.get(ctx.module_hash)
        )

        if (
            not ctx.cache_enabled
            or cached_jit_func is None
            or cached_jit_func.ir_module is None
        ):
            self._record_cache_miss(ctx)
            return CompileCacheState(
                module=ctx.module,
                cache_hit=False,
                load_from_file_cache=load_from_file_cache,
            )

        self._record_cache_hit(ctx)
        return CompileCacheState(
            module=cached_jit_func.ir_module,
            cache_hit=True,
            load_from_file_cache=load_from_file_cache,
        )

    def _record_cache_miss(self, ctx: CompileContext) -> None:
        dsl = self._dsl
        if dsl.envar.jit_time_profiling:
            dsl.cache_misses += 1
            log().info(
                "Jit cache hit rate=[%f%%]",
                dsl.cache_hits / (dsl.cache_hits + dsl.cache_misses) * 100,
            )
        log().info(
            "JIT cache miss function=[%s] module_hash=[%s]",
            ctx.function_name,
            ctx.module_hash,
        )

    def _record_cache_hit(self, ctx: CompileContext) -> None:
        dsl = self._dsl
        log().info(
            "JIT cache hit IN-FILE function=[%s] module_hash=[%s]",
            ctx.function_name,
            ctx.module_hash,
        )
        if dsl.envar.jit_time_profiling:
            dsl.cache_hits += 1
            log().info(
                "JIT cache hit rate=[%f%%]",
                dsl.cache_hits / (dsl.cache_hits + dsl.cache_misses) * 100,
            )

    def _build_jit_function_artifacts(self) -> JitFunctionArtifacts:
        dsl = self._dsl
        return JitFunctionArtifacts(
            PTX=dsl.compile_options.full_ptx_path,
            CUBIN=dsl.compile_options.full_cubin_path,
            SASS=dsl.compile_options.dump_sass_path,
            MLIR=(
                str(dsl.dump_mlir_path)
                if (dsl.envar.keep_ir or dsl.envar.keep_ir_clean)
                else None
            ),
        )

    def _finalize_cache(
        self,
        ctx: CompileContext,
        fn: JitCompiledFunction,
        load_from_file_cache: bool,
    ) -> None:
        if not ctx.cache_enabled:
            return

        assert ctx.module_hash is not None

        self._dsl.jit_cache.set(ctx.module_hash, fn, funcBody=ctx.funcBody)
        if self._dsl.envar.disable_file_caching or load_from_file_cache:
            return
        dump_cache_to_path(
            self._dsl.name,
            fn,
            ctx.module_hash,
            bytecode_writer=lambda f: write_bytecode_with_crc32(f, fn.ir_module),
        )

    @abstractmethod
    def _validate_compile(self, ctx: CompileContext) -> None:
        """Raise if ``ctx`` cannot be compiled by this backend."""

    @abstractmethod
    def _validate_execution_target(self, compile_gpu_arch: str) -> None:
        """Raise if this machine cannot execute binaries for ``compile_gpu_arch``."""

    @abstractmethod
    def _build_compiled_function(
        self,
        ctx: CompileContext,
        compile_gpu_arch: str,
        cache_state: CompileCacheState,
    ) -> JitCompiledFunction:
        """Lower ``cache_state.module`` and construct the compiled function."""


class LegacyCompilerBackend(CompilerBackend):
    """MLIR ExecutionEngine path used by CuTe DSL today."""

    @property
    def name(self) -> str:
        return "legacy"

    def _validate_compile(self, ctx: CompileContext) -> None:
        pass

    def _validate_execution_target(self, compile_gpu_arch: str) -> None:
        pass

    def _build_compiled_function(
        self,
        ctx: CompileContext,
        compile_gpu_arch: str,
        cache_state: CompileCacheState,
    ) -> JitCompiledFunction:
        dsl = self._dsl
        module = cache_state.module

        # Build a JIT engine when the runtime arch can execute a binary built for compile_gpu_arch;
        # a genuine cross-compile gets no engine and must be exported. _runtime_can_run_compiled is
        # overridden per DSL: the base requires an exact arch match, CuTe DSL adds family-portability.
        gen_jit_engine = dsl.num_kernels == 0 or dsl._runtime_can_run_compiled(
            dsl.envar.arch, compile_gpu_arch
        )

        if ctx.no_jit_engine:
            gen_jit_engine = False

        # Preprocess the pipeline.
        pipeline = dsl.preprocess_pipeline(
            dsl._get_pipeline(ctx.pipeline),  # type: ignore[arg-type]
            compile_gpu_arch,  # type: ignore[arg-type]
        )

        shared_libs = dsl.get_shared_libs()

        if not cache_state.cache_hit:
            # Compile and JIT MLIR module
            engine, module = dsl._compile_or_jit_module(
                module, pipeline, ctx.function_name, shared_libs, gen_jit_engine
            )
        else:
            engine = (
                dsl.compiler_provider.jit(module, shared_libs=shared_libs)
                if gen_jit_engine
                else None
            )

        capi_func = dsl._lookup_jit_entry(engine, ctx.function_name) if engine else None

        return dsl._build_jit_function(
            ctx.func_type,
            module,
            engine,
            capi_func,
            ctx.sig,
            ctx.function_name,
            ctx.dynamic_args,
            ctx.dynamic_kwargs,
        )


def get_compiler_backend(dsl: BaseDSL) -> CompilerBackend:
    """Return the configured compiler backend for ``dsl``."""
    backend_name = dsl.envar.compiler_backend
    log().debug("%s compiler backend: %s", dsl.name, backend_name)
    if backend_name == "legacy":
        return LegacyCompilerBackend(dsl)

    raise DSLRuntimeError(f"Unsupported compiler backend {backend_name}.")
