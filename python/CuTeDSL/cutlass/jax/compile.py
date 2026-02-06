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

import os
import gc
import ctypes
import inspect
from typing import Any, Callable, Optional, Sequence
from dataclasses import dataclass
from functools import partial
from pathlib import Path

import time
import logging
import threading
import hashlib

import cuda.bindings.driver as cuda

import jax
import jax.numpy as jnp
import jaxlib

from .types import (
    jax_to_cutlass_dtype,
    from_dlpack,
    JaxArray,
    JaxArrayList,
    TensorSpec,
    JaxTracedArray,
    DEFAULT_CUTLASS_DEVICE_MEMSPACE,
    DEFAULT_CUTLASS_DEVICE_BUFFER_ALIGNMENT,
)

import cutlass
import cutlass.cute as cute
from cutlass.cutlass_dsl.cutlass import CuTeDSL

logger = logging.getLogger(__name__)

_CUTLASS_COMPILE_CACHE = {}
_EXPORT_PREFIX = "cutlass_call"


@dataclass(frozen=True)
class Arg:
    idx: int  # position in pytree
    shape: tuple[Any, ...]
    dtype: jnp.dtype
    spec: TensorSpec

    def get_static_flag(self, use_static_tensors: bool):
        if self.spec.static is None:
            return use_static_tensors
        else:
            return self.spec.static


@dataclass(frozen=True)
class FunctionSpec:
    """Contains a specification of the inputs and outputs to the kernel."""

    in_args: tuple[Arg, ...]
    input_tree: Any
    out_args: tuple[Arg, ...]
    output_tree: Any
    input_output_aliases: tuple[tuple[int, int], ...]
    input_spec: tuple[TensorSpec, ...]
    output_spec: tuple[TensorSpec, ...]
    compile_options: str
    use_static_tensors: bool
    kwargs: tuple[tuple[str, Any]]

    def get_compile_args(self):
        """Returns the arguments to provide to cute.compile."""
        compiler_ins = [
            JaxTracedArray(
                jax_to_cutlass_dtype(leaf.dtype),
                leaf.shape,
                DEFAULT_CUTLASS_DEVICE_MEMSPACE,
                leaf.spec.ptr_assumed_align,
                leaf.spec.layout,
                leaf.spec.mode,
                leaf.get_static_flag(self.use_static_tensors),
            )
            for leaf in self.in_args
        ]
        compiler_outs = [
            JaxTracedArray(
                jax_to_cutlass_dtype(leaf.dtype),
                leaf.shape,
                DEFAULT_CUTLASS_DEVICE_MEMSPACE,
                leaf.spec.ptr_assumed_align,
                leaf.spec.layout,
                leaf.spec.mode,
                leaf.get_static_flag(self.use_static_tensors),
            )
            for leaf in self.out_args
        ]
        return JaxArrayList(tuple(compiler_ins + compiler_outs))


@cute.jit
def jit_wrapper(
    stream: cuda.CUstream,
    args: JaxArrayList,
    *,
    wrapped_fn: cutlass.Constexpr,
    spec: cutlass.Constexpr,
):
    # split buffer argument into inputs and outputs and return to tree
    ins, outs = args[: len(spec.in_args)], args[(len(spec.in_args)) :]
    ins = [x.get_tensor() for x in ins]
    outs = [x.get_tensor() for x in outs]
    ins = jax.tree.unflatten(spec.input_tree, ins)
    outs = jax.tree.unflatten(spec.output_tree, outs)
    wrapped_fn(stream, *ins, *outs, **dict(spec.kwargs))


@dataclass
class CompileResult:
    """Holds reference to the compiled kernel and argument spec."""

    module: bytes
    fingerprint: bytes
    spec: FunctionSpec


def _check_is_valid_type(x, is_input):
    if not is_input:
        if not isinstance(x, jax.ShapeDtypeStruct):
            raise TypeError("Invalid output value passed.", x)
    else:
        if not isinstance(x, jax.Array):
            raise TypeError("Invalid type passed.", x)


