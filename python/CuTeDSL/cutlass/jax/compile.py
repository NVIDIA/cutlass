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

from collections.abc import Hashable, Mapping, Sequence
from dataclasses import dataclass, field
from functools import partial
import gc
import hashlib
import logging
import operator
import os
import threading
import time
from typing import Any, Callable

import cuda.bindings.driver as cuda

import jax
import jax.numpy as jnp

from .types import (
    DEFAULT_CUTLASS_DEVICE_MEMSPACE,
    JaxArray,
    JaxTracedArray,
    TensorSpec,
    jax_to_cutlass_dtype,
    row_major_layout,
)

import cutlass
import cutlass.compiler as cutlass_compiler
import cutlass.cute as cute
from cutlass.cutlass_dsl.cutlass import CuTeDSL

logger = logging.getLogger(__name__)

_EXPORT_PREFIX = "cutlass_call"
_AliasRef = int | jax.tree_util.KeyPath
_KEY_ENTRY_TYPES = (
    jax.tree_util.SequenceKey,
    jax.tree_util.DictKey,
    jax.tree_util.GetAttrKey,
    jax.tree_util.FlattenedIndexKey,
)


@dataclass(frozen=True)
class Arg:
    idx: int  # position in pytree
    shape: tuple[Any, ...]
    dtype: jnp.dtype
    spec: TensorSpec

    def get_static_flag(self, use_static_tensors: bool) -> bool:
        if self.spec.static is None:
            return use_static_tensors
        else:
            return self.spec.static


@dataclass(frozen=True)
class FunctionSpec:
    """Contains the physical FFI frame and user-kernel argument structure."""

    in_args: tuple[Arg, ...]
    input_tree: Any
    out_args: tuple[Arg, ...]
    output_tree: Any
    input_output_aliases: tuple[tuple[int, int], ...]
    input_spec: tuple[TensorSpec, ...]
    output_spec: tuple[TensorSpec, ...]
    compile_options: str | None
    use_static_tensors: bool
    kwargs: tuple[tuple[str, Any], ...]

    def get_compile_args(self) -> list[JaxTracedArray]:
        """Return JAX buffer placeholders for ``cute.compile`` or ``compile_to``."""
        return [
            JaxTracedArray(
                JaxArray(
                    jax_to_cutlass_dtype(leaf.dtype),
                    leaf.shape,
                    DEFAULT_CUTLASS_DEVICE_MEMSPACE,
                    leaf.spec.ptr_assumed_align,
                    leaf.spec.layout,
                    leaf.spec.mode,
                    leaf.get_static_flag(self.use_static_tensors),
                    leaf.spec.divisibility,
                )
            )
            for leaf in self.in_args + self.out_args
        ]


@dataclass(frozen=True)
class _KernelLoweringTarget:
    """Kernel callable with its JAX lowering-cache identity."""

    fn: Callable[..., None] = field(compare=False, hash=False, repr=False)
    user_compile_key: Hashable | None = field(compare=False, hash=False)
    _jax_cache_key: tuple[bool, Hashable] = field(init=False, repr=False)

    def __post_init__(self) -> None:
        has_user_key = self.user_compile_key is not None
        cache_key = self.user_compile_key if has_user_key else self.fn
        object.__setattr__(self, "_jax_cache_key", (has_user_key, cache_key))


@cute.jit
def jit_wrapper(
    stream: cuda.CUstream,
    *args: JaxTracedArray,
    wrapped_fn: cutlass.Constexpr,
    spec: cutlass.Constexpr,
) -> None:
    """Convert flat XLA FFI buffer arguments and invoke a CuTe launcher.

    The buffers are positional varargs so compilation metadata gives each
    pointer its own top-level ABI slot. Passing one list here would instead
    require the caller to pack a nested ``void*[]`` tuple slot.
    """
    expected_arg_count = (  # type: ignore[attr-defined]
        len(spec.in_args) + len(spec.out_args)
    )
    if cutlass.const_expr(len(args) != expected_arg_count):
        raise ValueError(
            f"Expected {expected_arg_count} JAX buffer descriptors, got {len(args)}."
        )

    # Split buffer arguments into inputs and outputs and restore their pytrees.
    ins, outs = (  # type: ignore[attr-defined]
        args[: len(spec.in_args)],
        args[len(spec.in_args) :],
    )
    outs = _kernel_output_args(outs, spec.input_output_aliases)  # type: ignore[attr-defined]
    ins = [x.get_tensor() for x in ins]  # type: ignore[assignment, attr-defined]
    outs = [x.get_tensor() for x in outs]  # type: ignore[assignment, attr-defined]
    ins = jax.tree.unflatten(spec.input_tree, ins)  # type: ignore[attr-defined]
    outs = jax.tree.unflatten(spec.output_tree, outs)  # type: ignore[attr-defined]
    wrapped_fn(stream, *ins, *outs, **dict(spec.kwargs))  # type: ignore[operator, attr-defined]


@dataclass
class CompileResult:
    """Holds reference to the compiled kernel and argument spec."""

    module: bytes
    fingerprint: bytes
    spec: FunctionSpec


@dataclass(frozen=True)
class CompileCacheKey:
    """Hashable inputs that determine the compiled object.

    ``compile_key`` is the MLIR fingerprint or caller-provided key.
    """

    compile_key: Hashable
    spec: FunctionSpec
    environment: str


_CUTLASS_COMPILE_CACHE: dict[CompileCacheKey, CompileResult] = {}


def _generate_precompiled_mlir(
    fn: Callable[..., None], spec: FunctionSpec
) -> cutlass_compiler.PreCompiledMlirArtifact:
    """Trace one cutlass call to the content used for cache lookup.

    Cache misses retrace through the legacy object exporter, so launchers must
    generate identical IR for identical compile arguments.
    """
    return cute.compile_to(
        cutlass_compiler.ArtifactType.PreCompiledMlir,
        jit_wrapper,
        cuda.CUstream(0),
        *spec.get_compile_args(),
        wrapped_fn=fn,
        spec=spec,
        options=spec.compile_options,
    )


def _check_is_valid_type(x: Any, is_input: bool) -> None:
    if not is_input:
        if not isinstance(x, jax.ShapeDtypeStruct):
            raise TypeError("Invalid output value passed.", x)
    else:
        if not isinstance(x, jax.Array):
            raise TypeError("Invalid type passed.", x)


def _normalize_input_output_aliases(
    aliases: Mapping[_AliasRef, _AliasRef] | None,
) -> tuple[tuple[_AliasRef, _AliasRef], ...]:
    """Canonicalize top-level and JAX key-path aliases."""

    if aliases is None:
        return ()
    if not isinstance(aliases, Mapping):
        raise TypeError("input_output_aliases must be a mapping")

    def normalize_ref(value: Any, name: str) -> _AliasRef:
        if not isinstance(value, bool):
            try:
                index = operator.index(value)
            except TypeError:
                pass
            else:
                if index < 0:
                    raise ValueError(
                        f"input_output_aliases {name} must be nonnegative; got {index}"
                    )
                return index
        if not isinstance(value, tuple):
            raise TypeError(
                f"input_output_aliases {name} must be an integer or JAX KeyPath"
            )
        if not all(isinstance(entry, _KEY_ENTRY_TYPES) for entry in value):
            raise TypeError(
                f"input_output_aliases {name} KeyPath entries must be JAX key entries"
            )
        try:
            hash(value)
        except TypeError as error:
            raise TypeError(
                f"input_output_aliases {name} KeyPath must be hashable"
            ) from error
        return value

    normalized: list[tuple[_AliasRef, _AliasRef]] = []
    input_refs: set[_AliasRef] = set()
    output_refs: set[_AliasRef] = set()
    for raw_input_ref, raw_output_ref in aliases.items():
        input_ref = normalize_ref(raw_input_ref, "input index")
        output_ref = normalize_ref(raw_output_ref, "output index")
        if isinstance(input_ref, int) != isinstance(output_ref, int):
            raise TypeError(
                "input_output_aliases must map an integer to an integer or a "
                "JAX KeyPath to a JAX KeyPath"
            )
        if input_ref in input_refs:
            raise ValueError(
                f"input_output_aliases contains duplicate input {input_ref}"
            )
        if output_ref in output_refs:
            raise ValueError(
                "input_output_aliases must not map multiple inputs to output "
                f"{output_ref}"
            )
        input_refs.add(input_ref)
        output_refs.add(output_ref)
        normalized.append((input_ref, output_ref))

    def sort_key(alias: tuple[_AliasRef, _AliasRef]) -> tuple[str, str]:
        input_ref, output_ref = alias
        input_key = (
            str(input_ref)
            if isinstance(input_ref, int)
            else jax.tree_util.keystr(input_ref)
        )
        output_key = (
            str(output_ref)
            if isinstance(output_ref, int)
            else jax.tree_util.keystr(output_ref)
        )
        return input_key, output_key

    return tuple(sorted(normalized, key=sort_key))


def _kernel_output_args(
    physical_outputs: Sequence[Any], aliases: Sequence[tuple[int, int]]
) -> list[Any]:
    """Returns result descriptors that remain explicit user-kernel outputs."""

    aliased_outputs = {output_index for _, output_index in aliases}
    return [
        output
        for output_index, output in enumerate(physical_outputs)
        if output_index not in aliased_outputs
    ]