def build_function_spec(
    ins,
    in_tree,
    outs,
    out_tree,
    input_spec,
    output_spec,
    input_output_aliases,
    compile_options,
    use_static_tensors,
    kwargs,
):
    in_args = []
    for idx, (arg, spec) in enumerate(zip(ins, input_spec)):
        _check_is_valid_type(arg, is_input=True)
        in_args.append(Arg(idx, arg.shape, arg.dtype, spec))

    out_args = []
    for idx, (arg, spec) in enumerate(zip(outs, output_spec)):
        _check_is_valid_type(arg, is_input=False)
        out_args.append(Arg(idx, arg.shape, arg.dtype, spec))

    # Return the argument specs to the original pytree structure
    # We need this structure to sanely match index positions of the
    # arguments to the kernel.
    ins_args_structured = jax.tree.unflatten(in_tree, in_args)
    out_args_structured = jax.tree.unflatten(out_tree, out_args)

    # Assign per-leaf aliases
    input_output_aliases_per_leaf = {}
    for input_arg_alias_idx in input_output_aliases:
        flat_in, _ = jax.tree.flatten(ins_args_structured[input_arg_alias_idx])
        flat_out, _ = jax.tree.flatten(
            out_args_structured[input_output_aliases[input_arg_alias_idx]]
        )
        for i, o in zip(flat_in, flat_out):
            input_output_aliases_per_leaf[i.idx] = o.idx

    # Remove aliased arguments from output set since they are also provided
    # as inputs. This is done at the very top level of the tree to simplify
    # how we handle aliasing. The assumption is that the entire pytree is
    # aliased.
    out_args_structured = list(out_args_structured)
    for out_idx in sorted(tuple(set(input_output_aliases.values())), reverse=True):
        try:
            out_args_structured.pop(out_idx)
        except IndexError:
            raise ValueError(f"Invalid output alias {out_idx} in input_output_aliases.")
    out_args_structured = tuple(out_args_structured)

    in_args_flat, _ = jax.tree.flatten(ins_args_structured)
    out_args_flat, out_tree = jax.tree.flatten(out_args_structured)

    spec = FunctionSpec(
        tuple(in_args_flat),
        in_tree,
        tuple(out_args_flat),
        out_tree,
        tuple(input_output_aliases_per_leaf.items()),
        tuple(input_spec),
        tuple(output_spec),
        compile_options,
        use_static_tensors,
        tuple((k, kwargs[k]) for k in kwargs),
    )

    return spec


_compile_lock = threading.Lock()


def get_or_compile_kernel(fn, spec):
    """Gets or compiles fn and returns a CutlassCompileResult.

    The function and its specification is used as a key to determine if a new
    function must be compiled.
    """
    cache_key = (fn, spec)
    if cache_key in _CUTLASS_COMPILE_CACHE:
        return _CUTLASS_COMPILE_CACHE[cache_key]

    # Don't allow more than 1 thead to compile at any time.
    # We assume that the cache key is per thread so we don't need to lock
    # the above check in compile cache,
    compiled_fn = None
    with _compile_lock:
        start = time.time()
        try:
            cute_compile = cutlass.cute.compile
            if spec.compile_options:
                cute_compile = partial(cute_compile, options=spec.compile_options)

            compiled_fn = cute_compile(
                jit_wrapper,
                cuda.CUstream(0),
                spec.get_compile_args(),
                wrapped_fn=fn,
                spec=spec,
            )

            module = compiled_fn.dump_to_object(_EXPORT_PREFIX)
            fingerprint = bytes.fromhex(hashlib.sha256(module).hexdigest())

        except Exception as e:
            # Log here because Jax can obscure the exception details.
            logger.exception("Compilation failure for kernel.")
            raise e
        end = time.time()
    logger.debug(f"Took {end - start} to compile cute kernel.")

    result = CompileResult(module=module, spec=spec, fingerprint=fingerprint)
    _CUTLASS_COMPILE_CACHE[cache_key] = result
    return result


def release_compile_cache():
    """Releases entries from the compile cache.

    Note that is may prevent cute dsl from saving its persistent compilation cache entries.
    """
    _CUTLASS_COMPILE_CACHE.clear()
    dsl = CuTeDSL._get_dsl()
    dsl.jit_cache.clear()
    # TODO: This is needed to release frames being held in the DSL
    # We should avoid holding such references as they unexpectedly
    # extend object lifetime.
    dsl.frame = None
    gc.collect()


class _DummyInitKernel:
    @cute.kernel
    def kernel(self):
        pass

    @cute.jit
    def init(self):
        pass


_CUTLASS_DSL_INITIALIZED = False


def initialize_cutlass_dsl():
    """Initializes cutlass DSL."""
    global _CUTLASS_DSL_INITIALIZED
    if _CUTLASS_DSL_INITIALIZED:
        return

    # Call compiler to ensure we've pre-processed any kernels inside cutedsl.
    kernel = _DummyInitKernel()
    with _compile_lock:
        logger.debug("Initializing cutlass dsl...")
        _ = cutlass.cute.compile(kernel.init)

    _CUTLASS_DSL_INITIALIZED = True