def build_function_spec(
    ins: Any,
    in_tree: Any,
    outs: Any,
    out_tree: Any,
    input_spec: tuple[TensorSpec, ...],
    output_spec: tuple[TensorSpec, ...],
    input_output_aliases: Mapping[_AliasRef, _AliasRef],
    compile_options: str | None,
    use_static_tensors: bool,
    kwargs: dict[str, Any],
) -> FunctionSpec:
    in_args = []
    for idx, (arg, tensor_spec) in enumerate(zip(ins, input_spec)):
        _check_is_valid_type(arg, is_input=True)
        in_args.append(Arg(idx, arg.shape, arg.dtype, tensor_spec))

    out_args = []
    for idx, (arg, tensor_spec) in enumerate(zip(outs, output_spec)):
        _check_is_valid_type(arg, is_input=False)
        out_args.append(Arg(idx, arg.shape, arg.dtype, tensor_spec))

    # Return the argument specs to the original pytree structure
    # We need this structure to sanely match index positions of the
    # arguments to the kernel.
    ins_args_structured = jax.tree.unflatten(in_tree, in_args)
    out_args_structured = jax.tree.unflatten(out_tree, out_args)

    aliases = _normalize_input_output_aliases(input_output_aliases)
    input_output_aliases_per_leaf: dict[int, int] = {}
    aliased_input_indices: set[int] = set()
    aliased_output_indices: set[int] = set()

    def add_alias(input_arg: Arg, output_arg: Arg, label: str) -> None:
        if input_arg.idx in aliased_input_indices:
            raise ValueError(f"input_output_aliases {label} reuses an input buffer")
        if output_arg.idx in aliased_output_indices:
            raise ValueError(f"input_output_aliases {label} reuses an output buffer")
        if input_arg.shape != output_arg.shape or input_arg.dtype != output_arg.dtype:
            raise ValueError(
                f"input_output_aliases {label} has different input and output "
                "shape or dtype"
            )
        input_layout = input_arg.spec.layout or row_major_layout(input_arg.shape)
        output_layout = output_arg.spec.layout or row_major_layout(output_arg.shape)
        if input_layout != output_layout:
            raise ValueError(
                f"input_output_aliases {label} has different input and output "
                "physical layouts"
            )
        aliased_input_indices.add(input_arg.idx)
        aliased_output_indices.add(output_arg.idx)
        input_output_aliases_per_leaf[input_arg.idx] = output_arg.idx

    top_level_aliased_outputs: set[int] = set()
    path_aliased_outputs: set[jax.tree_util.KeyPath] = set()
    input_path_values = dict(
        jax.tree_util.tree_flatten_with_path(
            ins_args_structured, is_leaf=lambda value: value is None
        )[0]
    )
    output_path_values = dict(
        jax.tree_util.tree_flatten_with_path(
            out_args_structured, is_leaf=lambda value: value is None
        )[0]
    )
    missing = object()

    for input_ref, output_ref in aliases:
        if not isinstance(input_ref, int):
            assert not isinstance(output_ref, int)
            input_arg = input_path_values.get(input_ref, missing)
            output_arg = output_path_values.get(output_ref, missing)
            if input_arg is missing:
                raise ValueError(
                    "input_output_aliases input path does not exist: "
                    f"{jax.tree_util.keystr(input_ref)}"
                )
            if output_arg is missing:
                raise ValueError(
                    "input_output_aliases output path does not exist: "
                    f"{jax.tree_util.keystr(output_ref)}"
                )
            if (input_arg is None) != (output_arg is None):
                raise ValueError(
                    "input_output_aliases paths must both resolve to tensors or "
                    "both resolve to None"
                )
            path_aliased_outputs.add(output_ref)
            if input_arg is not None:
                assert isinstance(input_arg, Arg)
                assert isinstance(output_arg, Arg)
                add_alias(
                    input_arg,
                    output_arg,
                    f"path {jax.tree_util.keystr(input_ref)}:"
                    f"{jax.tree_util.keystr(output_ref)}",
                )
            continue

        input_arg_alias_idx = input_ref
        assert isinstance(output_ref, int)
        output_arg_alias_idx = output_ref
        if input_arg_alias_idx >= len(ins_args_structured):
            raise ValueError(
                "input_output_aliases input index "
                f"{input_arg_alias_idx} is outside [0, {len(ins_args_structured)})"
            )
        if output_arg_alias_idx >= len(out_args_structured):
            raise ValueError(
                "input_output_aliases output index "
                f"{output_arg_alias_idx} is outside [0, {len(out_args_structured)})"
            )

        flat_in, input_subtree = jax.tree.flatten(
            ins_args_structured[input_arg_alias_idx]
        )
        flat_out, output_subtree = jax.tree.flatten(
            out_args_structured[output_arg_alias_idx]
        )
        if input_subtree != output_subtree:
            raise ValueError(
                "input_output_aliases mapping "
                f"{input_arg_alias_idx}:{output_arg_alias_idx} must refer to "
                f"matching pytrees; got {input_subtree} and {output_subtree}"
            )
        for leaf_index, (input_arg, output_arg) in enumerate(zip(flat_in, flat_out)):
            add_alias(
                input_arg,
                output_arg,
                f"mapping {input_arg_alias_idx}:{output_arg_alias_idx} leaf "
                f"{leaf_index}",
            )
        top_level_aliased_outputs.add(output_arg_alias_idx)

    # Aliased results stay in the physical FFI frame. They are removed only
    # from the output structure passed to the user kernel.
    out_args_structured = jax.tree_util.tree_map_with_path(
        lambda path, value: None if path in path_aliased_outputs else value,
        out_args_structured,
        is_leaf=lambda value: value is None,
    )
    out_args_structured = list(out_args_structured)
    for out_idx in sorted(top_level_aliased_outputs, reverse=True):
        out_args_structured.pop(out_idx)
    out_args_structured = tuple(out_args_structured)

    in_args_flat, _ = jax.tree.flatten(ins_args_structured)
    _, out_tree = jax.tree.flatten(out_args_structured)

    spec = FunctionSpec(
        tuple(in_args_flat),
        in_tree,
        tuple(out_args),
        out_tree,
        tuple(sorted(input_output_aliases_per_leaf.items())),
        tuple(input_spec),
        tuple(output_spec),
        compile_options,
        use_static_tensors,
        tuple((k, kwargs[k]) for k in kwargs),
    )

    return spec


_compile_lock = threading.Lock()


def get_or_compile_kernel(
    fn: Callable[..., None],
    spec: FunctionSpec,
    *,
    compile_key: Hashable | None = None,
) -> CompileResult:
    """Return the kernel compiled for the callable and argument specification.

    ``compile_key`` skips automatic IR generation when provided.
    """

    lowering_target = _KernelLoweringTarget(fn, compile_key)

    # CuTe tracing mutates process-global DSL state, so key generation and
    # backend compilation must be serialized together.
    with _compile_lock:
        start = time.perf_counter()
        try:
            environment = str(sorted(os.environ.items()))
            if lowering_target.user_compile_key is None:
                artifact = _generate_precompiled_mlir(lowering_target.fn, spec)
                serialized_artifact = bytes(
                    cutlass_compiler.serialize_compilation_artifact(artifact)
                )
                compile_key = hashlib.sha256(serialized_artifact).digest()
            else:
                compile_key = lowering_target.user_compile_key
            cache_key = CompileCacheKey(
                compile_key=compile_key,
                spec=spec,
                environment=environment,
            )
            cached = _CUTLASS_COMPILE_CACHE.get(cache_key)
            if cached is not None:
                logger.debug(
                    "CuTe backend compile cache hit after %.3f s.",
                    time.perf_counter() - start,
                )
                return cached

            # This is an intermediate migration: compile_to supplies the cache
            # identity while object generation remains on cute.compile until the
            # full compilation flow transitions to compile_to.
            cute_compile = cutlass.cute.compile
            if spec.compile_options:
                cute_compile = partial(cute_compile, options=spec.compile_options)  # type: ignore[assignment]

            compiled_fn = cute_compile(
                jit_wrapper,
                cuda.CUstream(0),
                *spec.get_compile_args(),
                wrapped_fn=lowering_target.fn,
                spec=spec,
            )

            module = compiled_fn.dump_to_object(_EXPORT_PREFIX)
            fingerprint = hashlib.sha256(module).digest()
            result = CompileResult(module=module, spec=spec, fingerprint=fingerprint)
            _CUTLASS_COMPILE_CACHE[cache_key] = result

        except Exception:
            # Log here because Jax can obscure the exception details.
            logger.exception("Compilation failure for kernel.")
            raise
        elapsed = time.perf_counter() - start
    logger.debug("Compiled CuTe kernel after cache miss in %.3f s.", elapsed)

    return result


def release_compile_cache() -> None:
    """Releases entries from the compile cache.

    This may prevent CuTeDSL from saving its persistent compilation cache entries.
    """
    with _compile_lock:
        _CUTLASS_COMPILE_CACHE.clear()
        dsl = CuTeDSL._get_dsl()
        dsl.jit_cache.clear()
    gc.collect()
